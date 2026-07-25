import 'package:game_core/game_core.dart';

import 'agent_prompts.dart';
import 'agent_seat_speech.dart';
import 'decision_parser.dart';
import 'provider.dart';
import 'visible_facts.dart';

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

  // Package-private seams for agent_seat_speech.dart (keeps this file slim).
  bool get schemaRejected => _schemaRejected;
  void markSchemaRejected() => _schemaRejected = true;
  void noteSchemaParse({required bool ok}) => _noteSchemaParse(ok: ok);
  Future<String> situationPublic(DecisionContext ctx, String task) =>
      _situation(ctx, task);
  Future<String> thinkPublic(DecisionContext ctx, String task) =>
      _think(ctx, task);

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
        'No stage directions, at most 120 words of speech. First person '
        'only. Do not rephrase the previous speaker or recycle their '
        'catchphrases — add something new. Your speech may draw ONLY on '
        'the public record (and a deliberate role claim if you choose) — '
        'mentioning night conversations or unclaimed private results is '
        'an instant giveaway.',
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
        // The prompt asks for the {reason, speech} envelope in BOTH modes;
        // unconstrained models often comply, sometimes fenced. Speaking the
        // raw envelope once leaked a private reason into the transcript
        // (BALANCE.md, mixed game) — parse whenever the reply looks like
        // JSON and fall back to prose only when it clearly isn't.
        final looksLikeEnvelope =
            constrained ||
            text.startsWith('{') ||
            text.startsWith('```') ||
            text.contains('"speech"');
        if (looksLikeEnvelope) {
          final json = extractJsonObject(text);
          final speech = json['speech'];
          if (speech is! String) throw ParseFailure('missing speech field');
          text = speech.trim();
          if (constrained) _noteSchemaParse(ok: true);
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

  /// Presentation order for a target list. Models over-pick the first
  /// option they read; with the human parked in seat 1 that bias killed
  /// them night after night (field report). Rotating by chooser and day
  /// scatters "first" across seats while staying replay-deterministic.
  static List<int> presentationOrder(List<int> legal, DecisionContext ctx) {
    if (legal.length < 2) return legal;
    final shift = (ctx.day + ctx.seat) % legal.length;
    return [...legal.sublist(shift), ...legal.sublist(0, shift)];
  }

  Future<int?> _choice(
    DecisionContext ctx, {
    required String task,
    required String key,
    required List<int> legal,
    required bool allowNone,
  }) async {
    final system = ChatMessage.system(prompts.system(ctx));
    final analysis = twoStepReasoning ? await _think(ctx, task) : null;
    final ordered = presentationOrder(legal, ctx);
    final schema = allowNone
        ? '{"reason": "<one line>", "$key": <seat number or null>}'
        : '{"reason": "<one line>", "$key": <seat number>}';
    final ask = ChatMessage.user(
      '${await _situation(ctx, task)}\n\n'
      '${analysis == null || analysis.isEmpty ? '' : 'YOUR PRIVATE ANALYSIS (yours alone, moments ago):\n$analysis\n\n'}'
      'YOUR TASK: $task\n'
      'Legal targets: '
      '${ordered.map((s) => '${prompts.names[s]} (seat ${s + 1})').join(', ')}.\n'
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
              ? _jsonSchema(key, ordered, allowNone: allowNone)
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

  // Enums carry the public 1-based numbers the prompt text uses; the
  // parser maps them back to engine indices.
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
                  {
                    'type': 'integer',
                    'enum': [for (final s in legal) s + 1],
                  },
                  {'type': 'null'},
                ],
              }
            : {
                'type': 'integer',
                'enum': [for (final s in legal) s + 1],
              },
      },
      'required': ['reason', key],
      'additionalProperties': false,
    },
  );

  @override
  Future<String> speak(DecisionContext ctx) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    final buf = StringBuffer(
      'Give your day-${ctx.day} discussion speech in first person. Share '
      'reads, cast or deflect suspicion, and position for the vote. Do not '
      'restate ALREADY SAID TODAY. Do not invent private talks that are '
      'not in the public record.',
    );
    if (facts.ownRole == Role.mafioso) {
      buf.write(
        ' You are mafia: consider a deliberate fakeclaim or false dig if '
        'it steers the hang — e.g. "I am Sheriff and X is mafia" (false), '
        'or claim Doctor after a quiet night. Commit to the lie if you start '
        'it. Never out teammates.',
      );
    } else if (facts.ownRole == Role.sheriff &&
        facts.liveMafiaHits.isNotEmpty) {
      final named = facts.liveMafiaHits
          .map((s) => '${prompts.names[s]} (seat ${s + 1})')
          .join(', ');
      buf.write(
        ' You hold a live MAFIA investigation on $named — open by claiming '
        'Sheriff and naming them, then push the table to vote that way.',
      );
    } else if (facts.ownRole == Role.sheriff ||
        facts.ownRole == Role.doctor ||
        facts.ownRole == Role.assassin) {
      buf.write(
        ' If the table is mislynching or bleeding and a deliberate claim '
        'would save town, claim your role with a concrete reason.',
      );
    } else {
      buf.write(
        ' Demand claims from power roles when the board stalls; call out '
        'people who dodge direct questions.',
      );
    }
    return _speech(ctx, buf.toString());
  }

  @override
  Future<String> defend(DecisionContext ctx) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    if (facts.ownRole == Role.mafioso) {
      return _speech(
        ctx,
        'You are on trial and mafia. Defend hard: fakeclaim if needed, '
        'attack the accusers\' logic, offer a false town story. Never '
        'confess. At most 80 words.',
      );
    }
    return _speech(
      ctx,
      'You are on trial. Give your defense speech to avoid elimination. '
      'Answer the charges directly; claim a power role only if true and '
      'useful.',
    );
  }

  @override
  Future<String> lastWords(DecisionContext ctx) => _speech(
    ctx,
    'You have been eliminated. Give brief last words to the town. '
    'Mafia: do not confess cleanly — leave a false tip if useful. '
    'Town: name your best remaining read.',
  );

  @override
  Future<String> mafiaChat(DecisionContext ctx) => _speech(
    ctx,
    'Speak privately to your mafia team. First sentence: name a living '
    'non-mafia kill target (seat + name) and why. Second sentence: day '
    'plan — who to frame, whether someone should fakeclaim Sheriff or '
    'Doctor, who buses if needed. Concrete plan only.',
  );

  @override
  Future<(int?, String)> argue(DecisionContext ctx, List<int> candidates) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    final task = facts.ownRole == Role.mafioso
        ? 'Crossfire: challenge one living player or pass. This is a real '
              'table argument — speak naturally (up to ~120 words), press '
              'them, frame a townsfolk, force a claim, or dig into someone '
              'who threatens you. First person. Or pass.'
        : 'Crossfire: challenge one living player who accused you, dodged, '
              'or looks wrong. Speak like a real argument (up to ~120 words) '
              '— demand a claim or answer, push back hard. First person. '
              'Or pass if you have nothing new.';
    return seatSpeechAct(
      this,
      ctx: ctx,
      candidates: candidates,
      task: task,
      choiceKey: 'argue',
      speechKey: 'speech',
      speechWordCap: 140,
    );
  }

  @override
  Future<String> rebut(
    DecisionContext ctx, {
    required int challenger,
    required String challenge,
  }) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    final who = prompts.names[challenger];
    final task = facts.ownRole == Role.mafioso
        ? '$who just challenged you: "$challenge" — give a full first-person '
              'rebuttal (up to ~120 words). Defend your story or double down '
              'on a fakeclaim; never confess mafia. Make it land.'
        : '$who just challenged you: "$challenge" — give a full first-person '
              'rebuttal (up to ~120 words). Answer the charge; claim a real '
              'power role only if true and useful. Make it land.';
    return _speech(ctx, task);
  }

  @override
  Future<(int?, String)> nominate(DecisionContext ctx, List<int> candidates) =>
      seatSpeechAct(
        this,
        ctx: ctx,
        candidates: candidates,
        task:
            'Nominate one player for elimination, or pass. A nomination must '
            'be argued out loud to the table in first person with a charge '
            'that is not a copy of another player\'s wording today.',
        choiceKey: 'nominate',
        speechKey: 'statement',
        speechWordCap: 70,
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
    task:
        'Fire your single bullet at a player tonight, or hold it. After '
        'you fire you will learn privately whether it landed and whether '
        'they were mafia — spend it on someone you believe is mafia.',
    key: 'shoot',
    legal: targets,
    allowNone: true,
  );
}
