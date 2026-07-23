import 'package:game_core/game_core.dart';

/// Public activity a seat can be seen doing. Night/private acts are
/// deliberately absent — per-seat night indicators would leak roles.
enum TableActivity { speaking, nominating, voting }

/// Shared reading clock for the table: without voices nothing paces the
/// game, so a fast local model replaces each speech before anyone can
/// read it (field report, v0.1.2). Every public speech holds the floor
/// for roughly its reading time, and public prompts (votes, nominations
/// — the human's included) wait the floor out before they open.
class TablePacer {
  TablePacer({
    Future<void> Function(String text)? holdFor,
    Duration Function(String text)? readingTime,
  }) : _holdFor = holdFor,
       _readingTime = readingTime ?? defaultReadingTime;

  /// When set (voices on), a speech holds its turn until this future
  /// completes — the session ties it to the TTS queue finishing the
  /// line, so text persists exactly as long as it is being spoken.
  final Future<void> Function(String)? _holdFor;
  final Duration Function(String) _readingTime;
  Future<void> _floor = Future<void>.value();

  /// ~170 wpm plus a beat, clamped so one-liners linger and monologues
  /// don't stall the table.
  static Duration defaultReadingTime(String text) {
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final ms = 900 + words * 350;
    return Duration(milliseconds: ms.clamp(1500, 14000));
  }

  /// Lets the last speech finish being read/spoken (v0.1.4 field report:
  /// the vote prompt opened before the defenses could be read).
  Future<void> waitFloor() => _floor;

  /// Waits out the standing floor, then holds a new one for [text].
  Future<void> holdText(String text) async {
    await _floor;
    _floor = _holdFor?.call(text) ?? Future<void>.delayed(_readingTime(text));
  }

  Future<String> paced(Future<String> Function() action) async {
    final result = await action();
    await holdText(result);
    return result;
  }
}

/// Wraps a seat (AI or human): public speech acts share the table's
/// reading clock and announce themselves; public prompts wait the floor;
/// private acts pass straight through, invisible.
class PacedController extends PlayerController {
  PacedController(
    this.inner,
    this.pacer, {
    required this.seat,
    this.onActivity,
  });

  final PlayerController inner;
  final TablePacer pacer;
  final int seat;
  final void Function(int seat, TableActivity? activity)? onActivity;

  @override
  Duration? get actionTimeout => inner.actionTimeout;

  Future<String> _publicSpeech(Future<String> Function() action) async {
    onActivity?.call(seat, TableActivity.speaking);
    try {
      return await pacer.paced(action);
    } finally {
      onActivity?.call(seat, null);
    }
  }

  Future<int?> _publicChoice(
    TableActivity activity,
    Future<int?> Function() action,
  ) async {
    await pacer.waitFloor();
    onActivity?.call(seat, activity);
    try {
      return await action();
    } finally {
      onActivity?.call(seat, null);
    }
  }

  @override
  Future<String> speak(DecisionContext ctx) =>
      _publicSpeech(() => inner.speak(ctx));

  @override
  Future<String> defend(DecisionContext ctx) =>
      _publicSpeech(() => inner.defend(ctx));

  @override
  Future<String> lastWords(DecisionContext ctx) =>
      _publicSpeech(() => inner.lastWords(ctx));

  @override
  Future<(int?, String)> nominate(
    DecisionContext ctx,
    List<int> candidates,
  ) async {
    await pacer.waitFloor();
    onActivity?.call(seat, TableActivity.nominating);
    try {
      final result = await inner.nominate(ctx, candidates);
      // The statement is a speech: it holds the floor like one.
      if (result.$2.isNotEmpty) await pacer.holdText(result.$2);
      return result;
    } finally {
      onActivity?.call(seat, null);
    }
  }

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) =>
      _publicChoice(TableActivity.voting, () => inner.vote(ctx, nominees));

  @override
  Future<String> mafiaChat(DecisionContext ctx) => inner.mafiaChat(ctx);

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
