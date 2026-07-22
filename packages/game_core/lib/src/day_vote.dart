import 'dart:math';

import 'config.dart';

/// Trial slate per GAME_DESIGN.md §4.3: the two most-nominated stand trial;
/// a tie for a slot goes to whoever reached that nomination count first.
/// Nominations are (nominator, target?) in cast order; passes are ignored.
List<int> trialSlate(List<(int, int?)> nominations) {
  final counts = <int, int>{};
  // Seat → the index at which it reached its final count (for tiebreak).
  final reachedAt = <int, int>{};
  for (var i = 0; i < nominations.length; i++) {
    final target = nominations[i].$2;
    if (target == null) continue;
    counts[target] = (counts[target] ?? 0) + 1;
    reachedAt[target] = i;
  }
  final ranked = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      return reachedAt[a]!.compareTo(reachedAt[b]!);
    });
  return ranked.take(2).toList();
}

/// Verdict per §4.3.6: strict plurality eliminates; otherwise the tie rule
/// applies. Runoff is resolved by the engine re-voting, so this returns the
/// tied slate for it. Votes are voter → nominee (null = abstain).
({int? eliminated, List<int> runoff}) verdict(
  Map<int, int?> votes,
  TieRule tieRule,
  Random rng,
) {
  final counts = <int, int>{};
  for (final target in votes.values) {
    if (target != null) counts[target] = (counts[target] ?? 0) + 1;
  }
  if (counts.isEmpty) return (eliminated: null, runoff: const []);
  final max = counts.values.reduce((a, b) => a > b ? a : b);
  final leaders = [
    for (final MapEntry(:key, :value) in counts.entries)
      if (value == max) key,
  ]..sort();
  if (leaders.length == 1) return (eliminated: leaders.first, runoff: const []);
  return switch (tieRule) {
    TieRule.noElimination => (eliminated: null, runoff: const []),
    TieRule.randomAmongTied => (
      eliminated: leaders[rng.nextInt(leaders.length)],
      runoff: const [],
    ),
    TieRule.runoff => (eliminated: null, runoff: leaders),
  };
}
