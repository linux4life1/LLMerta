import 'package:game_core/game_core.dart';

import 'agent_prompts.dart';
import 'decision_parser.dart';
import 'provider.dart';

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
    this.speechMaxTokens = 4096,
    this.decisionMaxTokens = 4096,
    this.useJsonSchema = true,
    this.twoStepReasoning = false,
    this.memoryFor,
    Duration timeout = const Duration(minutes: 6),
  }) : _timeout = timeout;

  final ChatProvider client;
  final String model;
  final AgentPromptBuilder prompts;
  final double temperature;
  final int speechMaxTokens;
  final int decisionMaxTokens;

  /// Seam for the memory package (which llm must not depend on): an extra
  /// remembered-context block appended to the situation, per task. The
  /// caller is bound by the same visibility invariant as prompts.
  final Future<String?> Function(DecisionContext ctx, String task)? memoryFor;

  /// Reveal-v2 seam: private decision rationales, captured for the
  /// post-game reasoning peek only — never shown during play.
  void Function(String task, String reason)? onReason;

  Future<String> _situation(DecisionContext ctx, String task) async {
    final base = prompts.situation(ctx);
    final block = await memoryFor?.call(ctx, task);
    return block == null || block.isEmpty ? base : '$base\n\n$block';
  }

  /// Restores full-depth deliberation for thinking models: an
  /// unconstrained private-analysis call runs first (native reasoning
  /// free to expand), and its conclusion feeds the constrained call.
  /// Costs one extra request per action (LLM_INTEGRATION.md §4).
  final bool twoStepReasoning;

  /// Grammar-constrained decisions via response_format json_schema
  /// (verified working on oMLX): output cannot be malformed and, with the
  /// legal targets baked in as an enum, cannot name an illegal seat. On a
  /// server that rejects response_format the controller drops to
  /// prompt-JSON permanently.
  final bool useJsonSchema;
  final Duration _timeout;
  var _schemaRejected = false;
  // Some servers silently ignore response_format instead of rejecting it
  // (gpt-oss via OpenRouter): repeated non-JSON output under schema mode
  // flips to the prompt-JSON path just like an explicit 400 would.
  var _schemaParseFailures = 0;

  void _noteSchemaParse({required bool ok}) {
    if (ok) {
      _schemaParseFailures = 0;
    } else if (++_schemaParseFailures >= 2) {
      _schemaRejected = true;
    }
  }

  @override
  Duration? get actionTimeout => _timeout;

  /// Speeches are also schema-constrained where supported: a truncated
  /// thinking block otherwise comes back as content and gets spoken
  /// verbatim — an agent reciting its own role card in public (observed
  /// live with GLM-4.7-Flash). The reason field gives deliberation a
  /// private outlet; only the speech field is ever spoken.
  Future<String> _think(DecisionContext ctx, String task) async {
    final result = await client.chat(
      [
        ChatMessage.system(prompts.system(ctx)),
        ChatMessage.user(
          '${await _situation(ctx, task)}\n\nUPCOMING TASK: $task\n'
          'Think privately first — this is never shown to other players. '
          'Analyze the board for your goals: suspicions, risks, and what '
          'you want to achieve. End with a short conclusion.',
        ),
      ],
      model: model,
      temperature: temperature,
      maxTokens: decisionMaxTokens,
    );
    final text = result.text.trim();
    return text.length <= 2000 ? text : text.substring(text.length - 2000);
  }

  Future<String> _speech(DecisionContext ctx, String task) async {
    final analysis = twoStepReasoning ? await _think(ctx, task) : null;
    final messages = [
      ChatMessage.system(prompts.system(ctx)),
      ChatMessage.user(
        '${await _situation(ctx, task)}\n\n'
        '${analysis == null || analysis.isEmpty ? '' : 'YOUR PRIVATE ANALYSIS (yours alone, moments ago):\n$analysis\n\n'}'
        'YOUR TASK: $task\n'
        'Reply with ONLY this JSON, nothing else: '
        '{"reason": "<one or two private sentences>", '
        '"speech": "<the words you say out loud>"}\n'
        'No stage directions, at most 120 words of speech. Your speech may '
        'draw ONLY on the public record — mentioning night conversations, '
        'private results, or your role is an instant giveaway unless you '
        'are deliberately claiming.',
      ),
    ];
    for (var attempt = 0; attempt < 2; attempt++) {
      final constrained = useJsonSchema && !_schemaRejected;
      ChatResult result;
      try {
        result = await client.chat(
          messages,
          model: model,
          temperature: attempt == 0 ? temperature : 0.4,
          maxTokens: speechMaxTokens,
          jsonSchema: constrained ? _speechSchema : null,
        );
      } on ChatClientException catch (e) {
        if (!constrained || !e.isRequestRejection) rethrow;
        _schemaRejected = true;
        result = await client.chat(
          messages,
          model: model,
          temperature: attempt == 0 ? temperature : 0.4,
          maxTokens: speechMaxTokens,
        );
      }
      var text = result.text.trim();
      try {
        if (constrained) {
          final json = extractJsonObject(text);
          final speech = json['speech'];
          if (speech is! String) throw ParseFailure('missing speech field');
          text = speech.trim();
          _noteSchemaParse(ok: true);
          if (json['reason'] case final String reason) {
            onReason?.call(task, reason);
          }
        }
        if (text.isEmpty) throw ParseFailure('empty speech');
        final words = text.split(RegExp(r'\s+'));
        return words.length <= 140 ? text : words.take(140).join(' ');
      } on ParseFailure {
        if (constrained) _noteSchemaParse(ok: false);
        if (attempt == 1) rethrow;
        messages.add(ChatMessage.assistant(result.text));
        messages.add(
          const ChatMessage.user(
            'Your reply was cut off or malformed. Keep "reason" to one short '
            'sentence and give your "speech" now.',
          ),
        );
      }
    }
    throw ParseFailure('unreachable');
  }

  static const _speechSchema = JsonSchemaSpec(
    name: 'speech',
    schema: {
      'type': 'object',
      'properties': {
        'reason': {'type': 'string', 'maxLength': 300},
        'speech': {'type': 'string'},
      },
      'required': ['reason', 'speech'],
      'additionalProperties': false,
    },
  );

  Future<int?> _choice(
    DecisionContext ctx, {
    required String task,
    required String key,
    required List<int> legal,
    required bool allowNone,
  }) async {
    final system = ChatMessage.system(prompts.system(ctx));
    final analysis = twoStepReasoning ? await _think(ctx, task) : null;
    final schema = allowNone
        ? '{"reason": "<one line>", "$key": <seat number or null>}'
        : '{"reason": "<one line>", "$key": <seat number>}';
    final ask = ChatMessage.user(
      '${await _situation(ctx, task)}\n\n'
      '${analysis == null || analysis.isEmpty ? '' : 'YOUR PRIVATE ANALYSIS (yours alone, moments ago):\n$analysis\n\n'}'
      'YOUR TASK: $task\n'
      'Legal targets: '
      '${legal.map((s) => '${prompts.names[s]} (seat $s)').join(', ')}.\n'
      'Reply with ONLY this JSON, nothing else: $schema',
    );
    var messages = [system, ask];
    for (var attempt = 0; attempt < 2; attempt++) {
      ChatResult result;
      final constrained = useJsonSchema && !_schemaRejected;
      try {
        result = await client.chat(
          messages,
          model: model,
          temperature: attempt == 0 ? temperature : 0.2,
          maxTokens: decisionMaxTokens,
          jsonSchema: constrained
              ? _jsonSchema(key, legal, allowNone: allowNone)
              : null,
        );
      } on ChatClientException catch (e) {
        if (!constrained || !e.isRequestRejection) rethrow;
        _schemaRejected = true;
        result = await client.chat(
          messages,
          model: model,
          temperature: attempt == 0 ? temperature : 0.2,
          maxTokens: decisionMaxTokens,
        );
      }
      try {
        final json = extractJsonObject(result.text);
        final choice = parseSeatChoice(
          json,
          key,
          legal: legal,
          names: prompts.names,
          allowNone: allowNone,
        );
        if (constrained) _noteSchemaParse(ok: true);
        if (json['reason'] case final String reason) {
          onReason?.call(task, reason);
        }
        return choice;
      } on ParseFailure catch (failure) {
        if (constrained) _noteSchemaParse(ok: false);
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

  static JsonSchemaSpec _jsonSchema(
    String key,
    List<int> legal, {
    required bool allowNone,
  }) => JsonSchemaSpec(
    name: key,
    schema: {
      'type': 'object',
      'properties': {
        'reason': {'type': 'string', 'maxLength': 300},
        key: allowNone
            ? {
                'anyOf': [
                  {'type': 'integer', 'enum': legal},
                  {'type': 'null'},
                ],
              }
            : {'type': 'integer', 'enum': legal},
      },
      'required': ['reason', key],
      'additionalProperties': false,
    },
  );

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
    task:
        'Vote for the nominee you want ELIMINATED, or abstain. '
        'A vote for yourself is a vote for your own elimination.',
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
