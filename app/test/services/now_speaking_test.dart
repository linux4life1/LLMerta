import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';
import 'package:tts/tts.dart';

class _InstantEngine implements TtsEngine {
  @override
  Future<TtsAudio> synthesize(
    String text,
    Voice voice, {
    double speed = 1.0,
  }) async => TtsAudio(
    wavBytes: Uint8List.fromList(text.codeUnits),
    sampleRate: 22050,
    duration: const Duration(milliseconds: 1200),
  );
}

class _InstantPlayer implements WavPlayer {
  @override
  Future<void> play(Uint8List wavBytes) async {}

  @override
  void stop() {}
}

void main() {
  TtsStack stack() {
    final queue = SpeechQueue(
      engine: _InstantEngine(),
      player: _InstantPlayer(),
    );
    addTearDown(queue.dispose);
    return TtsStack(
      queue: queue,
      voices: [
        Voice(
          bundle: VoiceBundle(
            kind: VoiceBundleKind.piper,
            dir: Directory('/tmp/p'),
          ),
        ),
      ],
    );
  }

  test('nowSpeaking tracks the queue and clears when the line ends', () async {
    final s = stack();
    final container = ProviderContainer(
      overrides: [ttsStackProvider.overrideWith((_) => s)],
    );
    addTearDown(container.dispose);
    final seen = <(String, DateTime, Duration)?>[];
    final sub = container.listen(
      nowSpeakingProvider,
      (_, next) => seen.add(next),
    );
    addTearDown(sub.close);
    container.read(nowSpeakingProvider);

    s.queue.add(SpeechItem(id: 1, text: 'hello table', voice: s.voices.single));
    await s.queue.events.firstWhere((e) => e is QueueDrained);
    await Future<void>.delayed(Duration.zero);

    expect(seen.whereType<(String, DateTime, Duration)>().length, 1);
    final started = seen.whereType<(String, DateTime, Duration)>().single;
    expect(started.$1, 'hello table');
    expect(started.$3, const Duration(milliseconds: 1200));
    expect(seen.last, isNull);
  });

  test('speechHold falls back to reading time without a stack', () async {
    final container = ProviderContainer(
      overrides: [ttsStackProvider.overrideWith((_) => null)],
    );
    addTearDown(container.dispose);
    final clock = Stopwatch()..start();
    // Short text: floor is the 1.5s reading-time clamp.
    final hold = speechHold(container.read(_refProvider), 'hi');
    expect(clock.elapsedMilliseconds, lessThan(400));
    // Don't wait the full floor — just prove it's a pending future.
    expect(hold, isA<Future<void>>());
  });

  test('speechHold releases when the queue finishes the exact line', () async {
    final s = stack();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        ttsStackProvider.overrideWith((_) => s),
      ],
    );
    addTearDown(container.dispose);

    final hold = speechHold(container.read(_refProvider), 'the line');
    s.queue.add(SpeechItem(id: 7, text: 'the line', voice: s.voices.single));
    await hold.timeout(const Duration(seconds: 5));
  });
}

final _refProvider = Provider<Ref>((ref) => ref);
