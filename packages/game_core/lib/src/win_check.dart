import 'role.dart';
import 'state.dart';

/// GAME_DESIGN.md §4.5, checked after every death (day or night).
/// Town wins when no Mafia live; Mafia wins at parity (living mafia ≥
/// living non-mafia). Null = game continues.
Faction? winner(GameState state) {
  final mafia = state.livingMafia.length;
  if (mafia == 0) return Faction.town;
  if (mafia >= state.alive.length - mafia) return Faction.mafia;
  return null;
}
