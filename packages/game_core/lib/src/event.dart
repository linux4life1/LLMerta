import 'role.dart';
import 'visibility.dart';

sealed class GameEvent {
  const GameEvent();

  Scope get scope;
}

extension VisibleEvents on Iterable<GameEvent> {
  /// The only sanctioned way to hand events to a UI or an agent
  /// (CLAUDE.md visibility invariant).
  List<GameEvent> visibleTo(int seat, {required bool isMafia}) => [
    for (final e in this)
      if (e.scope.visibleTo(seat, isMafia: isMafia)) e,
  ];
}

// ---- Setup ----

class GameStarted extends GameEvent {
  const GameStarted({required this.seats});

  final int seats;

  @override
  Scope get scope => public;
}

class RolesDealt extends GameEvent {
  const RolesDealt(this.roles);

  /// Seat → role for every seat.
  final Map<int, Role> roles;

  @override
  Scope get scope => omniscient;
}

class RoleReceived extends GameEvent {
  const RoleReceived({required this.seat, required this.role});

  final int seat;
  final Role role;

  @override
  Scope get scope => PrivateScope(seat);
}

class MafiaTeamRevealed extends GameEvent {
  const MafiaTeamRevealed(this.team);

  final Set<int> team;

  @override
  Scope get scope => mafiaOnly;
}

// ---- Phase markers ----

class NightBegan extends GameEvent {
  const NightBegan(this.day);

  /// Night N precedes Day N+1; night 0 is the optional no-kill night.
  final int day;

  @override
  Scope get scope => public;
}

class DayBegan extends GameEvent {
  const DayBegan(this.day);

  final int day;

  @override
  Scope get scope => public;
}

// ---- Day ----

class DawnAnnounced extends GameEvent {
  const DawnAnnounced({required this.deaths, required this.revealedRoles});

  final List<int> deaths;

  /// Seat → role, only for [deaths] and only when reveal-on-death is on.
  final Map<int, Role> revealedRoles;

  @override
  Scope get scope => public;
}

class SpeechGiven extends GameEvent {
  const SpeechGiven({required this.seat, required this.text});

  final int seat;
  final String text;

  @override
  Scope get scope => public;
}

/// Crossfire: [by] challenges [to] mid-discussion (not a nomination).
/// [to] null = pass (emitted so replays record the decision).
class ArgumentOpened extends GameEvent {
  const ArgumentOpened({
    required this.by,
    required this.to,
    required this.text,
  });

  final int by;
  final int? to;
  final String text;

  @override
  Scope get scope => public;
}

/// Immediate reply from the challenged seat.
class ArgumentRebuttal extends GameEvent {
  const ArgumentRebuttal({
    required this.by,
    required this.to,
    required this.text,
  });

  final int by;
  final int to;
  final String text;

  @override
  Scope get scope => public;
}

class NominationCast extends GameEvent {
  const NominationCast({
    required this.by,
    required this.target,
    this.statement = '',
  });

  final int by;

  /// Null = pass.
  final int? target;

  /// The nominator's public case, spoken to the table ('' on a quiet
  /// pass or for pre-v0.1.5 saves).
  final String statement;

  @override
  Scope get scope => public;
}

class TrialStarted extends GameEvent {
  const TrialStarted(this.nominees);

  final List<int> nominees;

  @override
  Scope get scope => public;
}

class DefenseGiven extends GameEvent {
  const DefenseGiven({required this.seat, required this.text});

  final int seat;
  final String text;

  @override
  Scope get scope => public;
}

class VotesRevealed extends GameEvent {
  const VotesRevealed(this.votes);

  /// Voter → nominee, null = abstain. Cast simultaneously, revealed at once.
  final Map<int, int?> votes;

  @override
  Scope get scope => public;
}

class Verdict extends GameEvent {
  const Verdict({required this.eliminated, required this.revealedRole});

  /// Null = tie / no strict plurality → nobody eliminated.
  final int? eliminated;
  final Role? revealedRole;

  @override
  Scope get scope => public;
}

class LastWordsGiven extends GameEvent {
  const LastWordsGiven({required this.seat, required this.text});

  final int seat;
  final String text;

  @override
  Scope get scope => public;
}

// ---- Night ----

class MafiaChatSaid extends GameEvent {
  const MafiaChatSaid({required this.seat, required this.text});

  final int seat;
  final String text;

  @override
  Scope get scope => mafiaOnly;
}

class MafiaKillVoteCast extends GameEvent {
  const MafiaKillVoteCast({required this.by, required this.target});

  final int by;
  final int? target;

  @override
  Scope get scope => mafiaOnly;
}

class MafiaKillChosen extends GameEvent {
  const MafiaKillChosen(this.target);

  final int? target;

  @override
  Scope get scope => mafiaOnly;
}

class DoctorProtected extends GameEvent {
  const DoctorProtected({required this.doctor, required this.target});

  final int doctor;
  final int target;

  @override
  Scope get scope => PrivateScope(doctor);
}

class SheriffInvestigated extends GameEvent {
  const SheriffInvestigated({
    required this.sheriff,
    required this.target,
    required this.foundMafia,
  });

  final int sheriff;
  final int target;
  final bool foundMafia;

  @override
  Scope get scope => PrivateScope(sheriff);
}

class AssassinDecided extends GameEvent {
  const AssassinDecided({required this.assassin, required this.target});

  final int assassin;

  /// Null = hold the bullet.
  final int? target;

  @override
  Scope get scope => PrivateScope(assassin);
}

/// Private post-resolution feedback for a spent bullet: whether it killed
/// and whether the target was mafia. Town-only skill signal; never public.
class AssassinShotResolved extends GameEvent {
  const AssassinShotResolved({
    required this.assassin,
    required this.target,
    required this.killed,
    required this.wasMafia,
  });

  final int assassin;
  final int target;

  /// False when the Doctor protected the target (bullet still spent).
  final bool killed;
  final bool wasMafia;

  @override
  Scope get scope => PrivateScope(assassin);
}

class NightResolved extends GameEvent {
  const NightResolved({required this.killed, required this.saved});

  final List<int> killed;

  /// Targets whose deaths the Doctor blocked (resolution internals).
  final List<int> saved;

  @override
  Scope get scope => omniscient;
}

class FallbackApplied extends GameEvent {
  const FallbackApplied({
    required this.seat,
    required this.action,
    required this.reason,
  });

  final int seat;
  final String action;

  /// What went wrong ("TimeoutException…", "ParseFailure…") — saves
  /// spelunking server logs to tell timeout from parse failure.
  final String reason;

  @override
  Scope get scope => omniscient;
}

// ---- End ----

class GameEnded extends GameEvent {
  const GameEnded({required this.winner});

  /// Null = engine-backstop draw (maxDays reached), not a rules outcome.
  final Faction? winner;

  @override
  Scope get scope => public;
}
