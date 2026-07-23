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
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) async =>
      candidates.first;

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
    final a = PacedController(_InstantSpeaker(), pacer);
    final b = PacedController(_InstantSpeaker(), pacer);

    final clock = Stopwatch()..start();
    await a.speak(_ctx()); // First speech: no prior floor, returns fast.
    final first = clock.elapsedMilliseconds;
    await b.speak(_ctx()); // Must wait out the first speech's floor.
    final second = clock.elapsedMilliseconds;

    expect(first, lessThan(150));
    expect(second, greaterThanOrEqualTo(200));
  });

  test('private choices are never paced', () async {
    final pacer = TablePacer(
      readingTime: (_) => const Duration(milliseconds: 500),
    );
    final paced = PacedController(_InstantSpeaker(), pacer);
    await paced.speak(_ctx()); // Floor is now held for 500ms.

    final clock = Stopwatch()..start();
    await paced.vote(_ctx(), [1, 2]);
    await paced.nominate(_ctx(), [1, 2]);
    await paced.mafiaChat(_ctx());
    expect(clock.elapsedMilliseconds, lessThan(150));
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
