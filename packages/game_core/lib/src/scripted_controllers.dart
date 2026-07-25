import 'dart:async';
import 'dart:math';

import 'controller.dart';

/// Random-but-legal bot for headless simulation (ROADMAP M1). Every choice
/// draws from its own seeded RNG so simulations are reproducible.
class RandomLegalController extends PlayerController {
  RandomLegalController(int seed) : _rng = Random(seed);

  final Random _rng;

  T _pick<T>(List<T> options) => options[_rng.nextInt(options.length)];

  int? _maybePick(List<int> options, {double passChance = 0.3}) {
    if (options.isEmpty || _rng.nextDouble() < passChance) return null;
    return _pick(options);
  }

  @override
  Future<String> speak(DecisionContext ctx) async =>
      'Seat ${ctx.seat} has suspicions.';

  @override
  Future<String> defend(DecisionContext ctx) async =>
      'Seat ${ctx.seat} pleads innocence.';

  @override
  Future<String> lastWords(DecisionContext ctx) async =>
      'Seat ${ctx.seat} says farewell.';

  @override
  Future<(int?, String)> argue(
    DecisionContext ctx,
    List<int> candidates,
  ) async {
    final target = _maybePick(candidates, passChance: 0.55);
    return (
      target,
      target == null ? '' : 'Seat ${ctx.seat} challenges seat $target.',
    );
  }

  @override
  Future<String> rebut(
    DecisionContext ctx, {
    required int challenger,
    required String challenge,
  }) async => 'Seat ${ctx.seat} pushes back on seat $challenger.';

  @override
  Future<(int?, String)> nominate(
    DecisionContext ctx,
    List<int> candidates,
  ) async {
    final target = _maybePick(candidates);
    return (
      target,
      target == null ? '' : 'Seat ${ctx.seat} states their case.',
    );
  }

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) async =>
      _maybePick(nominees, passChance: 0.15);

  @override
  Future<String> mafiaChat(DecisionContext ctx) async =>
      'Seat ${ctx.seat} whispers.';

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) async =>
      _maybePick(targets, passChance: 0.05);

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) async =>
      _pick(targets);

  @override
  Future<int> sheriffInvestigate(
    DecisionContext ctx,
    List<int> targets,
  ) async => _pick(targets);

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) async =>
      _maybePick(targets, passChance: 0.7);
}

/// Never answers — exercises the engine's timeout fallbacks in tests.
class UnresponsiveController extends PlayerController {
  @override
  Duration? get actionTimeout => Duration.zero;

  Future<T> _hang<T>() => Completer<T>().future;

  @override
  Future<String> speak(DecisionContext ctx) => _hang();

  @override
  Future<String> defend(DecisionContext ctx) => _hang();

  @override
  Future<String> lastWords(DecisionContext ctx) => _hang();

  @override
  Future<(int?, String)> argue(DecisionContext ctx, List<int> candidates) =>
      _hang();

  @override
  Future<String> rebut(
    DecisionContext ctx, {
    required int challenger,
    required String challenge,
  }) => _hang();

  @override
  Future<(int?, String)> nominate(DecisionContext ctx, List<int> candidates) =>
      _hang();

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) => _hang();

  @override
  Future<String> mafiaChat(DecisionContext ctx) => _hang();

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) => _hang();

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) => _hang();

  @override
  Future<int> sheriffInvestigate(DecisionContext ctx, List<int> targets) =>
      _hang();

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) => _hang();
}
