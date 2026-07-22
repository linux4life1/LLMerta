import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

/// Never nominates and never kills: forces the maxDays draw backstop.
class PassiveController extends RandomLegalController {
  PassiveController() : super(0);

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) async =>
      null;

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) async =>
      null;

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) async =>
      null;
}

void main() {
  selfVoteTests();
  runoffAndFallbackTests();
  test('a full scripted game terminates with a factional winner', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 8),
      seed: 42,
    );
    expect(result.winner, isNotNull);
    expect(result.events.whereType<GameEnded>(), hasLength(1));
    expect(result.events.last, isA<GameEnded>());
  });

  test(
    'night 0 holds mafia chat but no kill and day 1 dawn is bloodless',
    () async {
      final result = await runScriptedGame(
        config: const GameConfig(seats: 7),
        seed: 7,
      );
      final events = result.events;
      final night0 = events.whereType<NightBegan>().first;
      expect(night0.day, 0);
      expect(events.whereType<MafiaChatSaid>(), isNotEmpty);
      final dawn1 = events.whereType<DawnAnnounced>().first;
      expect(dawn1.deaths, isEmpty);
      // No night-0 kill machinery, protection, or assassin decision.
      final firstDay = events.indexWhere((e) => e is DayBegan);
      final beforeDay1 = events.sublist(0, firstDay);
      expect(beforeDay1.whereType<MafiaKillChosen>(), isEmpty);
      expect(beforeDay1.whereType<DoctorProtected>(), isEmpty);
      expect(beforeDay1.whereType<AssassinDecided>(), isEmpty);
    },
  );

  test('night0 off skips straight to day 1', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 7, night0: false),
      seed: 7,
    );
    expect(result.events.whereType<NightBegan>().first.day, greaterThan(0));
  });

  test('sheriff peek on night 0 only when configured', () async {
    Future<bool> peeked({required bool config}) async {
      final result = await runScriptedGame(
        config: GameConfig(seats: 7, night0SheriffPeek: config),
        seed: 11,
      );
      final events = result.events;
      final firstDay = events.indexWhere((e) => e is DayBegan);
      return events
          .sublist(0, firstDay)
          .whereType<SheriffInvestigated>()
          .isNotEmpty;
    }

    expect(await peeked(config: true), isTrue);
    expect(await peeked(config: false), isFalse);
  });

  test('unresponsive seats fall back and the game still finishes', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 8),
      seed: 3,
      overrides: {0: UnresponsiveController(), 5: UnresponsiveController()},
    );
    expect(result.events.whereType<FallbackApplied>(), isNotEmpty);
    expect(result.events.whereType<GameEnded>(), hasLength(1));
  });

  test('stalemate hits the maxDays backstop as a draw', () async {
    final controllers = {for (var s = 0; s < 7; s++) s: PassiveController()};
    final result = await GameEngine(
      config: const GameConfig(seats: 7, maxDays: 3),
      controllers: controllers,
      rngSeed: 1,
    ).run();
    expect(result.winner, isNull);
    expect(result.events.whereType<GameEnded>().single.winner, isNull);
  });

  test('same seed reproduces the identical event log', () async {
    String fingerprint(List<GameEvent> events) =>
        events.map((e) => e.runtimeType.toString()).join(',');
    final a = await runScriptedGame(
      config: const GameConfig(seats: 9),
      seed: 99,
    );
    final b = await runScriptedGame(
      config: const GameConfig(seats: 9),
      seed: 99,
    );
    expect(fingerprint(a.events), fingerprint(b.events));
    expect(a.winner, b.winner);
  });

  test('replaying the event log reproduces the final state', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 10),
      seed: 5,
    );
    final replayed = GameState.replay(result.events);
    expect(replayed.over, isTrue);
    expect(replayed.winner, result.winner);
  });

  test('doctor never protects the same target on consecutive nights', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 8),
      seed: 21,
    );
    final protections = result.events.whereType<DoctorProtected>().map(
      (e) => e.target,
    );
    int? previous;
    for (final target in protections) {
      expect(target, isNot(previous));
      previous = target;
    }
  });

  test('assassin fires at most once per game', () async {
    for (var seed = 0; seed < 30; seed++) {
      final result = await runScriptedGame(
        config: const GameConfig(seats: 8),
        seed: seed,
      );
      final shots = result.events.whereType<AssassinDecided>().where(
        (e) => e.target != null,
      );
      expect(shots.length, lessThanOrEqualTo(1), reason: 'seed $seed');
    }
  });
}

/// Splits the day-1 vote 3–3 (seat 6 abstains) to force the runoff path.
class TieForcingController extends RandomLegalController {
  TieForcingController(this.seat) : super(seat);

  final int seat;

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) async =>
      ctx.day == 1 ? (seat == 0 ? 1 : 0) : null;

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) async {
    if (ctx.day != 1 || nominees.length < 2) return nominees.first;
    if (seat == 6) return null;
    return nominees[seat % 2];
  }
}

void runoffAndFallbackTests() {
  test(
    'runoff re-votes the tied slate once, second tie spares everyone',
    () async {
      final result = await runScriptedGame(
        config: const GameConfig(seats: 7, tieRule: TieRule.runoff, maxDays: 2),
        seed: 13,
        overrides: {for (var s = 0; s < 7; s++) s: TieForcingController(s)},
      );
      final day1Votes = result.events.whereType<VotesRevealed>().take(2);
      expect(day1Votes, hasLength(2), reason: 'initial vote plus one runoff');
      expect(result.events.whereType<Verdict>().first.eliminated, isNull);
    },
  );

  test('an entirely unresponsive table still plays to a verdict', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 7),
      seed: 17,
      overrides: {for (var s = 0; s < 7; s++) s: UnresponsiveController()},
    );
    expect(result.events.whereType<GameEnded>(), hasLength(1));
    expect(result.winner, isNotNull);
    final actions = result.events
        .whereType<FallbackApplied>()
        .map((e) => e.action)
        .toSet();
    expect(
      actions,
      containsAll([
        'speak',
        'nominate',
        'mafiaChat',
        'mafiaKillVote',
        'doctorProtect',
        'sheriffInvestigate',
        'assassinShoot',
      ]),
    );
  });

  test('engine exposes live state during and after a run', () async {
    final engine = GameEngine(
      config: const GameConfig(seats: 7),
      controllers: {for (var s = 0; s < 7; s++) s: RandomLegalController(s)},
      rngSeed: 23,
    );
    await engine.run();
    expect(engine.state.over, isTrue);
    expect(engine.events, isNotEmpty);
  });
}

/// Always votes for the first option offered — used to prove a nominee is
/// never offered themself.
class FirstOptionController extends RandomLegalController {
  FirstOptionController() : super(0);

  final offered = <List<int>>[];

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) async {
    offered.add([...nominees]);
    return nominees.isEmpty ? null : nominees.first;
  }
}

void selfVoteTests() {
  test('nominees are never offered themselves on the ballot', () async {
    final controllers = {
      for (var s = 0; s < 7; s++) s: FirstOptionController(),
    };
    final result = await GameEngine(
      config: const GameConfig(seats: 7, maxDays: 4),
      controllers: controllers,
      rngSeed: 8,
    ).run();
    for (final entry in controllers.entries) {
      for (final options in entry.value.offered) {
        expect(options, isNot(contains(entry.key)));
      }
    }
    for (final votes in result.events.whereType<VotesRevealed>()) {
      for (final MapEntry(:key, :value) in votes.votes.entries) {
        expect(value, isNot(key), reason: 'self-vote leaked into results');
      }
    }
  });
}
