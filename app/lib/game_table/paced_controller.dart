import 'package:game_core/game_core.dart';

/// Shared reading clock for the table: without voices nothing paces the
/// game, so a fast local model replaces each speech before anyone can
/// read it (field report, v0.1.2). Every public speech holds the floor
/// for roughly its reading time before the next turn may finish.
class TablePacer {
  TablePacer({Duration Function(String text)? readingTime})
    : _readingTime = readingTime ?? defaultReadingTime;

  final Duration Function(String) _readingTime;
  DateTime _floorHeldUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// ~170 wpm plus a beat, clamped so one-liners linger and monologues
  /// don't stall the table.
  static Duration defaultReadingTime(String text) {
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final ms = 900 + words * 350;
    return Duration(milliseconds: ms.clamp(1500, 14000));
  }

  Future<String> paced(Future<String> Function() action) async {
    final result = await action();
    final wait = _floorHeldUntil.difference(DateTime.now());
    if (wait > Duration.zero) {
      await Future<void>.delayed(wait);
    }
    _floorHeldUntil = DateTime.now().add(_readingTime(result));
    return result;
  }
}

/// Wraps an AI seat: public speech acts share the table's reading clock;
/// private choices pass straight through.
class PacedController extends PlayerController {
  PacedController(this.inner, this.pacer);

  final PlayerController inner;
  final TablePacer pacer;

  @override
  Duration? get actionTimeout => inner.actionTimeout;

  @override
  Future<String> speak(DecisionContext ctx) =>
      pacer.paced(() => inner.speak(ctx));

  @override
  Future<String> defend(DecisionContext ctx) =>
      pacer.paced(() => inner.defend(ctx));

  @override
  Future<String> lastWords(DecisionContext ctx) =>
      pacer.paced(() => inner.lastWords(ctx));

  @override
  Future<String> mafiaChat(DecisionContext ctx) => inner.mafiaChat(ctx);

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) =>
      inner.nominate(ctx, candidates);

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) =>
      inner.vote(ctx, nominees);

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) =>
      inner.mafiaKillVote(ctx, targets);

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) =>
      inner.doctorProtect(ctx, targets);

  @override
  Future<int> sheriffInvestigate(DecisionContext ctx, List<int> targets) =>
      inner.sheriffInvestigate(ctx, targets);

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) =>
      inner.assassinShoot(ctx, targets);
}
