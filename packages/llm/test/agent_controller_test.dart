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
AgentController agentWith(List<String> replies, {List<String>? requests}) {
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
  );
}

void main() {
  test('speech returns trimmed text and enforces the word cap', () async {
    final agent = agentWith(['  A fine speech.  ']);
    expect(await agent.speak(ctx()), 'A fine speech.');
    final long = agentWith([List.filled(300, 'word').join(' ')]);
    final speech = await long.defend(ctx());
    expect(speech.split(' ').length, 140);
  });

  test('empty speech throws so the engine falls back', () async {
    final agent = agentWith(['   ']);
    expect(() => agent.lastWords(ctx()), throwsA(isA<ParseFailure>()));
  });

  test('vote parses a clean JSON reply', () async {
    final agent = agentWith(['{"reason": "gut read", "vote": 2}']);
    expect(await agent.vote(ctx(), [1, 2]), 2);
  });

  test('nomination pass and assassin hold return null', () async {
    expect(
      await agentWith([
        '{"reason": "wait", "nominate": null}',
      ]).nominate(ctx(), [1, 2]),
      isNull,
    );
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
      '{"reason": "ok", "kill": 1}',
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

  test('mafia chat is plain speech', () async {
    final agent = agentWith(['We hit the loud one.']);
    expect(
      await agent.mafiaChat(ctx(role: Role.mafioso)),
      'We hit the loud one.',
    );
  });
}
