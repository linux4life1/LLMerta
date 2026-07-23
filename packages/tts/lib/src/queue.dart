import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'engine.dart';
import 'voices.dart';

abstract interface class WavPlayer {
  Future<void> play(Uint8List wavBytes);

  void stop();
}

class SpeechItem {
  SpeechItem({required this.id, required this.text, required this.voice});

  final Object id;
  final String text;
  final Voice voice;
}

sealed class QueueEvent {
  const QueueEvent();
}

class SpeakingStarted extends QueueEvent {
  const SpeakingStarted(
    this.id, [
    this.text = '',
    this.duration = Duration.zero,
  ]);

  final Object id;

  /// Line and audio length — lets the UI reveal words in time with the
  /// voice and lets the pacer hold the turn until the line is spoken.
  final String text;
  final Duration duration;
}

class SpeakingEnded extends QueueEvent {
  const SpeakingEnded(this.id, [this.text = '']);

  final Object id;

  /// The spoken line — lets the table pacer hold a speech's turn until
  /// its audio actually finishes.
  final String text;
}

/// A line that could not be synthesized or played — emitted instead of
/// silently vanishing (a playback error once muted three releases).
class SpeechFailed extends QueueEvent {
  const SpeechFailed(this.id, this.error, [this.text = '']);

  final Object id;
  final String error;
  final String text;
}

class QueueDrained extends QueueEvent {
  const QueueDrained();
}

/// Pipelined TTS (ARCHITECTURE.md §4): while item N plays, item N+1 is
/// already synthesizing. Synthesis results are cached by (voice, text)
/// so replays and retries cost nothing.
class SpeechQueue {
  SpeechQueue({
    required this.engine,
    required this.player,
    this.cacheCapacity = 64,
  });

  final TtsEngine engine;
  final WavPlayer player;
  final int cacheCapacity;

  final _pending = Queue<SpeechItem>();
  final _cache = <String, TtsAudio>{};
  final _events = StreamController<QueueEvent>.broadcast();
  Future<TtsAudio>? _prefetch;
  SpeechItem? _prefetchedFor;
  var _running = false;
  var _muted = false;
  var _disposed = false;

  Stream<QueueEvent> get events => _events.stream;

  int get backlog => _pending.length;

  bool get muted => _muted;

  set muted(bool value) {
    _muted = value;
    if (value) {
      _pending.clear();
      player.stop();
    }
  }

  void add(SpeechItem item) {
    if (_muted || _disposed) return;
    _pending.add(item);
    if (!_running) unawaited(_drain());
  }

  void skip() => player.stop();

  void dispose() {
    _disposed = true;
    _pending.clear();
    player.stop();
    _events.close();
  }

  String _key(SpeechItem item) => '${item.voice.cacheKey}|${item.text}';

  Future<TtsAudio> _synthesize(SpeechItem item) async {
    final key = _key(item);
    final hit = _cache[key];
    if (hit != null) return hit;
    final audio = await engine.synthesize(item.text, item.voice);
    if (_cache.length >= cacheCapacity) _cache.remove(_cache.keys.first);
    _cache[key] = audio;
    return audio;
  }

  Future<TtsAudio> _obtain(SpeechItem item) {
    if (identical(_prefetchedFor, item) && _prefetch != null) {
      return _prefetch!;
    }
    return _synthesize(item);
  }

  Future<void> _drain() async {
    _running = true;
    try {
      while (_pending.isNotEmpty && !_disposed && !_muted) {
        final item = _pending.removeFirst();
        TtsAudio audio;
        try {
          audio = await _obtain(item);
        } on Exception catch (error) {
          // One bad synthesis never stalls the table — but say so.
          _events.add(SpeechFailed(item.id, '$error', item.text));
          continue;
        }
        // Pipeline: synthesize the next item while this one plays.
        _prefetch = null;
        _prefetchedFor = null;
        if (_pending.isNotEmpty) {
          final next = _pending.first;
          _prefetchedFor = next;
          _prefetch = _synthesize(next);
          unawaited(
            _prefetch!.catchError(
              (Object _) => TtsAudio(
                wavBytes: Uint8List(0),
                sampleRate: 1,
                duration: Duration.zero,
              ),
            ),
          );
        }
        if (_muted || _disposed) break;
        _events.add(SpeakingStarted(item.id, item.text, audio.duration));
        try {
          await player.play(audio.wavBytes);
        } on Exception catch (error) {
          // A playback failure must never kill the drain loop (it once
          // silenced every voice on fresh installs, invisibly).
          _events.add(SpeechFailed(item.id, '$error', item.text));
        } finally {
          if (!_disposed) _events.add(SpeakingEnded(item.id, item.text));
        }
      }
    } finally {
      _running = false;
      if (!_disposed) _events.add(const QueueDrained());
    }
  }
}
