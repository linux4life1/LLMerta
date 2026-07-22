import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  group('trialSlate', () {
    test('takes the two most-nominated', () {
      final slate = trialSlate([
        (0, 3),
        (1, 3),
        (2, 5),
        (3, 5),
        (4, 5),
        (5, 7),
      ]);
      expect(slate, [5, 3]);
    });

    test('tie for a slot goes to whoever reached the count first', () {
      // 3 and 5 both end on two nominations; 3 reached two first.
      final slate = trialSlate([(0, 3), (1, 3), (2, 5), (4, 5), (6, 8)]);
      expect(slate, [3, 5]);
    });

    test('single nominee stands trial alone', () {
      expect(trialSlate([(0, null), (1, 4), (2, null)]), [4]);
    });

    test('no nominations: empty slate ends the day', () {
      expect(trialSlate([(0, null), (1, null)]), isEmpty);
    });
  });

  group('verdict', () {
    final rng = Random(1);

    test('strict plurality eliminates', () {
      final r = verdict(
        {0: 3, 1: 3, 2: 5, 4: null},
        TieRule.noElimination,
        rng,
      );
      expect(r.eliminated, 3);
      expect(r.runoff, isEmpty);
    });

    test('tie eliminates nobody by default', () {
      final r = verdict({0: 3, 1: 5, 2: null}, TieRule.noElimination, rng);
      expect(r.eliminated, isNull);
      expect(r.runoff, isEmpty);
    });

    test('all abstain eliminates nobody', () {
      final r = verdict({0: null, 1: null}, TieRule.noElimination, rng);
      expect(r.eliminated, isNull);
    });

    test('runoff rule returns the tied slate', () {
      final r = verdict({0: 3, 1: 5}, TieRule.runoff, rng);
      expect(r.eliminated, isNull);
      expect(r.runoff, [3, 5]);
    });

    test(
      'randomAmongTied picks one of the tied, deterministically by seed',
      () {
        final a = verdict({0: 3, 1: 5}, TieRule.randomAmongTied, Random(7));
        final b = verdict({0: 3, 1: 5}, TieRule.randomAmongTied, Random(7));
        expect(a.eliminated, b.eliminated);
        expect([3, 5], contains(a.eliminated));
      },
    );
  });
}
