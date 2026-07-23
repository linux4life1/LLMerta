import 'event.dart';
import 'role.dart';

/// Everything a controller may see when deciding: only its own seat, role,
/// day, and its visibility-filtered slice of the event log
/// (CLAUDE.md visibility invariant).
class DecisionContext {
  const DecisionContext({
    required this.seat,
    required this.role,
    required this.day,
    required this.visibleEvents,
    required this.livingSeats,
  });

  final int seat;
  final Role role;
  final int day;
  final List<GameEvent> visibleEvents;
  final List<int> livingSeats;
}

/// One async interface for every seat; the engine cannot tell a human,
/// an LLM agent, or a scripted bot apart (ARCHITECTURE.md §3).
abstract class PlayerController {
  /// Per-action timeout; null waits indefinitely (the human). On timeout
  /// the engine substitutes the GAME_DESIGN.md §4.4 fallback.
  Duration? get actionTimeout => null;

  Future<String> speak(DecisionContext ctx);

  Future<String> defend(DecisionContext ctx);

  Future<String> lastWords(DecisionContext ctx);

  /// Null = pass.
  /// A public act: the chosen target (null = pass) plus the spoken
  /// case for it — nominations are accusations, not silent ballots.
  Future<(int?, String)> nominate(DecisionContext ctx, List<int> candidates);

  /// Null = abstain.
  Future<int?> vote(DecisionContext ctx, List<int> nominees);

  Future<String> mafiaChat(DecisionContext ctx);

  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets);

  Future<int> doctorProtect(DecisionContext ctx, List<int> targets);

  Future<int> sheriffInvestigate(DecisionContext ctx, List<int> targets);

  /// Null = hold the bullet.
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets);
}
