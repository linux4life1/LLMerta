import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  test('copyWith preserves untouched fields and applies overrides', () {
    const base = GameConfig(seats: 9, night0SheriffPeek: true);
    final copy = base.copyWith(
      seats: 14,
      discussionRounds: 2,
      tieRule: TieRule.runoff,
      includeAssassin: false,
      mafiaCountDelta: 1,
    );
    expect(copy.seats, 14);
    expect(copy.discussionRounds, 2);
    expect(copy.tieRule, TieRule.runoff);
    expect(copy.includeAssassin, isFalse);
    expect(copy.mafiaCountDelta, 1);
    expect(copy.night0SheriffPeek, isTrue);
    expect(copy.night0, base.night0);
    expect(copy.doctorMayProtectSelf, base.doctorMayProtectSelf);
    expect(copy.doctorNoRepeatTarget, base.doctorNoRepeatTarget);
    expect(copy.revealRolesOnDeath, base.revealRolesOnDeath);
    expect(copy.nomineesVote, base.nomineesVote);
    expect(copy.includeDoctor, base.includeDoctor);
    expect(copy.includeSheriff, base.includeSheriff);
    expect(copy.maxDays, base.maxDays);
  });

  test('copyWith enforces the same invariants as the constructor', () {
    const base = GameConfig(seats: 10);
    expect(() => base.copyWith(seats: 6), throwsA(isA<AssertionError>()));
    expect(
      () => base.copyWith(discussionRounds: 3),
      throwsA(isA<AssertionError>()),
    );
  });
}
