import 'package:game_core/game_core.dart';

import 'agent_controller.dart';
import 'decision_parser.dart';
import 'provider.dart';

/// Shared path for "pick a seat + spoken line" acts (nominate, argue).
Future<(int?, String)> seatSpeechAct(
  AgentController agent, {
  required DecisionContext ctx,
  required List<int> candidates,
  required String task,
  required String choiceKey,
  required String speechKey,
  required int speechWordCap,
}) async {
  final system = ChatMessage.system(agent.prompts.system(ctx));
  final analysis = agent.twoStepReasoning
      ? await agent.thinkPublic(ctx, task)
      : null;
  final schemaLine =
      '{"reason": "<one line, private>", '
      '"$choiceKey": <seat number or null>, '
      '"$speechKey": "<what you say out loud — empty if you pass>"}';
  final ordered = AgentController.presentationOrder(candidates, ctx);
  final ask = ChatMessage.user(
    '${await agent.situationPublic(ctx, task)}\n\n'
    '${analysis == null || analysis.isEmpty ? '' : 'YOUR PRIVATE ANALYSIS (yours alone, moments ago):\n$analysis\n\n'}'
    'YOUR TASK: $task\n'
    'Legal targets: '
    '${ordered.map((s) => '${agent.prompts.names[s]} (seat ${s + 1})').join(', ')}.\n'
    'Reply with ONLY this JSON, nothing else: $schemaLine',
  );
  var messages = [system, ask];
  for (var attempt = 0; attempt < 2; attempt++) {
    ChatResult result;
    final constrained = agent.useJsonSchema && !agent.schemaRejected;
    try {
      result = await agent.client.chat(
        messages,
        model: agent.model,
        temperature: attempt == 0 ? agent.temperature : 0.2,
        maxTokens: agent.decisionMaxTokens,
        jsonSchema: constrained
            ? _seatSpeechSchema(choiceKey, speechKey, ordered)
            : null,
      );
    } on ChatClientException catch (e) {
      if (!constrained || !e.isRequestRejection) rethrow;
      agent.markSchemaRejected();
      result = await agent.client.chat(
        messages,
        model: agent.model,
        temperature: attempt == 0 ? agent.temperature : 0.2,
        maxTokens: agent.decisionMaxTokens,
      );
    }
    try {
      final json = extractJsonObject(result.text);
      final choice = parseSeatChoice(
        json,
        choiceKey,
        legal: candidates,
        names: agent.prompts.names,
        allowNone: true,
      );
      var speech = (json[speechKey] as String? ?? '').trim();
      final words = speech.split(RegExp(r'\s+'));
      if (words.length > speechWordCap) {
        speech = words.take(speechWordCap).join(' ');
      }
      if (constrained) agent.noteSchemaParse(ok: true);
      if (json['reason'] case final String reason) {
        agent.onReason?.call(task, reason);
      }
      if (choice == null || speech.isEmpty) return (null, '');
      return (choice, speech);
    } on ParseFailure catch (failure) {
      if (constrained) agent.noteSchemaParse(ok: false);
      messages = [
        system,
        ask,
        ChatMessage.assistant(result.text),
        ChatMessage.user(
          'Your reply was rejected: $failure. '
          'Reply with ONLY the JSON object: $schemaLine',
        ),
      ];
    }
  }
  throw ParseFailure('unparseable after retry');
}

JsonSchemaSpec _seatSpeechSchema(
  String choiceKey,
  String speechKey,
  List<int> legal,
) => JsonSchemaSpec(
  name: choiceKey,
  schema: {
    'type': 'object',
    'properties': {
      'reason': {'type': 'string', 'maxLength': 300},
      choiceKey: {
        'anyOf': [
          {
            'type': 'integer',
            'enum': [for (final s in legal) s + 1],
          },
          {'type': 'null'},
        ],
      },
      speechKey: {'type': 'string', 'maxLength': 500},
    },
    'required': ['reason', choiceKey, speechKey],
    'additionalProperties': false,
  },
);
