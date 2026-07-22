import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

GameState _state(Map<int, Role> roles, Set<int> alive) => GameState.replay([
  GameStarted(seats: roles.length),
  RolesDealt(roles),
  DawnAnnounced(
    deaths: [
      for (var s = 0; s < roles.length; s++)
        if (!alive.contains(s)) s,
    ],
    revealedRoles: const {},
  ),
]);

void main() {
  const roles = {
    0: Role.mafioso,
    1: Role.mafioso,
    2: Role.doctor,
    3: Role.sheriff,
    4: Role.assassin,
    5: Role.villager,
    6: Role.villager,
  };

  test('game continues while both factions live below parity', () {
    expect(winner(_state(roles, {0, 1, 2, 3, 4, 5, 6})), isNull);
  });

  test('town wins when all mafia are dead', () {
    expect(winner(_state(roles, {2, 3, 4, 5, 6})), Faction.town);
  });

  test('mafia wins at parity', () {
    expect(winner(_state(roles, {0, 1, 5, 6})), Faction.mafia);
  });

  test('mafia wins beyond parity', () {
    expect(winner(_state(roles, {0, 1, 5})), Faction.mafia);
  });

  test('one mafioso vs two town continues', () {
    expect(winner(_state(roles, {0, 5, 6})), isNull);
  });
}
