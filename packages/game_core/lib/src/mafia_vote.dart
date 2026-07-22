/// Mafia kill decision per GAME_DESIGN.md §4.4.1: plurality of the living
/// mafia's votes; the senior member (first living mafia in seat order)
/// breaks ties — their vote wins if it is among the tied leaders, else the
/// tied target nearest after the senior's seat (deterministic).
int? mafiaKillTarget({
  required Map<int, int?> votes,
  required List<int> livingMafiaInSeatOrder,
}) {
  final counts = <int, int>{};
  for (final target in votes.values) {
    if (target != null) counts[target] = (counts[target] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final max = counts.values.reduce((a, b) => a > b ? a : b);
  final leaders = [
    for (final MapEntry(:key, :value) in counts.entries)
      if (value == max) key,
  ]..sort();
  if (leaders.length == 1) return leaders.first;
  final senior = livingMafiaInSeatOrder.first;
  final seniorVote = votes[senior];
  if (seniorVote != null && leaders.contains(seniorVote)) return seniorVote;
  return leaders.firstWhere((s) => s > senior, orElse: () => leaders.first);
}
