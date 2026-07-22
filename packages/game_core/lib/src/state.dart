import 'event.dart';
import 'role.dart';

/// Game state as a pure fold over the event log. The engine derives all
/// state through [apply]; consumers can rebuild any point in time from a
/// save file's events.
class GameState {
  const GameState._({
    required this.seats,
    required this.roles,
    required this.alive,
    required this.day,
    required this.doctorLastTarget,
    required this.assassinBulletUsed,
    required this.sheriffVisited,
    required this.winner,
    required this.over,
  });

  const GameState.initial()
    : this._(
        seats: 0,
        roles: const {},
        alive: const {},
        day: 0,
        doctorLastTarget: null,
        assassinBulletUsed: false,
        sheriffVisited: const {},
        winner: null,
        over: false,
      );

  final int seats;
  final Map<int, Role> roles;
  final Set<int> alive;
  final int day;
  final int? doctorLastTarget;
  final bool assassinBulletUsed;
  final Set<int> sheriffVisited;
  final Faction? winner;
  final bool over;

  static GameState replay(Iterable<GameEvent> events) =>
      events.fold(const GameState.initial(), (s, e) => s.apply(e));

  Set<int> get livingMafia => {
    ...alive.where((s) => roles[s]?.faction == Faction.mafia),
  };

  Set<int> get livingTown => {
    ...alive.where((s) => roles[s]?.faction == Faction.town),
  };

  int? seatOf(Role role) {
    for (final MapEntry(:key, :value) in roles.entries) {
      if (value == role) return key;
    }
    return null;
  }

  GameState apply(GameEvent event) => switch (event) {
    GameStarted(:final seats) => _copy(
      seats: seats,
      alive: {for (var i = 0; i < seats; i++) i},
    ),
    RolesDealt(:final roles) => _copy(roles: Map.unmodifiable(roles)),
    DayBegan(:final day) => _copy(day: day),
    Verdict(:final eliminated) =>
      eliminated == null ? this : _copy(alive: {...alive}..remove(eliminated)),
    DawnAnnounced(:final deaths) => _copy(alive: {...alive}..removeAll(deaths)),
    DoctorProtected(:final target) => _copy(doctorLastTarget: target),
    SheriffInvestigated(:final target) => _copy(
      sheriffVisited: {...sheriffVisited, target},
    ),
    AssassinDecided(:final target) =>
      target == null ? this : _copy(assassinBulletUsed: true),
    GameEnded(:final winner) => _copy(winner: winner, over: true),
    _ => this,
  };

  GameState _copy({
    int? seats,
    Map<int, Role>? roles,
    Set<int>? alive,
    int? day,
    int? doctorLastTarget,
    bool? assassinBulletUsed,
    Set<int>? sheriffVisited,
    Faction? winner,
    bool? over,
  }) => GameState._(
    seats: seats ?? this.seats,
    roles: roles ?? this.roles,
    alive: alive ?? this.alive,
    day: day ?? this.day,
    doctorLastTarget: doctorLastTarget ?? this.doctorLastTarget,
    assassinBulletUsed: assassinBulletUsed ?? this.assassinBulletUsed,
    sheriffVisited: sheriffVisited ?? this.sheriffVisited,
    winner: winner ?? this.winner,
    over: over ?? this.over,
  );
}
