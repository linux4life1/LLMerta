/// Simultaneous night resolution per GAME_DESIGN.md §2:
/// - Doctor protection blocks the Mafia kill and the Assassin's bullet
///   (the bullet is still spent — tracked via the AssassinDecided event).
/// - Mafia kill and Assassin shot can both land in one night.
/// - Same target protected → nobody dies.
({List<int> killed, List<int> saved}) resolveNight({
  required int? mafiaTarget,
  required int? assassinTarget,
  required int? protectedSeat,
}) {
  final killed = <int>[];
  final saved = <int>[];
  for (final target in {mafiaTarget, assassinTarget}) {
    if (target == null) continue;
    if (target == protectedSeat) {
      saved.add(target);
    } else {
      killed.add(target);
    }
  }
  return (killed: killed..sort(), saved: saved..sort());
}
