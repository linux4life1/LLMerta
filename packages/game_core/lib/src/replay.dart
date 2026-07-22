import 'dart:collection';

import 'controller.dart';
import 'event.dart';

/// Resume-by-replay (ARCHITECTURE.md §3): re-run the engine with the same
/// config and seed; recorded decisions answer instantly until the log runs
/// dry, then the live controller takes over. Engine randomness is seeded
/// and every nondeterministic input is a recorded event, so the replayed
/// prefix reproduces the saved game exactly.
class ReplayLog {
  ReplayLog(Iterable<GameEvent> recorded) {
    for (final event in recorded) {
      switch (event) {
        case SpeechGiven(:final seat, :final text):
          _push(_speeches, seat, text);
        case DefenseGiven(:final seat, :final text):
          _push(_defenses, seat, text);
        case LastWordsGiven(:final seat, :final text):
          _push(_lastWords, seat, text);
        case MafiaChatSaid(:final seat, :final text):
          _push(_mafiaChats, seat, text);
        case NominationCast(:final by, :final target):
          _push(_nominations, by, target);
        case VotesRevealed(:final votes):
          for (final MapEntry(:key, :value) in votes.entries) {
            _push(_votes, key, value);
          }
        case MafiaKillVoteCast(:final by, :final target):
          _push(_mafiaKillVotes, by, target);
        case DoctorProtected(:final doctor, :final target):
          _push(_protections, doctor, target);
        case SheriffInvestigated(:final sheriff, :final target):
          _push(_investigations, sheriff, target);
        case AssassinDecided(:final assassin, :final target):
          _push(_shots, assassin, target);
        default:
          break;
      }
    }
  }

  final _speeches = <int, Queue<Object?>>{};
  final _defenses = <int, Queue<Object?>>{};
  final _lastWords = <int, Queue<Object?>>{};
  final _mafiaChats = <int, Queue<Object?>>{};
  final _nominations = <int, Queue<Object?>>{};
  final _votes = <int, Queue<Object?>>{};
  final _mafiaKillVotes = <int, Queue<Object?>>{};
  final _protections = <int, Queue<Object?>>{};
  final _investigations = <int, Queue<Object?>>{};
  final _shots = <int, Queue<Object?>>{};

  static void _push(Map<int, Queue<Object?>> map, int seat, Object? value) =>
      map.putIfAbsent(seat, Queue.new).add(value);

  /// (replayed, value) — `replayed: false` means the log is dry for this
  /// seat/action and the live controller must decide.
  (bool, Object?) _pop(Map<int, Queue<Object?>> map, int seat) {
    final queue = map[seat];
    if (queue == null || queue.isEmpty) return (false, null);
    return (true, queue.removeFirst());
  }
}

class ReplayController extends PlayerController {
  ReplayController({
    required this.seat,
    required this.live,
    required ReplayLog log,
  }) : _log = log;

  final int seat;
  final PlayerController live;
  final ReplayLog _log;

  // Replayed legs answer instantly, so the live timeout is always safe.
  @override
  Duration? get actionTimeout => live.actionTimeout;

  Future<String> _text(
    Map<int, Queue<Object?>> map,
    Future<String> Function() fallback,
  ) {
    final (replayed, value) = _log._pop(map, seat);
    return replayed ? Future.value(value! as String) : fallback();
  }

  Future<int?> _choice(
    Map<int, Queue<Object?>> map,
    Future<int?> Function() fallback,
  ) {
    final (replayed, value) = _log._pop(map, seat);
    return replayed ? Future.value(value as int?) : fallback();
  }

  @override
  Future<String> speak(DecisionContext ctx) =>
      _text(_log._speeches, () => live.speak(ctx));

  @override
  Future<String> defend(DecisionContext ctx) =>
      _text(_log._defenses, () => live.defend(ctx));

  @override
  Future<String> lastWords(DecisionContext ctx) =>
      _text(_log._lastWords, () => live.lastWords(ctx));

  @override
  Future<String> mafiaChat(DecisionContext ctx) =>
      _text(_log._mafiaChats, () => live.mafiaChat(ctx));

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) =>
      _choice(_log._nominations, () => live.nominate(ctx, candidates));

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) =>
      _choice(_log._votes, () => live.vote(ctx, nominees));

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) =>
      _choice(_log._mafiaKillVotes, () => live.mafiaKillVote(ctx, targets));

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) async =>
      (await _choice(
        _log._protections,
        () async => live.doctorProtect(ctx, targets),
      ))!;

  @override
  Future<int> sheriffInvestigate(
    DecisionContext ctx,
    List<int> targets,
  ) async => (await _choice(
    _log._investigations,
    () async => live.sheriffInvestigate(ctx, targets),
  ))!;

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) =>
      _choice(_log._shots, () => live.assassinShoot(ctx, targets));
}

/// Wraps every live controller with the shared recorded log.
Map<int, PlayerController> replayControllers({
  required List<GameEvent> recorded,
  required Map<int, PlayerController> live,
}) {
  final log = ReplayLog(recorded);
  return {
    for (final MapEntry(:key, :value) in live.entries)
      key: ReplayController(seat: key, live: value, log: log),
  };
}
