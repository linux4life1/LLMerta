// Headless all-LLM smoke game against an OpenAI-compatible server.
//
//   dart run llm:headless_game [--seats 8] [--seed 1]
//     [--base http://127.0.0.1:8000/v1] [--model <id>] [--spoil]
//
// Prints the public transcript by default (spoiler-safe); --spoil shows
// every event including mafia chat and night internals.
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';

const seatNames = [
  'Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta',
  'Hugo', 'Iris', 'Jonas', 'Katya', 'Lorenzo', 'Mira', 'Nikolai', //
];

String argValue(List<String> args, String flag, String fallback) {
  final i = args.indexOf(flag);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
}

Future<void> main(List<String> args) async {
  final seats = int.parse(argValue(args, '--seats', '8'));
  final seed = int.parse(argValue(args, '--seed', '1'));
  final base = argValue(args, '--base', 'http://127.0.0.1:8000/v1');
  final spoil = args.contains('--spoil');

  final client = OpenAiCompatClient(baseUrl: base);
  var model = argValue(args, '--model', '');
  if (model.isEmpty) {
    final models = await client.listModels();
    if (models.isEmpty) {
      stderr.writeln('No models served at $base');
      exit(1);
    }
    model = models.first;
  }
  stdout.writeln('▶ $seats seats, seed $seed, model $model @ $base\n');

  final names = seatNames.take(seats).toList();
  final prompts = AgentPromptBuilder(names: names);
  final controllers = {
    for (var s = 0; s < seats; s++)
      s: AgentController(client: client, model: model, prompts: prompts),
  };

  final sw = Stopwatch()..start();
  final engine = GameEngine(
    config: GameConfig(seats: seats),
    controllers: controllers,
    rngSeed: seed,
    observer: (event) {
      final visible = spoil || event.scope is PublicScope;
      if (!visible) return;
      final line =
          renderEvent(event, names) ??
          (spoil ? '[engine] ${event.runtimeType}' : null);
      if (line != null) stdout.writeln(line);
    },
  );
  final result = await engine.run();
  sw.stop();

  final fallbacks = result.events.whereType<FallbackApplied>().length;
  final usage = client.usage;
  stdout
    ..writeln('\n--- smoke result ---')
    ..writeln(
      'winner: ${result.winner?.name ?? 'draw'} '
      'after ${result.days} day(s) in ${sw.elapsed}',
    )
    ..writeln(
      'events: ${result.events.length}, '
      'llm calls: ${usage.calls}, '
      'tokens: ${usage.promptTokens} in / ${usage.completionTokens} out, '
      'fallbacks: $fallbacks',
    );
  client.close();
}
