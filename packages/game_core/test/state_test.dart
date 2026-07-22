import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  const roles = {
    0: Role.mafioso,
    1: Role.doctor,
    2: Role.sheriff,
    3: Role.assassin,
    4: Role.villager,
    5: Role.villager,
    6: Role.villager,
  };

  test('replay folds the full lifecycle', () {
    final state = GameState.replay([
      const GameStarted(seats: 7),
      const RolesDealt(roles),
      const NightBegan(0),
      const DayBegan(1),
      const DawnAnnounced(deaths: [], revealedRoles: {}),
      const Verdict(eliminated: 4, revealedRole: Role.villager),
      const NightBegan(1),
      const DoctorProtected(doctor: 1, target: 2),
      const SheriffInvestigated(sheriff: 2, target: 0, foundMafia: true),
      const AssassinDecided(assassin: 3, target: 5),
      const DayBegan(2),
      const DawnAnnounced(deaths: [5], revealedRoles: {5: Role.villager}),
    ]);
    expect(state.seats, 7);
    expect(state.alive, {0, 1, 2, 3, 6});
    expect(state.day, 2);
    expect(state.doctorLastTarget, 2);
    expect(state.sheriffVisited, {0});
    expect(state.assassinBulletUsed, isTrue);
    expect(state.livingMafia, {0});
    expect(state.livingTown, {1, 2, 3, 6});
    expect(state.over, isFalse);
  });

  test('holding the bullet does not spend it', () {
    final state = GameState.replay([
      const GameStarted(seats: 7),
      const RolesDealt(roles),
      const AssassinDecided(assassin: 3, target: null),
    ]);
    expect(state.assassinBulletUsed, isFalse);
  });

  test('tie verdict removes nobody', () {
    final state = GameState.replay([
      const GameStarted(seats: 7),
      const RolesDealt(roles),
      const Verdict(eliminated: null, revealedRole: null),
    ]);
    expect(state.alive, hasLength(7));
  });

  test('game end records the winner', () {
    final state = GameState.replay([
      const GameStarted(seats: 7),
      const GameEnded(winner: Faction.town),
    ]);
    expect(state.over, isTrue);
    expect(state.winner, Faction.town);
  });

  test('seatOf finds unique roles', () {
    final state = GameState.replay([
      const GameStarted(seats: 7),
      const RolesDealt(roles),
    ]);
    expect(state.seatOf(Role.doctor), 1);
    expect(state.seatOf(Role.sheriff), 2);
  });
}
