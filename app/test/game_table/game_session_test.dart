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
    controller.abandonGame();
    final session = container.read(gameSessionControllerProvider);
    expect(session.stage, GameStage.idle);
    expect(session.visibleEvents, isEmpty);
    expect(controller.revealEvents, isEmpty);
  });
}
