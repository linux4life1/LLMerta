import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  const expectedMafia = {7: 2, 8: 2, 9: 2, 10: 3, 11: 3, 12: 3, 13: 4, 14: 4};

  test('mafia count follows the design table', () {
    for (final entry in expectedMafia.entries) {
      expect(mafiaCountFor(entry.key), entry.value);
    }
  });

  test(
    'every game seats doctor, sheriff, assassin and fills with villagers',
    () {
      for (var seats = minSeats; seats <= maxSeats; seats++) {
        final roles = rolesFor(seats);
        expect(roles.length, seats);
        expect(
          roles.where((r) => r == Role.mafioso).length,
          expectedMafia[seats],
        );
        expect(roles.where((r) => r == Role.doctor).length, 1);
        expect(roles.where((r) => r == Role.sheriff).length, 1);
        expect(roles.where((r) => r == Role.assassin).length, 1);
        expect(
          roles.where((r) => r == Role.villager).length,
          seats - expectedMafia[seats]! - 3,
        );
      }
    },
  );

  test('only the mafioso is mafia-aligned', () {
    expect(Role.mafioso.faction, Faction.mafia);
    for (final role in Role.values.where((r) => r != Role.mafioso)) {
      expect(role.faction, Faction.town);
    }
  });

  test('rejects seat counts outside 7..14', () {
    expect(() => rolesFor(6), throwsArgumentError);
    expect(() => rolesFor(15), throwsArgumentError);
    expect(() => mafiaCountFor(0), throwsArgumentError);
  });

  test('role lists are unmodifiable', () {
    expect(() => rolesFor(7).add(Role.villager), throwsUnsupportedError);
  });
}
