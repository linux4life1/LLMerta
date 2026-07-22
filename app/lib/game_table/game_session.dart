import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:memory/memory.dart';
import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../lobby/lobby.dart';
import '../services/services.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import 'session_state.dart';
import 'session_support.dart';
import 'ui_human_controller.dart';

part 'game_session.g.dart';

@Riverpod(keepAlive: true)
class GameSessionController extends _$GameSessionController {
  GameEngine? _engine;
  UiHumanController? _human;
  final List<ChatProvider> _clients = [];
  bool _grudgeMode = false;
  Difficulty _difficulty = Difficulty.standard;
  String _castingJson = '[]';
  int _rngSeed = 0;
  int _epoch = 0;
  Map<int, (ChatProvider, String)> _agentBackends = {};
  // Omniscient host-side state (never exposed to render surfaces): each
  // AI seat's memory receives only that seat's visibility slice.
  final Map<int, AgentMemory> _memories = {};
  final Map<int, List<(String, String)>> _reasoning = {};
  Map<int, Role> _roles = const {};

  /// For the Reveal's table talk (M3.6): seat → (client, model).
  Map<int, (ChatProvider, String)> get agentBackends => _agentBackends;

  /// Test seam: per-seat RAG memories (M4).
  Map<int, AgentMemory> get memories => Map.unmodifiable(_memories);

  /// Post-game only (Reveal v2): each seat's private decision rationales.
  Map<int, List<(String, String)>> get revealReasoning =>
      state.stage == GameStage.finished
      ? Map.unmodifiable(_reasoning)
      : const {};

  void _recordReason(int seat, String task, String reason) =>
      _reasoning.putIfAbsent(seat, () => []).add((task, reason));

  Future<String?> Function(DecisionContext, String) _memoryFor(int seat) =>
      (ctx, task) async {
        final memory = _memories[seat];
        if (memory == null || memory.store.length == 0) return null;
        return memory.memoryBlock(
          task,
          budget: const TokenBudget(context: 8000),
          fixedTokens: 2500,
        );
      };

  void _buildMemories(Iterable<int> aiSeats) {
    _memories.clear();
    _reasoning.clear();
    final embedder = ref.read(gameEmbedderProvider);
    for (final seat in aiSeats) {
      _memories[seat] = AgentMemory(seat: seat, embedder: embedder);
    }
  }

  void _ingestForAgents(GameEvent event) {
    if (event is RolesDealt) _roles = event.roles;
    for (final MapEntry(key: seat, value: memory) in _memories.entries) {
      final isMafia = _roles[seat]?.faction == Faction.mafia;
      if (!event.scope.visibleTo(seat, isMafia: isMafia)) continue;
      unawaited(memory.ingest(event, renderEvent(event, state.names)));
    }
    // A phase boundary closes the previous phase: summarize what each
    // agent heard during it.
    if (event is DayBegan && event.day > 1) {
      _queuePhaseSummaries(event.day - 1);
    }
    if (event is NightBegan && event.day > 0) {
      _queuePhaseSummaries(event.day);
    }
  }

  /// Rolling-summary tier: each agent compacts the finished phase in its
  /// own words via its own model — fire-and-forget, epoch-guarded.
  void _queuePhaseSummaries(int endedDay) {
    final epoch = _epoch;
    for (final MapEntry(key: seat, value: memory) in _memories.entries) {
      final backend = _agentBackends[seat];
      if (backend == null) continue;
      var lines = memory.store.where((c) => c.day == endedDay);
      if (lines.isEmpty) continue;
      if (lines.length > 20) lines = lines.sublist(lines.length - 20);
      final (client, model) = backend;
      unawaited(() async {
        try {
          final result = await client.chat(
            [
              ChatMessage.system(
                'You are ${state.names[seat]} in a social deduction game. '
                'Summarize the phase below in at most two short lines from '
                'your own perspective. Keep names, votes, accusations.',
              ),
              ChatMessage.user(lines.map((c) => c.text).join('\n')),
            ],
            model: model,
            maxTokens: 160,
          );
          if (epoch != _epoch) return;
          memory.summary.add(result.text.trim());
          await memory.summary.compactIfNeeded(
            (prompt) async => (await client.chat(
              [ChatMessage.user(prompt)],
              model: model,
              maxTokens: 200,
            )).text,
          );
        } on Exception {
          // Summaries are best-effort; retrieval and facts still stand.
        }
      }());
    }
  }

  @override
  GameSession build() {
    ref.onDispose(_teardown);
    return const GameSession();
  }

  UiHumanController? get humanController => _human;

  void _teardown() {
    _epoch++;
    for (final client in _clients) {
      client.close();
    }
    _clients.clear();
    _agentBackends = {};
    _memories.clear();
    _reasoning.clear();
    _roles = const {};
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
      gameId: 'game-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await _start(setup);
    } catch (error) {
      // Boundary catch: config/DB/keychain failures surface in the UI
      // rather than crashing the shell.
      state = state.copyWith(stage: GameStage.error, error: '$error');
    }
  }

  /// Resume an unfinished save: same seed, recorded decisions replay
  /// instantly, live controllers take over where the log ends.
  Future<void> resumeGame(String id) async {
    if (state.stage == GameStage.running) return;
    final db = ref.read(appDatabaseProvider);
    final row = await db.gameById(id);
    if (row == null || row.finished) {
      state = GameSession(
        stage: GameStage.error,
        error: row == null
            ? 'Save $id no longer exists'
            : 'That game is finished — watch it in Replays',
      );
      return;
    }
    state = GameSession(
      stage: GameStage.casting,
      humanSeat: row.humanSeat,
      townName: row.townName,
      gameId: row.id,
      notes: row.notes,
      scene: row.sceneJson == null
          ? null
          : sceneFromJson(
              (jsonDecode(row.sceneJson!) as Map).cast<String, Object?>(),
            ),
    );
    try {
      await _resume(row);
    } catch (error) {
      state = state.copyWith(stage: GameStage.error, error: '$error');
    }
  }

  Future<Persona Function(String)> _personaResolver() async {
    final db = ref.read(appDatabaseProvider);
    final customs = {
      for (final row in await db.watchPersonas().first)
        row.name: row.toPersona(),
    };
    final house = {for (final p in personaLibrary) p.name: p};
    return (String name) =>
        customs[name] ??
        house[name] ??
        Persona(
          name: name,
          archetype: 'townsperson',
          style: 'plain',
          quirk: 'unremarkable',
        );
  }

  Future<Map<int, String>> _grudgeMemories(List<String> names) async {
    if (!_grudgeMode) return const {};
    final json = await ref.read(appDatabaseProvider).pref(grudgeBookPrefKey);
    if (json == null) return const {};
    final grudges = GrudgeBook.fromJson(json);
    return {
      for (var s = 0; s < names.length; s++)
        if (grudges.promptBlockFor(names[s]) case final String block) s: block,
    };
  }

  Future<Future<ChatProvider> Function(String)> _clientResolver() async {
    final keyStore = ref.read(apiKeyStoreProvider);
    final factory = ref.read(clientFactoryProvider);
    final connections = {
      for (final c
          in await ref.read(appDatabaseProvider).watchConnections().first)
        c.id: c,
    };
    final cache = <String, ChatProvider>{};
    return (String connectionId) async {
      final cached = cache[connectionId];
      if (cached != null) return cached;
      final connection = connections[connectionId];
      if (connection == null) {
        throw StateError('Connection $connectionId no longer exists');
      }
      final client = factory(connection, await keyStore.read(connectionId));
      cache[connectionId] = client;
      _clients.add(client);
      return client;
    };
  }

  void Function(GameEvent) _guardedObserver() {
    final epoch = _epoch;
    return (event) {
      if (epoch == _epoch) _onEvent(event);
    };
  }

  void _launch(GameEngine engine) {
    _engine = engine;
    final epoch = _epoch;
    unawaited(
      engine.run().then((result) => _onFinished(result, epoch)).catchError((
        Object error,
      ) {
        if (epoch == _epoch) {
          state = state.copyWith(stage: GameStage.error, error: '$error');
        }
      }),
    );
  }

  Future<void> _start(LobbySetup setup) async {
    _grudgeMode = setup.grudgeMode;
    _difficulty = setup.difficulty;
    final personaOf = await _personaResolver();

    final personas = <int, Persona>{};
    final badges = <int, String>{};
    for (final seat in setup.aiSeats) {
      final casting = setup.seats[seat];
      personas[seat] = personaOf(casting.personaName!);
      badges[seat] = casting.model!.split('/').last;
    }
    personas[setup.humanSeat] = humanSeatPersona(
      setup.humanName.trim(),
      setup.humanPersona?.avatarPath,
    );
    badges[setup.humanSeat] = 'human';

    final names = [
      for (var s = 0; s < setup.config.seats; s++) personas[s]!.name,
    ];
    // The human slot carries the FP-persona avatar so resume keeps the face.
    _castingJson = jsonEncode([
      for (var s = 0; s < setup.config.seats; s++)
        s == setup.humanSeat
            ? {'human': true, 'avatarPath': setup.humanPersona?.avatarPath}
            : {
                'connectionId': setup.seats[s].connectionId,
                'model': setup.seats[s].model,
                'temperature': setup.seats[s].temperature,
              },
    ]);

    final prompts = AgentPromptBuilder(
      names: names,
      personas: personas,
      difficulty: _difficulty,
      pastMemories: await _grudgeMemories(names),
    );
    final clientFor = await _clientResolver();

    final human = UiHumanController();
    _human = human;
    _agentBackends = {};
    _buildMemories(setup.aiSeats);
    final controllers = <int, PlayerController>{setup.humanSeat: human};
    for (final seat in setup.aiSeats) {
      final casting = setup.seats[seat];
      final client = await clientFor(casting.connectionId!);
      controllers[seat] = AgentController(
        client: client,
        model: casting.model!,
        prompts: prompts,
        temperature: casting.temperature,
        memoryFor: _memoryFor(seat),
      )..onReason = (task, reason) => _recordReason(seat, task, reason);
      _agentBackends[seat] = (client, casting.model!);
    }

    await prewarmBackends(setup, _agentBackends);

    _rngSeed = Random().nextInt(1 << 31);
    state = state.copyWith(
      stage: GameStage.running,
      names: names,
      personas: personas,
      modelBadges: badges,
    );
    _launch(
      GameEngine(
        config: setup.config,
        controllers: controllers,
        rngSeed: _rngSeed,
        observer: _guardedObserver(),
      ),
    );
    await _autosave();
  }

  Future<void> _resume(Game row) async {
    final config = configFromJson(
      (jsonDecode(row.configJson) as Map).cast<String, Object?>(),
    );
    final recorded = [
      for (final e in jsonDecode(row.eventsJson) as List)
        eventFromJson((e as Map).cast<String, Object?>()),
    ];
    final names = (jsonDecode(row.namesJson) as List).cast<String>();
    final badges = {
      for (final MapEntry(:key, :value)
          in (jsonDecode(row.badgesJson) as Map)
              .cast<String, Object?>()
              .entries)
        int.parse(key): value! as String,
    };
    final castingList = jsonDecode(row.castingJson) as List;
    _grudgeMode = row.grudgeMode;
    _difficulty = Difficulty.values.byName(row.difficulty);
    _castingJson = row.castingJson;
    _rngSeed = row.rngSeed;

    final personaOf = await _personaResolver();
    final personas = {
      for (var s = 0; s < names.length; s++) s: personaOf(names[s]),
    };
    // The human slot map (new saves) restores the FP-persona avatar; old
    // saves stored null there and fall back to a bare identity.
    final humanCast = (castingList[row.humanSeat] as Map?)
        ?.cast<String, Object?>();
    personas[row.humanSeat] = humanSeatPersona(
      names[row.humanSeat],
      humanCast?['avatarPath'] as String?,
    );
    final prompts = AgentPromptBuilder(
      names: names,
      personas: personas,
      difficulty: _difficulty,
      pastMemories: await _grudgeMemories(names),
    );
    final clientFor = await _clientResolver();

    final human = UiHumanController();
    _human = human;
    _agentBackends = {};
    _buildMemories([
      for (var s = 0; s < names.length; s++)
        if (s != row.humanSeat) s,
    ]);
    final live = <int, PlayerController>{row.humanSeat: human};
    for (var seat = 0; seat < names.length; seat++) {
      if (seat == row.humanSeat) continue;
      final cast = (castingList[seat] as Map?)?.cast<String, Object?>();
      if (cast == null) {
        throw StateError('Save is missing casting for seat $seat');
      }
      final client = await clientFor(cast['connectionId']! as String);
      final model = cast['model']! as String;
      live[seat] = AgentController(
        client: client,
        model: model,
        prompts: prompts,
        temperature: (cast['temperature'] as num?)?.toDouble() ?? 0.7,
        memoryFor: _memoryFor(seat),
      )..onReason = (task, reason) => _recordReason(seat, task, reason);
      _agentBackends[seat] = (client, model);
    }

    state = state.copyWith(
      stage: GameStage.running,
      names: names,
      personas: personas,
      modelBadges: badges,
    );
    _launch(
      GameEngine(
        config: config,
        controllers: replayControllers(recorded: recorded, live: live),
        rngSeed: _rngSeed,
        observer: _guardedObserver(),
      ),
    );
  }

  Future<void> _autosave({bool finished = false}) async {
    final gameId = state.gameId;
    final engine = _engine;
    if (gameId == null || engine == null) return;
    await ref
        .read(appDatabaseProvider)
        .upsertGame(
          GamesCompanion(
            id: Value(gameId),
            townName: Value(state.townName ?? ''),
            savedAt: Value(DateTime.now()),
            finished: Value(finished),
            winner: Value(state.winner?.name),
            humanSeat: Value(state.humanSeat),
            rngSeed: Value(_rngSeed),
            difficulty: Value(_difficulty.name),
            grudgeMode: Value(_grudgeMode),
            namesJson: Value(jsonEncode(state.names)),
            badgesJson: Value(
              jsonEncode(state.modelBadges.map((k, v) => MapEntry('$k', v))),
            ),
            castingJson: Value(_castingJson),
            configJson: Value(jsonEncode(configToJson(engine.config))),
            sceneJson: Value(
              state.scene == null
                  ? null
                  : jsonEncode(sceneToJson(state.scene!)),
            ),
            eventsJson: Value(
              jsonEncode([for (final e in engine.events) eventToJson(e)]),
            ),
            notes: Value(state.notes),
          ),
        );
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
    unawaited(_autosave(finished: state.stage == GameStage.finished));
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
    _ingestForAgents(event);
    // Autosave on phase boundaries (UI_UX.md §5: crash-safe resume).
    if (event is DayBegan || event is NightBegan) unawaited(_autosave());
  }

  Future<void> _onFinished(GameResult result, [int? epoch]) async {
    if (epoch != null && epoch != _epoch) return;
    state = state.copyWith(stage: GameStage.finished, winner: result.winner);
    await _autosave(finished: true);
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
      observer: _guardedObserver(),
    );
    _engine = engine;
    final result = await engine.run();
    await _onFinished(result);
    return result;
  }

  /// Save-and-exit: the row stays resumable from Continue. The old
  /// engine's epoch is retired so its stragglers can't touch fresh state.
  Future<void> abandonGame() async {
    await _autosave(finished: state.stage == GameStage.finished);
    _teardown();
    state = const GameSession();
  }
}

@riverpod
GameStage sessionStage(Ref ref) =>
    ref.watch(gameSessionControllerProvider).stage;

@riverpod
Stream<List<Game>> savedGames(Ref ref) =>
    ref.watch(appDatabaseProvider).watchGames();

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
