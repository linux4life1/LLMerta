import 'dart:async';

import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart' show renderEvent;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tts/tts.dart';

import '../game_table/game_session.dart';
import '../game_table/session_state.dart';
import 'audio.dart';
import 'database.dart';
import 'sherpa_tts.dart';

part 'tts_service.g.dart';

const ttsEnabledPrefKey = 'ttsEnabled';

class TtsStack {
  const TtsStack({required this.queue, required this.voices});

  final SpeechQueue queue;
  final List<Voice> voices;
}

@Riverpod(keepAlive: true)
class TtsEnabled extends _$TtsEnabled {
  @override
  bool build() {
    unawaited(_hydrate());
    return true;
  }

  Future<void> _hydrate() async {
    try {
      final saved = await ref.read(appDatabaseProvider).pref(ttsEnabledPrefKey);
      if (saved != null) state = saved == 'true';
    } on Exception {
      // No DB yet (first run, tests): keep the default.
    }
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    try {
      await ref
          .read(appDatabaseProvider)
          .setPref(ttsEnabledPrefKey, '$enabled');
    } on Exception {
      // Preference persistence is best-effort.
    }
  }
}

@Riverpod(keepAlive: true)
VoiceBundle? kokoroBundle(Ref ref) => detectKokoroBundle();

@Riverpod(keepAlive: true)
VoiceBundle? piperBundle(Ref ref) => detectPiperBundle();

@Riverpod(keepAlive: true)
VoiceDownloader voiceDownloader(Ref ref) {
  final downloader = VoiceDownloader();
  ref.onDispose(downloader.close);
  return downloader;
}

/// Kokoro (many speakers) preferred, Piper as the single-voice fallback;
/// null when no valid bundle is on disk — the app stays fully silent-safe.
@Riverpod(keepAlive: true)
TtsStack? ttsStack(Ref ref) {
  final kokoro = ref.watch(kokoroBundleProvider);
  final piper = ref.watch(piperBundleProvider);
  final voices = [
    if (kokoro != null) ...kokoroSpeakers(kokoro),
    if (kokoro == null && piper != null) Voice(bundle: piper, label: 'Piper'),
  ];
  if (voices.isEmpty) return null;
  final queue = SpeechQueue(
    engine: SherpaTtsEngine(),
    player: AudioplayersWavPlayer(),
  );
  ref.onDispose(queue.dispose);
  return TtsStack(queue: queue, voices: voices);
}

/// Bridges session events into the speech queue: seat voices for
/// speeches, the narrator voice for dawn/verdict/game-end lines.
@Riverpod(keepAlive: true)
class TtsDirector extends _$TtsDirector {
  var _consumed = 0;
  String? _gameId;

  @override
  int build() {
    ref.listen(gameSessionControllerProvider, (_, next) => _consume(next));
    return 0;
  }

  void _consume(GameSession session) {
    if (session.gameId != _gameId) {
      _gameId = session.gameId;
      _consumed = 0;
    }
    final stack = ref.read(ttsStackProvider);
    final enabled = ref.read(ttsEnabledProvider);
    final events = session.visibleEvents;
    for (; _consumed < events.length; _consumed++) {
      // Track position even while disabled so re-enabling doesn't dump
      // the whole backlog at once.
      if (stack == null || !enabled || session.names.isEmpty) continue;
      final event = events[_consumed];
      final assignment = assignVoices(
        seats: session.names.length,
        available: stack.voices,
      );
      final (text, voice) = switch (event) {
        SpeechGiven(:final seat, :final text) => (
          text,
          assignment.bySeat[seat],
        ),
        DefenseGiven(:final seat, :final text) => (
          text,
          assignment.bySeat[seat],
        ),
        LastWordsGiven(:final seat, :final text) => (
          text,
          assignment.bySeat[seat],
        ),
        DawnAnnounced() ||
        Verdict() ||
        GameEnded() => (renderEvent(event, session.names), assignment.narrator),
        _ => (null, null),
      };
      if (text == null || text.isEmpty || voice == null) continue;
      stack.queue.add(SpeechItem(id: _consumed, text: text, voice: voice));
      state = state + 1;
    }
  }
}
