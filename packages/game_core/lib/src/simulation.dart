import 'config.dart';
import 'controller.dart';
import 'engine.dart';
import 'scripted_controllers.dart';

/// Headless scripted game: every seat is a [RandomLegalController] with a
/// seed derived from [seed], so a run is fully reproducible.
Future<GameResult> runScriptedGame({
  required GameConfig config,
  required int seed,
  Map<int, PlayerController> overrides = const {},
}) {
  final controllers = {
    for (var s = 0; s < config.seats; s++)
      s: overrides[s] ?? RandomLegalController(seed * 1000 + s),
  };
  return GameEngine(
    config: config,
    controllers: controllers,
    rngSeed: seed,
  ).run();
}
