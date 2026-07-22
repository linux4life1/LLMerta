import 'role_distribution.dart';

enum TieRule { noElimination, runoff, randomAmongTied }

/// Rule configuration from GAME_DESIGN.md; defaults match the doc.
class GameConfig {
  const GameConfig({
    required this.seats,
    this.doctorMayProtectSelf = true,
    this.doctorNoRepeatTarget = true,
    this.night0 = true,
    this.night0SheriffPeek = false,
    this.revealRolesOnDeath = true,
    this.discussionRounds = 1,
    this.nomineesVote = true,
    this.tieRule = TieRule.noElimination,
    this.includeDoctor = true,
    this.includeSheriff = true,
    this.includeAssassin = true,
    this.mafiaCountDelta = 0,
    this.maxDays = 50,
  }) : assert(seats >= minSeats && seats <= maxSeats),
       assert(discussionRounds >= 1 && discussionRounds <= 2),
       assert(mafiaCountDelta >= -1 && mafiaCountDelta <= 1),
       assert(maxDays > 0);

  final int seats;
  final bool doctorMayProtectSelf;
  final bool doctorNoRepeatTarget;
  final bool night0;
  final bool night0SheriffPeek;
  final bool revealRolesOnDeath;
  final int discussionRounds;
  final bool nomineesVote;
  final TieRule tieRule;
  final bool includeDoctor;
  final bool includeSheriff;
  final bool includeAssassin;
  final int mafiaCountDelta;

  /// Engine safety backstop, not a game rule: stalemates (e.g. perpetual
  /// vote ties with every kill doctor-blocked) end in a draw rather than
  /// looping forever.
  final int maxDays;
}
