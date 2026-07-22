import 'dart:async';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../lobby/lobby.dart';
import '../services/services.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import 'ui_human_controller.dart';

part 'game_session.freezed.dart';
part 'game_session.g.dart';

enum GameStage { idle, casting, running, finished, error }

const grudgeBookPrefKey = 'grudgeBook';

/// Session snapshot for the UI. [visibleEvents] is the ONLY event surface
/// exposed while a game runs — filtered per event as they arrive; the full
/// log stays inside the controller until the post-game reveal.
@freezed
abstract class GameSession with _$GameSession {
  const factory GameSession({
    @Default(GameStage.idle) GameStage stage,
    @Default([]) List<GameEvent> visibleEvents,
    @Default(0) int humanSeat,
    @Default([]) List<String> names,
    @Default({}) Map<int, String> modelBadges,
    @Default({}) Map<int, Persona> personas,
    @Default(false) bool humanIsMafia,
    Scene? scene,
    String? townName,
    Faction? winner,
    String? error,
  }) = _GameSession;
}

@Riverpod(keepAlive: true)
class GameSessionController extends _$GameSessionController {
  GameEngine? _engine;
  UiHumanController? _human;
  final List<ChatProvider> _clients = [];
  bool _grudgeMode = false;

  @override
  GameSession build() {
    ref.onDispose(_teardown);
    return const GameSession();
  }

  UiHumanController? get humanController => _human;

  void _teardown() {
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    _human?.dispose();
    _human = null;
    _engine = null;
  }

  Future<void> startFromLobby() async {
    if (state.stage == GameStage.running) return;
    final setup = ref.read(lobbySetupControllerProvider);
    assert(setup.ready);
    state = GameSession(
      stage: GameStage.casting,
      humanSeat: setup.humanSeat,
      scene: setup.scene,
      townName: setup.townName,
    );
    try {
      await _start(setup);
    } catch (error) {
      // Boundary catch: config/DB/keychain failures surface in the UI
      // rather than crashing the shell.
      state = state.copyWith(stage: GameStage.error, error: '$error');
    }
  }

  Future<void> _start(LobbySetup setup) async {
    final db = ref.read(appDatabaseProvider);
    final keyStore = ref.read(apiKeyStoreProvider);
    final factory = ref.read(clientFactoryProvider);
    _grudgeMode = setup.grudgeMode;

    final connections = {
      for (final c in await db.watchConnections().first) c.id: c,
    };
    final customs = {
      for (final row in await db.watchPersonas().first)
        row.name: row.toPersona(),
    };
    final house = {for (final p in personaLibrary) p.name: p};

    Persona personaOf(String name) =>
        customs[name] ??
        house[name] ??
        Persona(
          name: name,
          archetype: 'townsperson',
          style: 'plain',
          quirk: 'unremarkable',
        );

    final personas = <int, Persona>{};
    final badges = <int, String>{};
    for (final seat in setup.aiSeats) {
      final casting = setup.seats[seat];
      personas[seat] = personaOf(casting.personaName!);
      badges[seat] = casting.model!.split('/').last;
    }
    personas[setup.humanSeat] = setup.humanPersonaName != null
        ? personaOf(setup.humanPersonaName!)
        : Persona(
            name: setup.humanName.trim(),
            archetype: 'themself',
            style: 'their own',
            quirk: 'unpredictable — a human is playing this seat',
          );
    badges[setup.humanSeat] = 'human';

    final names = [
      for (var s = 0; s < setup.config.seats; s++) personas[s]!.name,
    ];

    var grudges = GrudgeBook();
    if (_grudgeMode) {
      final json = await db.pref(grudgeBookPrefKey);
      if (json != null) grudges = GrudgeBook.fromJson(json);
    }
    final memories = <int, String>{};
    if (_grudgeMode) {
      for (var s = 0; s < names.length; s++) {
        final block = grudges.promptBlockFor(names[s]);
        if (block != null) memories[s] = block;
      }
    }

    final prompts = AgentPromptBuilder(
      names: names,
      personas: personas,
      difficulty: setup.difficulty,
      pastMemories: memories,
    );

    final clientByConnection = <String, ChatProvider>{};
    Future<ChatProvider> clientFor(String connectionId) async {
      final cached = clientByConnection[connectionId];
      if (cached != null) return cached;
      final connection = connections[connectionId];
      if (connection == null) {
        throw StateError('Connection $connectionId no longer exists');
      }
      final apiKey = await keyStore.read(connectionId);
      final client = factory(connection, apiKey);
      clientByConnection[connectionId] = client;
      _clients.add(client);
      return client;
    }

    final human = UiHumanController();
    _human = human;
    final controllers = <int, PlayerController>{setup.humanSeat: human};
    for (final seat in setup.aiSeats) {
      final casting = setup.seats[seat];
      controllers[seat] = AgentController(
        client: await clientFor(casting.connectionId!),
        model: casting.model!,
        prompts: prompts,
        temperature: casting.temperature,
      );
    }

    final engine = GameEngine(
      config: setup.config,
      controllers: controllers,
      rngSeed: Random().nextInt(1 << 31),
      observer: _onEvent,
    );
    _engine = engine;
    state = state.copyWith(
      stage: GameStage.running,
      names: names,
      personas: personas,
      modelBadges: badges,
    );
    unawaited(
      engine.run().then(_onFinished).catchError((Object error) {
        state = state.copyWith(stage: GameStage.error, error: '$error');
      }),
    );
  }

  void _onEvent(GameEvent event) {
    var session = state;
    if (event is RolesDealt) {
      session = session.copyWith(
        humanIsMafia: event.roles[session.humanSeat]?.faction == Faction.mafia,
      );
    }
    if (event is NightBegan) {
      ref.read(tableMoodControllerProvider.notifier).set(TableMood.night);
    }
    if (event is DayBegan) {
      ref.read(tableMoodControllerProvider.notifier).set(TableMood.day);
    }
    final visible = event.scope.visibleTo(
      session.humanSeat,
      isMafia: session.humanIsMafia,
    );
    state = visible
        ? session.copyWith(visibleEvents: [...session.visibleEvents, event])
        : session;
  }

  Future<void> _onFinished(GameResult result) async {
    state = state.copyWith(stage: GameStage.finished, winner: result.winner);
    if (_grudgeMode) {
      final db = ref.read(appDatabaseProvider);
      final json = await db.pref(grudgeBookPrefKey);
      final grudges = json == null ? GrudgeBook() : GrudgeBook.fromJson(json);
      grudges.recordGame(result.events, state.names);
      await db.setPref(grudgeBookPrefKey, grudges.toJson());
    }
  }

  /// Post-game only: the full log for the reveal screen (M3.6). Empty
  /// while the game is live — never render from this during play.
  List<GameEvent> get revealEvents => state.stage == GameStage.finished
      ? _engine?.events ?? const []
      : const [];

  /// Test seam: run the engine through the session with injected
  /// controllers — no DB, no clients, no LLM.
  Future<GameResult> startScripted({
    required GameConfig config,
    required Map<int, PlayerController> controllers,
    required List<String> names,
    int humanSeat = 0,
    int seed = 42,
  }) async {
    _human = controllers[humanSeat] is UiHumanController
        ? controllers[humanSeat]! as UiHumanController
        : null;
    state = GameSession(
      stage: GameStage.running,
      humanSeat: humanSeat,
      names: names,
    );
    final engine = GameEngine(
      config: config,
      controllers: controllers,
      rngSeed: seed,
      observer: _onEvent,
    );
    _engine = engine;
    final result = await engine.run();
    await _onFinished(result);
    return result;
  }

  void abandonGame() {
    _teardown();
    state = const GameSession();
  }
}

@riverpod
GameStage sessionStage(Ref ref) =>
    ref.watch(gameSessionControllerProvider).stage;

@riverpod
Stream<HumanRequest?> humanRequest(Ref ref) {
  // Re-grab the stream whenever a new game (new controller) starts.
  ref.watch(sessionStageProvider);
  final controller = ref
      .watch(gameSessionControllerProvider.notifier)
      .humanController;
  if (controller == null) return Stream.value(null);
  return () async* {
    yield controller.current;
    yield* controller.requests;
  }();
}
