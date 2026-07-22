import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:persistence/persistence.dart';
import 'package:tts/tts.dart';

const _names = ['Sosuke', 'Edda', 'Alma', 'Jonas', 'Greta', 'Marlowe', 'Vex'];

class _FakeEngine implements TtsEngine {
  final spoken = <(String, String)>[];

  @override
  Future<TtsAudio> synthesize(
    String text,
    Voice voice, {
    double speed = 1.0,
  }) async {
    spoken.add((text, voice.label));
    return TtsAudio(
      wavBytes: Uint8List.fromList(text.codeUnits),
      sampleRate: 22050,
      duration: Duration.zero,
    );
  }
}

class _FakePlayer implements WavPlayer {
  final played = <String>[];

  @override
  Future<void> play(Uint8List wavBytes) async =>
      played.add(String.fromCharCodes(wavBytes));

  @override
  void stop() {}
}

class _DrivableSession extends GameSessionController {
  @override
  GameSession build() => const GameSession();

  void push(GameSession session) => state = session;
}

void main() {
  test(
    'director voices speeches per seat and narration via narrator',
    () async {
      final engine = _FakeEngine();
      final player = _FakePlayer();
      final bundle = VoiceBundle(
        kind: VoiceBundleKind.kokoro,
        dir: Directory('/tmp/k'),
      );
      final stack = TtsStack(
        queue: SpeechQueue(engine: engine, player: player),
        voices: kokoroSpeakers(bundle, count: 4),
      );
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          gameSessionControllerProvider.overrideWith(_DrivableSession.new),
          ttsStackProvider.overrideWith((_) => stack),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(stack.queue.dispose);
      container.read(ttsDirectorProvider);
      final session =
          container.read(gameSessionControllerProvider.notifier)
              as _DrivableSession;

      session.push(
        GameSession(
          stage: GameStage.running,
          gameId: 'g1',
          names: _names,
          visibleEvents: const [
            GameStarted(seats: 7),
            DayBegan(1),
            SpeechGiven(seat: 2, text: 'The bakery was dark.'),
            SpeechGiven(seat: 3, text: 'I do not trust the fog.'),
            Verdict(eliminated: 3, revealedRole: Role.mafioso),
          ],
        ),
      );
      await stack.queue.events.firstWhere((e) => e is QueueDrained);

      expect(player.played, hasLength(3));
      expect(player.played[0], 'The bakery was dark.');
      expect(engine.spoken[0].$2, isNot(engine.spoken[1].$2));
      expect(engine.spoken[2].$1, contains('eliminated'));
      expect(container.read(ttsDirectorProvider), 3);
    },
  );

  test('disabled TTS advances position without speaking the backlog', () async {
    final engine = _FakeEngine();
    final stack = TtsStack(
      queue: SpeechQueue(engine: engine, player: _FakePlayer()),
      voices: [
        Voice(
          bundle: VoiceBundle(
            kind: VoiceBundleKind.piper,
            dir: Directory('/tmp/p'),
          ),
        ),
      ],
    );
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        gameSessionControllerProvider.overrideWith(_DrivableSession.new),
        ttsStackProvider.overrideWith((_) => stack),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(stack.queue.dispose);
    container.read(ttsDirectorProvider);
    await container.read(ttsEnabledProvider.notifier).set(false);
    final session =
        container.read(gameSessionControllerProvider.notifier)
            as _DrivableSession;

    session.push(
      GameSession(
        stage: GameStage.running,
        gameId: 'g1',
        names: _names,
        visibleEvents: const [
          DayBegan(1),
          SpeechGiven(seat: 1, text: 'quiet line'),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(engine.spoken, isEmpty);

    await container.read(ttsEnabledProvider.notifier).set(true);
    session.push(
      GameSession(
        stage: GameStage.running,
        gameId: 'g1',
        names: _names,
        visibleEvents: const [
          DayBegan(1),
          SpeechGiven(seat: 1, text: 'quiet line'),
          SpeechGiven(seat: 2, text: 'spoken line'),
        ],
      ),
    );
    await stack.queue.events.firstWhere((e) => e is QueueDrained);
    expect(engine.spoken.map((s) => s.$1), ['spoken line']);
  });

  testWidgets('voices tab reports missing bundles and toggles TTS', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kokoroBundleProvider.overrideWith((_) => null),
          piperBundleProvider.overrideWith((_) => null),
        ],
        child: const MaterialApp(home: Scaffold(body: VoicesSection())),
      ),
    );
    await tester.pump();
    expect(find.textContaining('No usable voice bundle'), findsOneWidget);
    expect(find.textContaining('npz files will not work'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Speak the table aloud'));
    await tester.pump();
    final element = tester.element(find.byType(VoicesSection));
    expect(
      ProviderScope.containerOf(element).read(ttsEnabledProvider),
      isFalse,
    );
  });
}
