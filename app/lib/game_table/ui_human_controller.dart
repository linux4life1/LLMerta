import 'dart:async';

import 'package:game_core/game_core.dart';

enum HumanActionKind {
  speak,
  defend,
  lastWords,
  nominate,
  vote,
  mafiaChat,
  mafiaKillVote,
  doctorProtect,
  sheriffInvestigate,
  assassinShoot,
}

class HumanRequest {
  HumanRequest({
    required this.kind,
    required this.ctx,
    this.targets = const [],
  });

  final HumanActionKind kind;
  final DecisionContext ctx;
  final List<int> targets;
  final _completer = Completer<Object?>();

  Future<Object?> get result => _completer.future;

  bool get isSubmitted => _completer.isCompleted;

  bool get wantsText => switch (kind) {
    HumanActionKind.speak ||
    HumanActionKind.defend ||
    HumanActionKind.lastWords ||
    HumanActionKind.mafiaChat => true,
    _ => false,
  };

  /// Doctor and Sheriff must act; everyone else may pass/hold/abstain.
  bool get mustChoose =>
      kind == HumanActionKind.doctorProtect ||
      kind == HumanActionKind.sheriffInvestigate;

  void submitText(String text) => _completer.complete(text);

  void submitChoice(int? seat) {
    assert(!mustChoose || seat != null);
    _completer.complete(seat);
  }
}

/// The engine-facing human seat: every request parks here until the dock
/// completes it. No timeout — the game waits (GAME_DESIGN.md §5).
class UiHumanController extends PlayerController {
  final _requests = StreamController<HumanRequest?>.broadcast();

  Stream<HumanRequest?> get requests => _requests.stream;

  HumanRequest? current;

  void dispose() => _requests.close();

  Future<T> _ask<T>(
    HumanActionKind kind,
    DecisionContext ctx, [
    List<int> targets = const [],
  ]) async {
    final request = HumanRequest(kind: kind, ctx: ctx, targets: targets);
    current = request;
    _requests.add(request);
    final result = await request._completer.future;
    current = null;
    _requests.add(null);
    return result as T;
  }

  @override
  Future<String> speak(DecisionContext ctx) => _ask(HumanActionKind.speak, ctx);

  @override
  Future<String> defend(DecisionContext ctx) =>
      _ask(HumanActionKind.defend, ctx);

  @override
  Future<String> lastWords(DecisionContext ctx) =>
      _ask(HumanActionKind.lastWords, ctx);

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) =>
      _ask(HumanActionKind.nominate, ctx, candidates);

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) =>
      _ask(HumanActionKind.vote, ctx, nominees);

  @override
  Future<String> mafiaChat(DecisionContext ctx) =>
      _ask(HumanActionKind.mafiaChat, ctx);

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) =>
      _ask(HumanActionKind.mafiaKillVote, ctx, targets);

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) =>
      _ask(HumanActionKind.doctorProtect, ctx, targets);

  @override
  Future<int> sheriffInvestigate(DecisionContext ctx, List<int> targets) =>
      _ask(HumanActionKind.sheriffInvestigate, ctx, targets);

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) =>
      _ask(HumanActionKind.assassinShoot, ctx, targets);
}
