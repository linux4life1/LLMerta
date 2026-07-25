import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llmerta_app/game_table/game_table.dart';

class _InstantSpeaker extends PlayerController {
  var calls = 0;

  @override
  Future<String> speak(DecisionContext ctx) async {
    calls++;
    return 'line $calls with a few words';
  }

  @override
  Future<String> defend(DecisionContext ctx) async => 'my defense';

  @override
  Future<String> lastWords(DecisionContext ctx) async => 'goodbye';

  @override
  Future<String> mafiaChat(DecisionContext ctx) async => 'psst';

  @override
  Future<(int?, String)> argue(
    DecisionContext ctx,
    List<int> candidates,
  ) async => (candidates.first, 'I challenge you.');

  @override
  Future<String> rebut(
    DecisionContext ctx, {
    required int challenger,
    required String challenge,
  }) async => 'I push back.';

  @override
  Future<(int?, String)> nominate(
    DecisionContext ctx,
    List<int> candidates,
  ) async => (candidates.first, 'My case is simple.');

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) async => null;

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) async =>
      null;

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) async =>
      targets.first;

  @override
  Future<int> sheriffInvestigate(
    DecisionContext ctx,
    List<int> targets,
  ) async => targets.first;

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) async =>
      null;
}

DecisionContext _ctx() => DecisionContext(
  seat: 0,
  role: Role.villager,
  day: 1,
  visibleEvents: const [GameStarted(seats: 7)],
  livingSeats: const [0, 1, 2],
);

void main() {
  test('speeches hold the floor for their reading time', () async {
    final pacer = TablePacer(
      readingTime: (_) => const Duration(milliseconds: 200),
    );
    final a = PacedController(_InstantSpeaker(), pacer, seat: 1);
    final b = PacedController(_InstantSpeaker(), pacer, seat: 2);

    final clock = Stopwatch()..start();
    await a.speak(_ctx()); // First speech: no prior floor, returns fast.
    final first = clock.elapsedMilliseconds;
    await b.speak(_ctx()); // Must wait out the first speech's floor.
    final second = clock.elapsedMilliseconds;

    expect(first, lessThan(150));
    expect(second, greaterThanOrEqualTo(200));
  });

  test('public prompts wait the floor; private acts never do', () async {
    final pacer = TablePacer(
      readingTime: (_) => const Duration(milliseconds: 300),
    );
    final paced = PacedController(_InstantSpeaker(), pacer, seat: 0);
    await paced.speak(_ctx()); // Floor is now held for 300ms.

    // Night/private acts ignore the floor entirely.
    var clock = Stopwatch()..start();
    await paced.mafiaChat(_ctx());
    await paced.mafiaKillVote(_ctx(), [1, 2]);
    await paced.doctorProtect(_ctx(), [1, 2]);
    expect(clock.elapsedMilliseconds, lessThan(150));

    // The vote prompt waits out the defense's floor (field report:
    // "it told me to vote before the defenses could be read").
    clock = Stopwatch()..start();
    await paced.vote(_ctx(), [1, 2]);
    expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(110));
  });

  test('nomination statements hold the floor like speeches', () async {
    final pacer = TablePacer(
      readingTime: (_) => const Duration(milliseconds: 200),
    );
    final paced = PacedController(_InstantSpeaker(), pacer, seat: 0);
    final (target, statement) = await paced.nominate(_ctx(), [1, 2]);
    expect(target, 1);
    expect(statement, isNotEmpty);

    // The next public act waits out the statement's floor.
    final clock = Stopwatch()..start();
    await paced.vote(_ctx(), [1, 2]);
    expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(180));
  });

  test('speaking is announced only after the standing floor drains', () async {
    final pacer = TablePacer(
      readingTime: (_) => const Duration(milliseconds: 200),
    );
    final log = <(int, TableActivity?, int)>[];
    final clock = Stopwatch()..start();
    void note(int seat, TableActivity? activity) =>
        log.add((seat, activity, clock.elapsedMilliseconds));
    final a = PacedController(
      _InstantSpeaker(),
      pacer,
      seat: 1,
      onActivity: note,
    );
    final b = PacedController(
      _InstantSpeaker(),
      pacer,
      seat: 2,
      onActivity: note,
    );

    await a.speak(_ctx());
    await b.speak(_ctx());

    final aClaim = log.firstWhere((e) => e.$1 == 1 && e.$2 != null);
    final bClaim = log.firstWhere((e) => e.$1 == 2 && e.$2 != null);
    expect(aClaim.$2, TableActivity.speaking);
    expect(aClaim.$3, lessThan(150));
    // Seat 2 must not be named the speaker while seat 1's line still
    // holds the floor (the dock/center-stage mismatch).
    expect(bClaim.$2, TableActivity.speaking);
    expect(bClaim.$3, greaterThanOrEqualTo(180));
    expect(log.last, (2, null, log.last.$3));
  });

  test('default reading time scales with words within clamps', () {
    final short = TablePacer.defaultReadingTime('hi');
    final medium = TablePacer.defaultReadingTime(
      List.filled(40, 'word').join(' '),
    );
    final epic = TablePacer.defaultReadingTime(
      List.filled(500, 'word').join(' '),
    );
    expect(short, const Duration(milliseconds: 1500));
    expect(medium, greaterThan(short));
    expect(epic, const Duration(milliseconds: 14000));
    expect(
      TablePacer.defaultReadingTime('  '),
      const Duration(milliseconds: 1500),
    );
  });
}
