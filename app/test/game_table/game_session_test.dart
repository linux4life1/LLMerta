import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/theme/theme.dart';
import 'package:persistence/persistence.dart';

class _MemKeyStore implements ApiKeyStore {
  final keys = <String, String>{};

  @override
  Future<String?> read(String id) async => keys[id];

  @override
  Future<void> write(String id, String apiKey) async => keys[id] = apiKey;

  @override
  Future<void> delete(String id) async => keys.remove(id);
}

/// Legal-but-passive agent: speaks, never nominates, never shoots — the
/// stub game runs to the maxDays draw, exercising the whole pipeline.
class _ScriptedChat implements ChatProvider {
  @override
  Future<ChatResult> chat(
    List<ChatMessage> messages, {
    required String model,
    double temperature = 0.7,
    int maxTokens = 1024,
    JsonSchemaSpec? jsonSchema,
  }) async => const ChatResult(
    text:
        '{"reason":"noted","speech":"The fog keeps its counsel.",'
        '"nominate":null,"vote":null,"kill":null,"protect":0,'
        '"investigate":0,"shoot":null}',
    latency: Duration.zero,
  );

  @override
  Future<List<String>> listModels() async => const ['stub'];

  @override
  ({int calls, int promptTokens, int completionTokens}) get usage =>
      (calls: 0, promptTokens: 0, completionTokens: 0);

  @override
  void close() {}
}

void main() {
  test(
    'scripted game runs through the session with visibility filtering',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(gameSessionControllerProvider.notifier);

      final result = await controller.startScripted(
        config: const GameConfig(seats: 7),
        controllers: {for (var s = 0; s < 7; s++) s: RandomLegalController(s)},
        names: const [
          'Sosuke',
          'Edda',
          'Alma',
          'Jonas',
          'Greta',
          'Marlowe',
          'Vex',
        ],
        seed: 42,
      );

      final session = container.read(gameSessionControllerProvider);
      expect(session.stage, GameStage.finished);
      expect(session.winner, result.winner);
      expect(session.visibleEvents, isNotEmpty);

      // Leak spot-checks: a non-mafia human must never see the mafia's
      // night traffic or anyone else's role card.
      if (!session.humanIsMafia) {
        expect(
          session.visibleEvents.whereType<MafiaChatSaid>(),
          isEmpty,
          reason: 'mafia chat leaked to a town human',
        );
        expect(
          session.visibleEvents.whereType<MafiaKillChosen>(),
          isEmpty,
          reason: 'mafia kill decision leaked to a town human',
        );
      }
      expect(
        session.visibleEvents.whereType<RoleReceived>().where(
          (e) => e.seat != session.humanSeat,
        ),
        isEmpty,
        reason: 'a foreign role card leaked into render state',
      );
      expect(
        session.visibleEvents.whereType<NightResolved>(),
        isEmpty,
        reason: 'omniscient resolution internals leaked',
      );

      // Post-game the full log opens up for the reveal.
      expect(controller.revealEvents.length, result.events.length);
      expect(
        controller.revealEvents.length,
        greaterThan(session.visibleEvents.length),
      );

      // The mood follows the last phase event of the finished game.
      expect(container.read(tableMoodControllerProvider), isA<TableMood>());
    },
  );

  test(
    'startFromLobby wires DB, keys, clients, grudges — full stub game',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertConnection(
        ConnectionsCompanion.insert(
          id: 'omlx',
          label: 'oMLX',
          kind: ProviderKind.openaiCompat,
          baseUrl: 'http://127.0.0.1:8000/v1',
        ),
      );
      await db.replaceModels('omlx', ['stub-model']);
      await db.upsertPersona(
        CustomPersonasCompanion.insert(
          name: 'Vex',
          archetype: 'switchboard operator',
          style: 'clipped',
          quirk: 'listens in',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          apiKeyStoreProvider.overrideWith((_) => _MemKeyStore()),
          clientFactoryProvider.overrideWith(
            (_) =>
                (connection, apiKey) => _ScriptedChat(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(lobbySetupControllerProvider.notifier)
        ..setSeatCount(7)
        ..castAllSeats(connectionId: 'omlx', model: 'stub-model')
        ..shufflePersonas(['Vex', for (final p in personaLibrary) p.name])
        ..setHumanName('Sosuke')
        ..setGrudgeMode(true);

      final controller = container.read(gameSessionControllerProvider.notifier);
      final started = controller.startFromLobby();

      // Auto-answer every human request so the stub game never stalls.
      void answer(HumanRequest? request) {
        if (request == null) return;
        if (request.wantsText) {
          request.submitText('I keep to myself.');
        } else {
          request.submitChoice(
            request.mustChoose ? request.targets.first : null,
          );
        }
      }

      var humanBound = false;
      while (!humanBound) {
        final human = controller.humanController;
        if (human != null) {
          human.requests.listen(answer);
          answer(human.current);
          humanBound = true;
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      }
      await started;

      while (container.read(gameSessionControllerProvider).stage ==
          GameStage.running) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final session = container.read(gameSessionControllerProvider);
      expect(session.stage, GameStage.finished);
      expect(session.error, isNull);
      // Passive agents + maxDays backstop = engine draw.
      expect(session.winner, isNull);
      expect(session.names, hasLength(7));
      expect(session.names[0], 'Sosuke');
      expect(session.modelBadges[0], 'human');
      expect(session.modelBadges[1], 'stub-model');
      expect(controller.revealEvents, isNotEmpty);
      expect(await db.pref(grudgeBookPrefKey), isNotNull);

      // M4: every AI seat built a memory, and each memory holds ONLY its
      // seat's visibility slice — town seats never store mafia whispers.
      expect(controller.memories, hasLength(6));
      final roles = controller.revealEvents.whereType<RolesDealt>().first.roles;
      var ingestedSomething = false;
      for (final MapEntry(key: seat, value: agentMemory)
          in controller.memories.entries) {
        if (agentMemory.store.length > 0) ingestedSomething = true;
        if (roles[seat]!.faction != Faction.mafia) {
          expect(
            agentMemory.store.where((c) => c.text.contains('[mafia chat]')),
            isEmpty,
            reason: 'seat $seat (town) stored a mafia whisper',
          );
        }
      }
      expect(ingestedSomething, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'resumeGame replays a mid-game save and plays it to completion',
    () async {
      // Craft a genuine mid-game save from a scripted engine run.
      final original = await GameEngine(
        config: const GameConfig(seats: 7),
        controllers: {for (var s = 0; s < 7; s++) s: RandomLegalController(s)},
        rngSeed: 99,
      ).run();
      final cut = original.events.indexWhere(
        (e) => e is DayBegan && e.day == 2,
      );
      expect(cut, greaterThan(0), reason: 'need a two-day game to cut');
      final prefix = original.events.sublist(0, cut);

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertConnection(
        ConnectionsCompanion.insert(
          id: 'omlx',
          label: 'oMLX',
          kind: ProviderKind.openaiCompat,
          baseUrl: 'http://127.0.0.1:8000/v1',
        ),
      );
      const names = [
        'Sosuke',
        'Edda',
        'Alma',
        'Jonas',
        'Greta',
        'Marlowe',
        'Vex',
      ];
      await db.upsertGame(
        GamesCompanion.insert(
          id: 'mid-game',
          townName: 'Veilport',
          savedAt: DateTime(2026, 7, 22),
          humanSeat: 0,
          rngSeed: 99,
          difficulty: 'standard',
          grudgeMode: const Value(false),
          namesJson: jsonEncode(names),
          badgesJson: jsonEncode({
            for (var s = 1; s < 7; s++) '$s': 'stub-model',
          }),
          castingJson: Value(
            jsonEncode([
              null,
              for (var s = 1; s < 7; s++)
                {
                  'connectionId': 'omlx',
                  'model': 'stub-model',
                  'temperature': 0.7,
                },
            ]),
          ),
          configJson: jsonEncode(configToJson(const GameConfig(seats: 7))),
          eventsJson: jsonEncode([for (final e in prefix) eventToJson(e)]),
          notes: const Value('resume me'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          apiKeyStoreProvider.overrideWith((_) => _MemKeyStore()),
          clientFactoryProvider.overrideWith(
            (_) =>
                (connection, apiKey) => _ScriptedChat(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(gameSessionControllerProvider.notifier);

      void answer(HumanRequest? request) {
        if (request == null) return;
        if (request.wantsText) {
          request.submitText('Still here.');
        } else {
          request.submitChoice(
            request.mustChoose ? request.targets.first : null,
          );
        }
      }

      final resumed = controller.resumeGame('mid-game');
      var bound = false;
      while (!bound) {
        final human = controller.humanController;
        if (human != null) {
          human.requests.listen(answer);
          answer(human.current);
          bound = true;
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      }
      await resumed;
      while (container.read(gameSessionControllerProvider).stage ==
          GameStage.running) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final session = container.read(gameSessionControllerProvider);
      expect(session.stage, GameStage.finished);
      expect(session.error, isNull);
      expect(session.notes, 'resume me');
      expect(session.names, names);
      // The replayed prefix must be byte-identical to the save.
      final replayed = controller.revealEvents;
      expect(
        [
          for (final e in replayed.take(prefix.length))
            jsonEncode(eventToJson(e)),
        ],
        [for (final e in prefix) jsonEncode(eventToJson(e))],
      );
      final row = await db.gameById('mid-game');
      expect(row?.finished, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'startFromLobby surfaces a missing connection as an error stage',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          apiKeyStoreProvider.overrideWith((_) => _MemKeyStore()),
        ],
      );
      addTearDown(container.dispose);
      container.read(lobbySetupControllerProvider.notifier)
        ..setSeatCount(7)
        ..castAllSeats(connectionId: 'ghost', model: 'm')
        ..shufflePersonas([for (final p in personaLibrary) p.name])
        ..setHumanName('Sosuke');
      final controller = container.read(gameSessionControllerProvider.notifier);
      await controller.startFromLobby();
      final session = container.read(gameSessionControllerProvider);
      expect(session.stage, GameStage.error);
      expect(session.error, contains('ghost'));
    },
  );

  test('abandonGame resets to idle', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(gameSessionControllerProvider.notifier);
    await controller.startScripted(
      config: const GameConfig(seats: 7),
      controllers: {for (var s = 0; s < 7; s++) s: RandomLegalController(s)},
      names: const ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
    );
    await controller.abandonGame();
    final session = container.read(gameSessionControllerProvider);
    expect(session.stage, GameStage.idle);
    expect(session.visibleEvents, isEmpty);
    expect(controller.revealEvents, isEmpty);
  });
}
