import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:persistence/persistence.dart';
import 'package:tts/tts.dart';

import 'support.dart';

const _names = ['Sosuke', 'Edda', 'Alma', 'Jonas', 'Greta', 'Marlowe', 'Vex'];

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

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

  test(
    'sherpa engine rejects invalid bundles before any native load',
    () async {
      final engine = SherpaTtsEngine();
      final empty = await Directory.systemTemp.createTemp('llmerta-bad-piper');
      addTearDown(() => empty.delete(recursive: true));
      await expectLater(
        engine.synthesize(
          'hello',
          Voice(
            bundle: VoiceBundle(kind: VoiceBundleKind.piper, dir: empty),
          ),
        ),
        throwsA(isA<TtsUnavailable>()),
      );

      final npz = await Directory.systemTemp.createTemp('llmerta-npz');
      addTearDown(() => npz.delete(recursive: true));
      File('${npz.path}/kokoro-v1_0.npz').writeAsBytesSync(const [1]);
      await expectLater(
        engine.synthesize(
          'hello',
          Voice(
            bundle: VoiceBundle(kind: VoiceBundleKind.kokoro, dir: npz),
          ),
        ),
        throwsA(
          isA<TtsUnavailable>().having(
            (e) => e.message,
            'message',
            contains('npz'),
          ),
        ),
      );
    },
  );

  testWidgets('download flow fetches the Piper voice into app support', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final support = await Directory.systemTemp.createTemp('llmerta-support');
      addTearDown(() => support.delete(recursive: true));
      PathProviderPlatform.instance = _FakePathProvider(support.path);

      final archive = Archive()
        ..addFile(
          ArchiveFile('${piperLessac.dirName}/tokens.txt', 1, 'x'.codeUnits),
        );
      final bz2 = BZip2Encoder().encode(TarEncoder().encode(archive));
      final downloader = VoiceDownloader(
        httpClient: MockClient(
          (request) async => http.Response.bytes(bz2, 200),
        ),
      );
      addTearDown(downloader.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((_) => db),
            kokoroBundleProvider.overrideWith((_) => null),
            piperBundleProvider.overrideWith((_) => null),
            voiceDownloaderProvider.overrideWith((_) => downloader),
          ],
          child: const MaterialApp(home: Scaffold(body: VoicesSection())),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Download'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await settle(tester);
      expect(
        File(
          '${support.path}/voices/${piperLessac.dirName}/tokens.txt',
        ).existsSync(),
        isTrue,
      );
      expect(find.textContaining('Download failed'), findsNothing);
    });
  });

  testWidgets('voices tab reports missing bundles and toggles TTS', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((_) => db),
            kokoroBundleProvider.overrideWith((_) => null),
            piperBundleProvider.overrideWith((_) => null),
          ],
          child: const MaterialApp(home: Scaffold(body: VoicesSection())),
        ),
      );
      await settle(tester);
      expect(find.textContaining('No usable voice bundle'), findsOneWidget);
      expect(find.textContaining('npz files will not work'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      await tester.tap(find.text('Speak the table aloud'));
      await settle(tester);
      final element = tester.element(find.byType(VoicesSection));
      expect(
        ProviderScope.containerOf(element).read(ttsEnabledProvider),
        isFalse,
      );
    });
  });
}
