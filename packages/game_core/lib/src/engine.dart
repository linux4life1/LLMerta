import 'dart:math';

import 'config.dart';
import 'controller.dart';
import 'day_vote.dart';
import 'event.dart';
import 'mafia_vote.dart';
import 'night_resolution.dart';
import 'role.dart';
import 'role_distribution.dart';
import 'state.dart';
import 'win_check.dart';

class GameResult {
  const GameResult({
    required this.winner,
    required this.days,
    required this.events,
  });

  /// Null = engine-backstop draw (config.maxDays reached).
  final Faction? winner;
  final int days;
  final List<GameEvent> events;
}

class GameEngine {
  GameEngine({
    required this.config,
    required this.controllers,
    required int rngSeed,
    this.observer,
  }) : assert(controllers.length == config.seats),
       _rng = Random(rngSeed);

  final GameConfig config;
  final Map<int, PlayerController> controllers;

  /// Called for every emitted event; the caller is responsible for
  /// visibility filtering before showing anything to a player.
  final void Function(GameEvent)? observer;
  final Random _rng;
  final List<GameEvent> _events = [];
  final List<int> _pendingDeaths = [];
  GameState _state = const GameState.initial();

  List<GameEvent> get events => List.unmodifiable(_events);

  GameState get state => _state;

  void _emit(GameEvent e) {
    _events.add(e);
    _state = _state.apply(e);
    observer?.call(e);
  }

  Future<GameResult> run() async {
    _setup();
    if (config.night0) await _night(0);
    for (var day = 1; !_state.over; day++) {
      if (day > config.maxDays) {
        _emit(const GameEnded(winner: null));
        break;
      }
      _emit(DayBegan(day));
      _dawn();
      if (_state.over) break;
      await _discussion();
      await _trialAndVote();
      if (_state.over) break;
      await _night(day);
    }
    return GameResult(winner: _state.winner, days: _state.day, events: events);
  }

  // ---- Setup ----

  void _setup() {
    _emit(GameStarted(seats: config.seats));
    final roles = rolesForConfig(config).toList()..shuffle(_rng);
    final bySeat = {for (var s = 0; s < roles.length; s++) s: roles[s]};
    _emit(RolesDealt(bySeat));
    for (final MapEntry(:key, :value) in bySeat.entries) {
      _emit(RoleReceived(seat: key, role: value));
    }
    final team = {
      for (final MapEntry(:key, :value) in bySeat.entries)
        if (value.faction == Faction.mafia) key,
    };
    if (team.isNotEmpty) _emit(MafiaTeamRevealed(team));
  }

  // ---- Day ----

  void _dawn() {
    final deaths = List<int>.from(_pendingDeaths);
    _pendingDeaths.clear();
    _emit(
      DawnAnnounced(
        deaths: deaths,
        revealedRoles: {
          if (config.revealRolesOnDeath)
            for (final s in deaths) s: _state.roles[s]!,
        },
      ),
    );
    _checkWin();
  }

  Future<void> _discussion() async {
    for (var round = 0; round < config.discussionRounds; round++) {
      for (final seat in _rotatedLiving()) {
        final text = await _ask(
          seat,
          'speak',
          (c) => c.speak(_ctx(seat)),
          () => '',
        );
        _emit(SpeechGiven(seat: seat, text: text));
      }
    }
  }

  Future<void> _trialAndVote() async {
    final nominations = <(int, int?)>[];
    for (final seat in _rotatedLiving()) {
      final candidates = _living()..remove(seat);
      final (target, statement) = await _ask(
        seat,
        'nominate',
        (c) => c.nominate(_ctx(seat), candidates),
        () => (null, ''),
      );
      final legal = target != null && candidates.contains(target);
      nominations.add((seat, legal ? target : null));
      _emit(
        NominationCast(
          by: seat,
          target: legal ? target : null,
          statement: statement,
        ),
      );
    }
    final slate = trialSlate(nominations);
    if (slate.isEmpty) return;
    _emit(TrialStarted(slate));
    for (final seat in slate) {
      final text = await _ask(
        seat,
        'defend',
        (c) => c.defend(_ctx(seat)),
        () => '',
      );
      _emit(DefenseGiven(seat: seat, text: text));
    }
    var eliminated = await _voteRound(slate);
    if (eliminated == null && config.tieRule == TieRule.runoff) {
      // Single runoff among the tied; a second tie eliminates nobody.
      final tied = _lastRunoffSlate;
      if (tied.isNotEmpty) eliminated = await _voteRound(tied);
    }
    _emit(
      Verdict(
        eliminated: eliminated,
        revealedRole: eliminated != null && config.revealRolesOnDeath
            ? _state.roles[eliminated]
            : null,
      ),
    );
    if (eliminated != null) {
      final text = await _ask(
        eliminated,
        'lastWords',
        (c) => c.lastWords(_ctx(eliminated!)),
        () => '',
      );
      _emit(LastWordsGiven(seat: eliminated, text: text));
      _checkWin();
    }
  }

  List<int> _lastRunoffSlate = const [];

  Future<int?> _voteRound(List<int> slate) async {
    final voters = _living()
      ..removeWhere((s) => !config.nomineesVote && slate.contains(s));
    final votes = <int, int?>{};
    await Future.wait([
      for (final seat in voters)
        _ask(
          seat,
          'vote',
          // A nominee never sees themself as an option: self-votes are not
          // proper play, so they are structurally impossible.
          (c) => c.vote(_ctx(seat), [...slate]..remove(seat)),
          () => null,
        ).then(
          (v) => votes[seat] = v != null && v != seat && slate.contains(v)
              ? v
              : null,
        ),
    ]);
    final ordered = {for (final s in voters) s: votes[s]};
    _emit(VotesRevealed(ordered));
    final result = verdict(ordered, config.tieRule, _rng);
    _lastRunoffSlate = result.runoff;
    return result.eliminated;
  }

  // ---- Night ----

  Future<void> _night(int day) async {
    _emit(NightBegan(day));
    final mafia = _livingMafia();
    for (final seat in mafia) {
      final text = await _ask(
        seat,
        'mafiaChat',
        (c) => c.mafiaChat(_ctx(seat)),
        () => '',
      );
      _emit(MafiaChatSaid(seat: seat, text: text));
    }
    int? mafiaTarget;
    if (day > 0 && mafia.isNotEmpty) {
      final targets = _living()
        ..removeWhere((s) => _state.roles[s]!.faction == Faction.mafia);
      final votes = <int, int?>{};
      await Future.wait([
        for (final seat in mafia)
          _ask(
            seat,
            'mafiaKillVote',
            (c) => c.mafiaKillVote(_ctx(seat), targets),
            () =>
                targets.isEmpty ? null : targets[_rng.nextInt(targets.length)],
          ).then(
            (v) => votes[seat] = v != null && targets.contains(v) ? v : null,
          ),
      ]);
      for (final seat in mafia) {
        _emit(MafiaKillVoteCast(by: seat, target: votes[seat]));
      }
      mafiaTarget = mafiaKillTarget(
        votes: votes,
        livingMafiaInSeatOrder: mafia,
      );
      _emit(MafiaKillChosen(mafiaTarget));
    }

    final results = await Future.wait([
      _doctorAction(day),
      _sheriffAction(day),
      _assassinAction(day),
    ]);
    final protectedSeat = results[0];
    final assassinTarget = results[2];

    if (day > 0) {
      final resolution = resolveNight(
        mafiaTarget: mafiaTarget,
        assassinTarget: assassinTarget,
        protectedSeat: protectedSeat,
      );
      _emit(NightResolved(killed: resolution.killed, saved: resolution.saved));
      _pendingDeaths.addAll(resolution.killed);
    }
  }

  Future<int?> _doctorAction(int day) async {
    if (day == 0) return null;
    final doctor = _livingSeatWith(Role.doctor);
    if (doctor == null) return null;
    final targets = _living();
    if (!config.doctorMayProtectSelf) targets.remove(doctor);
    if (config.doctorNoRepeatTarget) targets.remove(_state.doctorLastTarget);
    if (targets.isEmpty) return null;
    final target = await _ask(
      doctor,
      'doctorProtect',
      (c) => c.doctorProtect(_ctx(doctor), targets),
      () => targets.contains(doctor)
          ? doctor
          : targets[_rng.nextInt(targets.length)],
    );
    final legal = targets.contains(target) ? target : targets.first;
    _emit(DoctorProtected(doctor: doctor, target: legal));
    return legal;
  }

  Future<int?> _sheriffAction(int day) async {
    if (day == 0 && !config.night0SheriffPeek) return null;
    final sheriff = _livingSeatWith(Role.sheriff);
    if (sheriff == null) return null;
    final targets = _living()..remove(sheriff);
    if (targets.isEmpty) return null;
    final unvisited = targets
        .where((s) => !_state.sheriffVisited.contains(s))
        .toList();
    final target = await _ask(
      sheriff,
      'sheriffInvestigate',
      (c) => c.sheriffInvestigate(_ctx(sheriff), targets),
      () =>
          (unvisited.isEmpty ? targets : unvisited)[_rng.nextInt(
            (unvisited.isEmpty ? targets : unvisited).length,
          )],
    );
    final legal = targets.contains(target) ? target : targets.first;
    _emit(
      SheriffInvestigated(
        sheriff: sheriff,
        target: legal,
        foundMafia: _state.roles[legal]!.faction == Faction.mafia,
      ),
    );
    return legal;
  }

  Future<int?> _assassinAction(int day) async {
    if (day == 0) return null;
    final assassin = _livingSeatWith(Role.assassin);
    if (assassin == null || _state.assassinBulletUsed) return null;
    final targets = _living()..remove(assassin);
    if (targets.isEmpty) return null;
    final target = await _ask(
      assassin,
      'assassinShoot',
      (c) => c.assassinShoot(_ctx(assassin), targets),
      () => null,
    );
    final legal = target != null && targets.contains(target) ? target : null;
    _emit(AssassinDecided(assassin: assassin, target: legal));
    return legal;
  }

  // ---- Helpers ----

  void _checkWin() {
    final w = winner(_state);
    if (w != null) _emit(GameEnded(winner: w));
  }

  List<int> _living() => _state.alive.toList()..sort();

  List<int> _livingMafia() => _livingMafiaOf(_state);

  static List<int> _livingMafiaOf(GameState s) =>
      s.livingMafia.toList()..sort();

  int? _livingSeatWith(Role role) {
    final seat = _state.seatOf(role);
    return seat != null && _state.alive.contains(seat) ? seat : null;
  }

  /// Discussion order rotates daily so the same seat never anchors every
  /// day (GAME_DESIGN.md §8.4).
  List<int> _rotatedLiving() {
    final living = _living();
    final offset = (_state.day - 1) % living.length;
    return [...living.sublist(offset), ...living.sublist(0, offset)];
  }

  DecisionContext _ctx(int seat) {
    final role = _state.roles[seat]!;
    return DecisionContext(
      seat: seat,
      role: role,
      day: _state.day,
      visibleEvents: _events.visibleTo(
        seat,
        isMafia: role.faction == Faction.mafia,
      ),
      livingSeats: _living(),
    );
  }

  /// Wraps every controller call: on timeout or any thrown error the
  /// GAME_DESIGN.md §4.4 fallback substitutes so no seat can stall a game.
  Future<T> _ask<T>(
    int seat,
    String action,
    Future<T> Function(PlayerController) call,
    T Function() fallback,
  ) async {
    final controller = controllers[seat]!;
    final timeout = controller.actionTimeout;
    try {
      final future = call(controller);
      return await (timeout == null ? future : future.timeout(timeout));
    } on Object catch (error) {
      final reason = error.toString();
      _emit(
        FallbackApplied(
          seat: seat,
          action: action,
          reason: reason.length > 200 ? reason.substring(0, 200) : reason,
        ),
      );
      return fallback();
    }
  }
}
