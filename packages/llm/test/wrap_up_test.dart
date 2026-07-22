import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

void main() {
  test('table talk gives every agent omniscient hindsight in rounds', () async {
    final prompts = <String>[];
    var n = 0;
    final client = OpenAiCompatClient(
      baseUrl: 'http://test/v1',
      httpClient: MockClient((request) async {
        prompts.add(request.body);
        n++;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'line $n'},
              },
            ],
          }),
          200,
        );
      }),
    );
    const events = <GameEvent>[
      GameStarted(seats: 3),
      RolesDealt({0: Role.mafioso, 1: Role.sheriff, 2: Role.villager}),
      MafiaChatSaid(seat: 0, text: 'kill the sheriff'),
      GameEnded(winner: Faction.town),
    ];
    final human = <String>['good game all', ''];
    final talk = await postGameTableTalk(
      events: events,
      names: const ['Alma', 'Boris', 'Clara'],
      agentSeats: {0: (client, 'm'), 1: (client, 'm')},
      rounds: 2,
      humanSeat: 2,
      humanTurn: (_) async => human.isEmpty ? null : human.removeAt(0),
    );
    expect(talk, hasLength(5));
    expect(talk[2], (2, 'good game all'));
    expect(prompts.first, contains('kill the sheriff'));
    expect(prompts.first, contains('nothing is secret anymore'));
    expect(prompts.last, contains('good game all'));
    expect(human, isEmpty);
  });
}
