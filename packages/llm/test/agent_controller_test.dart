import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];

DecisionContext ctx({Role role = Role.villager, int seat = 0}) =>
    DecisionContext(
      seat: seat,
      role: role,
      day: 1,
      visibleEvents: const [GameStarted(seats: 7)],
      livingSeats: const [0, 1, 2, 3, 4, 5, 6],
    );

/// Serves scripted completions in order; records request bodies.
AgentController agentWith(
  List<String> replies, {
  List<String>? requests,
  bool useJsonSchema = true,
  Future<String?> Function(DecisionContext ctx, String task)? memoryFor,
}) {
  var call = 0;
  final client = OpenAiCompatClient(
    baseUrl: 'http://test/v1',
    httpClient: MockClient((request) async {
      requests?.add(request.body);
      final text = replies[call < replies.length ? call : replies.length - 1];
      call++;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': text},
            },
          ],
          'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  return AgentController(
    client: client,
    model: 'test-model',
    prompts: const AgentPromptBuilder(names: names),
    useJsonSchema: useJsonSchema,
    memoryFor: memoryFor,
  );
}

void main() {
  twoStepTests();
  schemaTests();
  test('schema speech extracts only the speech field', () async {
    final agent = agentWith([
      '{"reason": "hide my role", "speech": "  A fine speech.  "}',
    ]);
    expect(await agent.speak(ctx()), 'A fine speech.');
  });

  test(
    'sheriff with live mafia hit is told to claim in the speak task',
    () async {
      final requests = <String>[];
      final agent = agentWith([
        '{"reason": "claim", "speech": "I am the Sheriff. Dmitri is mafia."}',
      ], requests: requests);
      final sheriffCtx = DecisionContext(
        seat: 6,
        role: Role.sheriff,
        day: 2,
        visibleEvents: const [
          GameStarted(seats: 7),
          RoleReceived(seat: 6, role: Role.sheriff),
          DayBegan(2),
          SheriffInvestigated(sheriff: 6, target: 3, foundMafia: true),
        ],
        livingSeats: const [0, 1, 2, 3, 4, 5, 6],
      );
      await agent.speak(sheriffCtx);
      expect(requests.single, contains('live MAFIA investigation'));
      expect(requests.single, contains('claiming Sheriff'));
      expect(requests.single, contains('Dmitri'));
    },
  );

  // Regression: BALANCE.md mixed game — an unconstrained defense spoke its
  // raw fenced envelope, private reason included. Never again.
  test('unconstrained fenced envelope speaks only the speech field', () async {
    final agent = agentWith([
      '```json\n{"reason": "deflect the sheriff", '
          '"speech": "I was baking all night."}\n```',
    ], useJsonSchema: false);
    final reasons = <String>[];
    agent.onReason = (task, reason) => reasons.add(reason);
    final speech = await agent.defend(ctx());
    expect(speech, 'I was baking all night.');
    expect(speech, isNot(contains('deflect')));
    expect(reasons, ['deflect the sheriff']);
  });

  test(
    'unconstrained bare envelope parses; prose still passes through',
    () async {
      final bare = agentWith([
        '{"reason": "r", "speech": "Short and sweet."}',
      ], useJsonSchema: false);
      expect(await bare.lastWords(ctx()), 'Short and sweet.');

      final prose = agentWith([
        'No JSON here, just talk.',
      ], useJsonSchema: false);
      expect(await prose.speak(ctx()), 'No JSON here, just talk.');
    },
  );

  test('unconstrained envelope without speech retries corrected', () async {
    final agent = agentWith([
      '{"reason": "only a reason"}',
      '{"reason": "ok", "speech": "Fixed on retry."}',
    ], useJsonSchema: false);
    expect(await agent.speak(ctx()), 'Fixed on retry.');
  });

  test('plain-text speech path trims and enforces the word cap', () async {
    final agent = agentWith(['  A fine speech.  '], useJsonSchema: false);
    expect(await agent.speak(ctx()), 'A fine speech.');
    final long = agentWith([
      List.filled(300, 'word').join(' '),
    ], useJsonSchema: false);
    final speech = await long.defend(ctx());
    expect(speech.split(' ').length, 140);
  });

  test(
    'empty or wrongly-typed speech throws for the engine fallback',
    () async {
      final agent = agentWith(['   '], useJsonSchema: false);
      expect(() => agent.lastWords(ctx()), throwsA(isA<ParseFailure>()));
      final badType = agentWith(['{"reason": "r", "speech": 7}']);
      expect(() => badType.speak(ctx()), throwsA(isA<ParseFailure>()));
      final empty = agentWith(['{"reason": "r", "speech": "  "}']);
      expect(() => empty.speak(ctx()), throwsA(isA<ParseFailure>()));
    },
  );

  test('vote parses a clean JSON reply', () async {
    final agent = agentWith(['{"reason": "gut read", "vote": 3}']);
    expect(await agent.vote(ctx(), [1, 2]), 2);
  });

  test('system prompt carries the grounding guard and fixed-role line', () {
    const prompts = AgentPromptBuilder(names: names);
    final system = prompts.system(ctx(role: Role.doctor));
    expect(system, contains('never invent private conversations'));
    expect(system, contains('true role line above is fixed'));
  });

  // Regression (field report, day-3 live game): agents talked about a
  // night-killed player as if the town had lynched them.
  test('the situation never lets a night kill read as a lynch', () {
    const prompts = AgentPromptBuilder(names: names);
    final situation = prompts.situation(
      DecisionContext(
        seat: 2,
        role: Role.villager,
        day: 2,
        visibleEvents: const [
          GameStarted(seats: 7),
          DayBegan(1),
          TrialStarted([1]),
          Verdict(eliminated: 1, revealedRole: Role.mafioso),
          NightBegan(1),
          DayBegan(2),
          DawnAnnounced(deaths: [0], revealedRoles: {0: Role.villager}),
        ],
        livingSeats: const [2, 3, 4, 5, 6],
      ),
    );
    expect(
      situation,
      contains('Alma — killed in the night before day 2, was the villager'),
    );
    expect(
      situation,
      contains('Boris — voted out by the town on day 1, was the mafioso'),
    );
    expect(situation, contains('Never confuse a night kill'));
    // Rendered seat numbers match the UI (one-based).
    expect(situation, contains('Clara (seat 3)'));
    expect(situation, isNot(contains('Clara (seat 2)')));
  });

  test('onReason captures private rationales for the reveal', () async {
    final reasons = <(String, String)>[];
    final agent = agentWith(['{"reason": "Edda contradicted dawn", "vote": 2}'])
      ..onReason = (task, reason) => reasons.add((task, reason));
    await agent.vote(ctx(), [1, 2]);
    expect(reasons.single.$2, 'Edda contradicted dawn');
    expect(reasons.single.$1, isNotEmpty);

    final speechReasons = <String>[];
    final speaker = agentWith(['{"reason": "stay small", "speech": "Hi."}'])
      ..onReason = (task, reason) => speechReasons.add(reason);
    await speaker.speak(ctx());
    expect(speechReasons, ['stay small']);
  });

  test('memoryFor block rides into the outgoing prompt', () async {
    final requests = <String>[];
    var seenTask = '';
    final agent = agentWith(
      ['{"reason": "recall", "vote": 2}'],
      requests: requests,
      memoryFor: (ctx, task) async {
        seenTask = task;
        return 'RELEVANT PAST STATEMENTS (verbatim):\n'
            '- Boris (seat 1): "I was at the docks."';
      },
    );
    expect(await agent.vote(ctx(), [1, 2]), 1);
    expect(requests.single, contains('I was at the docks.'));
    expect(seenTask, isNotEmpty);

    final silent = agentWith([
      '{"reason": "r", "vote": 3}',
    ], memoryFor: (ctx, task) async => null);
    expect(await silent.vote(ctx(), [1, 2]), 2);
  });

  test('nomination pass and assassin hold return null', () async {
    final pass = await agentWith([
      '{"reason": "wait", "nominate": null, "statement": ""}',
    ]).nominate(ctx(), [1, 2]);
    expect(pass.$1, isNull);
    expect(pass.$2, isEmpty);

    final accusation = await agentWith([
      '{"reason": "gut", "nominate": 3, '
          '"statement": "Clara has dodged every direct question."}',
    ]).nominate(ctx(), [1, 2]);
    expect(accusation.$1, 2);
    expect(accusation.$2, contains('dodged'));
    expect(
      await agentWith([
        '{"reason": "save it", "shoot": "hold"}',
      ]).assassinShoot(ctx(role: Role.assassin), [1, 2]),
      isNull,
    );
  });

  test('malformed first reply triggers one corrective retry', () async {
    final requests = <String>[];
    final agent = agentWith([
      'I choose Boris!',
      '{"reason": "ok", "kill": 2}',
    ], requests: requests);
    expect(await agent.mafiaKillVote(ctx(role: Role.mafioso), [1, 2]), 1);
    expect(requests, hasLength(2));
    expect(requests.last, contains('rejected'));
  });

  test('two malformed replies throw for the engine fallback', () async {
    final agent = agentWith(['nope', 'still nope']);
    expect(
      () => agent.doctorProtect(ctx(role: Role.doctor), [1, 2]),
      throwsA(isA<ParseFailure>()),
    );
  });

  test('required choices reject a null target even on retry', () async {
    final agent = agentWith(['{"protect": null}', '{"protect": null}']);
    expect(
      () => agent.doctorProtect(ctx(role: Role.doctor), [1, 2]),
      throwsA(isA<ParseFailure>()),
    );
  });

  test('sheriff investigate returns a required seat', () async {
    final agent = agentWith(['{"reason": "hmm", "investigate": "Clara"}']);
    expect(await agent.sheriffInvestigate(ctx(role: Role.sheriff), [1, 2]), 2);
  });

  test('mafia chat flows through the speech path', () async {
    final agent = agentWith([
      '{"reason": "plan", "speech": "We hit the loud one."}',
    ]);
    expect(
      await agent.mafiaChat(ctx(role: Role.mafioso)),
      'We hit the loud one.',
    );
  });
}

void schemaTests() {
  test(
    'decisions send a strict json_schema with legal seats as enum',
    () async {
      final bodies = <String>[];
      final agent = agentWith([
        '{"reason": "read", "vote": 2}',
      ], requests: bodies);
      await agent.vote(ctx(), [1, 2]);
      final body = jsonDecode(bodies.single) as Map<String, dynamic>;
      final format = body['response_format'] as Map<String, dynamic>;
      expect(format['type'], 'json_schema');
      final schema =
          ((format['json_schema'] as Map<String, dynamic>)['schema']
                  as Map<String, dynamic>)['properties']
              as Map<String, dynamic>;
      final vote = schema['vote'] as Map<String, dynamic>;
      expect(((vote['anyOf'] as List).first as Map<String, dynamic>)['enum'], [
        3,
        2,
      ]);
    },
  );

  test(
    'a server that rejects response_format falls back to prompt JSON',
    () async {
      final bodies = <String>[];
      var call = 0;
      final client = OpenAiCompatClient(
        baseUrl: 'http://test/v1',
        httpClient: MockClient((request) async {
          bodies.add(request.body);
          call++;
          if (request.body.contains('response_format')) {
            return http.Response('unsupported', 400);
          }
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': '{"reason": "ok", "vote": 2}',
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final agent = AgentController(
        client: client,
        model: 'm',
        prompts: const AgentPromptBuilder(names: names),
      );
      expect(await agent.vote(ctx(), [1, 2]), 1);
      expect(call, 2);
      expect(await agent.vote(ctx(), [1, 2]), 1);
      expect(bodies.last.contains('response_format'), isFalse);
    },
  );

  test('required choice schema has a bare integer enum', () async {
    final bodies = <String>[];
    final agent = agentWith([
      '{"reason": "hm", "protect": 2}',
    ], requests: bodies);
    await agent.doctorProtect(ctx(role: Role.doctor), [1, 2]);
    final body = jsonDecode(bodies.single) as Map<String, dynamic>;
    final props =
        ((((body['response_format'] as Map<String, dynamic>)['json_schema']
                    as Map<String, dynamic>)['schema']
                as Map<String, dynamic>)['properties'])
            as Map<String, dynamic>;
    expect((props['protect'] as Map<String, dynamic>)['enum'], [3, 2]);
  });
}

void twoStepTests() {
  test('two-step reasoning runs a think call and feeds it forward', () async {
    final bodies = <String>[];
    var call = 0;
    final client = OpenAiCompatClient(
      baseUrl: 'http://test/v1',
      httpClient: MockClient((request) async {
        bodies.add(request.body);
        call++;
        final text = call == 1
            ? 'Boris contradicted himself; vote him.'
            : '{"reason": "per analysis", "vote": 2}';
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': text},
              },
            ],
          }),
          200,
        );
      }),
    );
    final agent = AgentController(
      client: client,
      model: 'm',
      prompts: const AgentPromptBuilder(names: names),
      twoStepReasoning: true,
    );
    expect(await agent.vote(ctx(), [1, 2]), 1);
    expect(bodies, hasLength(2));
    expect(bodies.first, contains('Think privately first'));
    expect(bodies.first.contains('response_format'), isFalse);
    expect(bodies.last, contains('YOUR PRIVATE ANALYSIS'));
    expect(bodies.last, contains('Boris contradicted himself'));
  });
}
