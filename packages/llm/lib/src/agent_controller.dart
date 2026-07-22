import 'package:game_core/game_core.dart';

import 'agent_prompts.dart';
import 'chat_client.dart';
import 'decision_parser.dart';

/// LLM-backed seat. Prompts are built exclusively from
/// [DecisionContext.visibleEvents]; a parse failure after one corrective
/// retry throws, which lands on the engine's deterministic fallback
/// (GAME_DESIGN.md §4.4) and a FallbackApplied event.
class AgentController extends PlayerController {
  AgentController({
    required this.client,
    required this.model,
    required this.prompts,
    this.temperature = 0.7,
    this.speechMaxTokens = 2048,
    this.decisionMaxTokens = 2048,
    Duration timeout = const Duration(minutes: 3),
  }) : _timeout = timeout;

  final OpenAiCompatClient client;
  final String model;
  final AgentPromptBuilder prompts;
  final double temperature;
  final int speechMaxTokens;
  final int decisionMaxTokens;
  final Duration _timeout;

  @override
  Duration? get actionTimeout => _timeout;

  Future<String> _speech(DecisionContext ctx, String task) async {
    final result = await client.chat(
      [
        ChatMessage.system(prompts.system(ctx)),
        ChatMessage.user(
          '${prompts.situation(ctx)}\n\nYOUR TASK: $task\n'
          'Reply with the words you say out loud — no quotes, no stage '
          'directions, at most 120 words. Never state your own role unless '
          'you are deliberately claiming it.',
        ),
      ],
      model: model,
      temperature: temperature,
      maxTokens: speechMaxTokens,
    );
    final text = result.text.trim();
    if (text.isEmpty) throw ParseFailure('empty speech');
    final words = text.split(RegExp(r'\s+'));
    return words.length <= 140 ? text : words.take(140).join(' ');
  }

  Future<int?> _choice(
    DecisionContext ctx, {
    required String task,
    required String key,
    required List<int> legal,
    required bool allowNone,
  }) async {
    final system = ChatMessage.system(prompts.system(ctx));
    final schema = allowNone
        ? '{"reason": "<one line>", "$key": <seat number or null>}'
        : '{"reason": "<one line>", "$key": <seat number>}';
    final ask = ChatMessage.user(
      '${prompts.situation(ctx)}\n\nYOUR TASK: $task\n'
      'Legal targets: '
      '${legal.map((s) => '${prompts.names[s]} (seat $s)').join(', ')}.\n'
      'Reply with ONLY this JSON, nothing else: $schema',
    );
    var messages = [system, ask];
    for (var attempt = 0; attempt < 2; attempt++) {
      final result = await client.chat(
        messages,
        model: model,
        temperature: attempt == 0 ? temperature : 0.2,
        maxTokens: decisionMaxTokens,
      );
      try {
        final json = extractJsonObject(result.text);
        return parseSeatChoice(
          json,
          key,
          legal: legal,
          names: prompts.names,
          allowNone: allowNone,
        );
      } on ParseFailure catch (failure) {
        messages = [
          system,
          ask,
          ChatMessage.assistant(result.text),
          ChatMessage.user(
            'Your reply was rejected: $failure. '
            'Reply with ONLY the JSON object: $schema',
          ),
        ];
      }
    }
    throw ParseFailure('unparseable after retry');
  }

  @override
  Future<String> speak(DecisionContext ctx) => _speech(
    ctx,
    'Give your day-${ctx.day} discussion speech: share reads, cast or '
    'deflect suspicion, and position yourself for the vote.',
  );

  @override
  Future<String> defend(DecisionContext ctx) => _speech(
    ctx,
    'You are on trial. Give your defense speech to avoid elimination.',
  );

  @override
  Future<String> lastWords(DecisionContext ctx) => _speech(
    ctx,
    'You have been eliminated. Give brief last words to the town.',
  );

  @override
  Future<String> mafiaChat(DecisionContext ctx) => _speech(
    ctx,
    'Speak privately to your mafia team: coordinate strategy and '
    'propose tonight\'s plan in one or two sentences.',
  );

  @override
  Future<int?> nominate(DecisionContext ctx, List<int> candidates) => _choice(
    ctx,
    task: 'Nominate one player for elimination, or pass.',
    key: 'nominate',
    legal: candidates,
    allowNone: true,
  );

  @override
  Future<int?> vote(DecisionContext ctx, List<int> nominees) => _choice(
    ctx,
    task: 'Vote to eliminate one of the players on trial, or abstain.',
    key: 'vote',
    legal: nominees,
    allowNone: true,
  );

  @override
  Future<int?> mafiaKillVote(DecisionContext ctx, List<int> targets) => _choice(
    ctx,
    task: 'Vote for tonight\'s mafia kill target.',
    key: 'kill',
    legal: targets,
    allowNone: true,
  );

  @override
  Future<int> doctorProtect(DecisionContext ctx, List<int> targets) async =>
      (await _choice(
        ctx,
        task: 'Choose one player to protect tonight.',
        key: 'protect',
        legal: targets,
        allowNone: false,
      ))!;

  @override
  Future<int> sheriffInvestigate(
    DecisionContext ctx,
    List<int> targets,
  ) async => (await _choice(
    ctx,
    task: 'Choose one player to investigate tonight.',
    key: 'investigate',
    legal: targets,
    allowNone: false,
  ))!;

  @override
  Future<int?> assassinShoot(DecisionContext ctx, List<int> targets) => _choice(
    ctx,
    task: 'Fire your single bullet at a player tonight, or hold it.',
    key: 'shoot',
    legal: targets,
    allowNone: true,
  );
}
