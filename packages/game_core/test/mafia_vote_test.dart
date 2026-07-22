import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  test('unique plurality wins', () {
    expect(
      mafiaKillTarget(
        votes: {1: 4, 2: 4, 3: 6},
        livingMafiaInSeatOrder: [1, 2, 3],
      ),
      4,
    );
  });

  test('tie broken by the senior member\'s vote', () {
    expect(
      mafiaKillTarget(
        votes: {1: 6, 2: 4, 3: 6, 4: 4},
        livingMafiaInSeatOrder: [1, 2, 3, 4],
      ),
      6,
    );
  });

  test('senior abstained: first tied leader after senior seat wins', () {
    expect(
      mafiaKillTarget(
        votes: {1: null, 2: 4, 3: 6},
        livingMafiaInSeatOrder: [1, 2, 3],
      ),
      4,
    );
  });

  test('senior voted off-slate: deterministic wrap picks a leader', () {
    // Leaders {0, 2}; senior seat 5 voted for 9 (one vote, also a leader?
    // no: 0 and 2 have two votes each, 9 has one). First leader after 5
    // wraps to 0.
    expect(
      mafiaKillTarget(
        votes: {5: 9, 6: 0, 7: 0, 8: 2, 9: 2},
        livingMafiaInSeatOrder: [5, 6, 7, 8, 9],
      ),
      0,
    );
  });

  test('nobody voted: no kill', () {
    expect(
      mafiaKillTarget(
        votes: {1: null, 2: null},
        livingMafiaInSeatOrder: [1, 2],
      ),
      isNull,
    );
  });
}
