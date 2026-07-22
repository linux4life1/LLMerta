import 'role.dart';

// Distribution table from GAME_DESIGN.md §3.
const int minSeats = 7;
const int maxSeats = 14;

int mafiaCountFor(int seats) {
  _checkSeats(seats);
  if (seats <= 9) return 2;
  if (seats <= 12) return 3;
  return 4;
}

List<Role> rolesFor(int seats) {
  final mafia = mafiaCountFor(seats);
  return List.unmodifiable([
    for (var i = 0; i < mafia; i++) Role.mafioso,
    Role.doctor,
    Role.sheriff,
    Role.assassin,
    for (var i = 0; i < seats - mafia - 3; i++) Role.villager,
  ]);
}

void _checkSeats(int seats) {
  if (seats < minSeats || seats > maxSeats) {
    throw ArgumentError.value(seats, 'seats', 'must be $minSeats..$maxSeats');
  }
}
