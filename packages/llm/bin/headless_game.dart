// All-LLM (or human + LLM) Mafia game against any supported provider.
//
//   dart run llm:headless_game
//     [--seats 8] [--seed 1] [--spoil] [--human <seat>]
//     [--provider openai|anthropic|gemini] [--base <url>] [--model <id>]
//     [--api-key-env <ENV_VAR>]
//     [--models local:<id>,or:<id>,...]   per-seat mix, round-robin:
//         local:X  = default local server (--base)   or:X = OpenRouter
//         (OpenRouter key from OPENROUTER_API_KEY)
//     [--difficulty casual|standard|cutthroat] [--persona-seed <n>]
//     [--grudges <file.json>]     cross-game persona memory (grudge mode)
//     [--decision-tokens 4096] [--speech-tokens 4096] [--timeout-mins 6]
//     [--no-schema] [--two-step]   two-step = private think call first
//     [--discussion-rounds 1|2]
//     [--cards <dir>]   use v2 character cards (.json/.png) as personas —
//         a Front Porch AI crossover; falls back to the library for
//         missing seats
//
// Public transcript by default; --spoil shows every event including mafia
// chat and night internals (don't combine with --human unless you enjoy
// spoilers).
import 'dart:io';
import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';

String argValue(List<String> args, String flag, String fallback) {
  final i = args.indexOf(flag);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
}

ChatProvider buildProvider(List<String> args) {
  final provider = argValue(args, '--provider', 'openai');
  final keyEnv = argValue(args, '--api-key-env', '');
  final apiKey = keyEnv.isEmpty ? null : Platform.environment[keyEnv];
  if (keyEnv.isNotEmpty && apiKey == null) {
    stderr.writeln('env var $keyEnv is not set');
    exit(1);
  }
  switch (provider) {
    case 'anthropic':
      return AnthropicClient(
        apiKey: apiKey ?? '',
        baseUrl: argValue(args, '--base', 'https://api.anthropic.com'),
      );
    case 'gemini':
      return GeminiClient(
        apiKey: apiKey ?? '',
        baseUrl: argValue(
          args,
          '--base',
          'https://generativelanguage.googleapis.com',
        ),
      );
    case 'openai':
      return OpenAiCompatClient(
        baseUrl: argValue(args, '--base', 'http://127.0.0.1:8000/v1'),
        apiKey: apiKey,
      );
    default:
      stderr.writeln('unknown provider "$provider"');
      exit(1);
  }
}

Future<void> main(List<String> args) async {
  final seats = int.parse(argValue(args, '--seats', '8'));
  final seed = int.parse(argValue(args, '--seed', '1'));
  final spoil = args.contains('--spoil');
  final humanSeat = int.tryParse(argValue(args, '--human', ''));
  final decisionTokens = int.parse(argValue(args, '--decision-tokens', '4096'));
  final speechTokens = int.parse(argValue(args, '--speech-tokens', '4096'));
  final timeoutMins = int.parse(argValue(args, '--timeout-mins', '6'));
  final useSchema = !args.contains('--no-schema');
  final twoStep = args.contains('--two-step');
  final difficulty = Difficulty.values.byName(
    argValue(args, '--difficulty', 'standard'),
  );
  final grudgePath = argValue(args, '--grudges', '');

  final client = buildProvider(args);
  final mixSpec = argValue(args, '--models', '');
  OpenAiCompatClient? openRouter;
  final seatBackends = <int, (ChatProvider, String)>{};
  if (mixSpec.isNotEmpty) {
    final entries = mixSpec.split(',');
    for (var s = 0; s < seats; s++) {
      final entry = entries[s % entries.length].trim();
      final sep = entry.indexOf(':');
      final kind = entry.substring(0, sep);
      final id = entry.substring(sep + 1);
      switch (kind) {
        case 'local':
          seatBackends[s] = (client, id);
        case 'or':
          openRouter ??= OpenAiCompatClient(
            baseUrl: 'https://openrouter.ai/api/v1',
            apiKey:
                Platform.environment['OPENROUTER_API_KEY'] ??
                (throw StateError('OPENROUTER_API_KEY not set')),
          );
          seatBackends[s] = (openRouter, id);
        default:
          stderr.writeln('bad --models entry "$entry"');
          exit(1);
      }
    }
  }
  var model = argValue(args, '--model', '');
  if (model.isEmpty && seatBackends.isEmpty) {
    final models = await client.listModels();
    if (models.isEmpty) {
      stderr.writeln('no models available from provider');
      exit(1);
    }
    model = models.first;
  }

  // Default keeps the first N library personas so grudge files stay
  // continuous; --persona-seed casts a different ensemble.
  final cardDir = argValue(args, '--cards', '');
  final cardCast = cardDir.isEmpty
      ? const <Persona>[]
      : personasFromCardDir(Directory(cardDir));
  final personaSeed = int.tryParse(argValue(args, '--persona-seed', ''));
  final libraryCast = personaSeed == null
      ? personaLibrary.toList()
      : (personaLibrary.toList()..shuffle(Random(personaSeed)));
  final cast = [
    ...cardCast.take(seats),
    ...libraryCast
        .where((p) => !cardCast.any((c) => c.name == p.name))
        .take(seats - cardCast.length.clamp(0, seats)),
  ];
  final personas = {for (var s = 0; s < seats; s++) s: cast[s]};
  final names = [for (var s = 0; s < seats; s++) personas[s]!.name];

  var grudges = GrudgeBook();
  final grudgeFile = grudgePath.isEmpty ? null : File(grudgePath);
  if (grudgeFile != null && grudgeFile.existsSync()) {
    grudges = GrudgeBook.fromJson(grudgeFile.readAsStringSync());
  }
  final memories = <int, String>{};
  for (var s = 0; s < seats; s++) {
    final block = grudges.promptBlockFor(names[s]);
    if (block != null) memories[s] = block;
  }

  final prompts = AgentPromptBuilder(
    names: names,
    personas: personas,
    difficulty: difficulty,
    pastMemories: memories,
  );
  stdout.writeln(
    '▶ $seats seats, seed $seed, '
    '${seatBackends.isEmpty ? 'model $model' : 'models ${[for (var s = 0; s < seats; s++) '$s=${seatBackends[s]?.$2 ?? model}'].join(' ')}'}'
    ', difficulty ${difficulty.name}'
    '${memories.isEmpty ? '' : ', ${memories.length} seats carry memories'}'
    '${humanSeat != null ? ', human at seat $humanSeat' : ''}\n',
  );

  final controllers = <int, PlayerController>{
    for (var s = 0; s < seats; s++)
      s: s == humanSeat
          ? StdinHumanController(names: names)
          : AgentController(
              client: seatBackends[s]?.$1 ?? client,
              model: seatBackends[s]?.$2 ?? model,
              prompts: prompts,
              decisionMaxTokens: decisionTokens,
              speechMaxTokens: speechTokens,
              useJsonSchema: useSchema,
              twoStepReasoning: twoStep,
              timeout: Duration(minutes: timeoutMins),
            ),
  };

  final sw = Stopwatch()..start();
  var humanIsMafia = false;
  final engine = GameEngine(
    config: GameConfig(
      seats: seats,
      discussionRounds: int.parse(argValue(args, '--discussion-rounds', '1')),
    ),
    controllers: controllers,
    rngSeed: seed,
    observer: (event) {
      if (event is RolesDealt && humanSeat != null) {
        humanIsMafia = event.roles[humanSeat]!.faction == Faction.mafia;
      }
      final mine =
          humanSeat != null &&
          event.scope.visibleTo(humanSeat, isMafia: humanIsMafia);
      if (!(spoil || event.scope is PublicScope || mine)) return;
      final line =
          renderEvent(event, names) ??
          (spoil && event is FallbackApplied
              ? '[engine] fallback for seat ${event.seat} '
                    '(${event.action}): ${event.reason}'
              : spoil
              ? '[engine] ${event.runtimeType}'
              : null);
      if (line != null) stdout.writeln(line);
    },
  );
  final result = await engine.run();
  sw.stop();

  if (grudgeFile != null) {
    grudges.recordGame(result.events, names);
    grudgeFile.writeAsStringSync(grudges.toJson());
    stdout.writeln('grudges updated: ${grudgeFile.path}');
  }

  final fallbacks = result.events.whereType<FallbackApplied>().length;
  final usage = client.usage;
  final orUsage = openRouter?.usage;
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
      '${orUsage == null ? '' : 'openrouter: ${orUsage.calls} calls, ${orUsage.promptTokens} in / ${orUsage.completionTokens} out, '}'
      'fallbacks: $fallbacks',
    );
  openRouter?.close();
  client.close();
}
