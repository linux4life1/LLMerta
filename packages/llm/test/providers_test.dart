import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

const spec = JsonSchemaSpec(
  name: 'vote',
  schema: {
    'type': 'object',
    'properties': {
      'reason': {'type': 'string'},
      'vote': {
        'anyOf': [
          {
            'type': 'integer',
            'enum': [1, 2],
          },
          {'type': 'null'},
        ],
      },
    },
    'required': ['reason', 'vote'],
    'additionalProperties': false,
  },
);

void main() {
  group('AnthropicClient', () {
    test('maps schema to forced tool use and decodes tool input', () async {
      late Map<String, dynamic> sent;
      late Map<String, String> headers;
      final client = AnthropicClient(
        apiKey: 'k',
        baseUrl: 'http://test',
        httpClient: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          headers = request.headers;
          return http.Response(
            jsonEncode({
              'content': [
                {
                  'type': 'tool_use',
                  'name': 'vote',
                  'input': {'reason': 'gut', 'vote': 2},
                },
              ],
              'usage': {'input_tokens': 5, 'output_tokens': 2},
            }),
            200,
          );
        }),
      );
      final result = await client.chat(
        [const ChatMessage.system('sys'), const ChatMessage.user('u')],
        model: 'claude-x',
        jsonSchema: spec,
      );
      expect(headers['x-api-key'], 'k');
      expect(sent['system'], 'sys');
      expect((sent['messages'] as List), hasLength(1));
      expect((sent['tool_choice'] as Map<String, dynamic>)['name'], 'vote');
      expect(jsonDecode(result.text), {'reason': 'gut', 'vote': 2});
      expect(client.usage.promptTokens, 5);
    });

    test('plain text response joins text blocks', () async {
      final client = AnthropicClient(
        apiKey: 'k',
        baseUrl: 'http://test',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'hello '},
                {'type': 'text', 'text': 'town'},
              ],
            }),
            200,
          ),
        ),
      );
      final result = await client.chat([
        const ChatMessage.user('u'),
      ], model: 'claude-x');
      expect(result.text, 'hello town');
    });
  });

  group('GeminiClient', () {
    test('maps roles, system instruction, and responseSchema', () async {
      late Map<String, dynamic> sent;
      late Uri url;
      final client = GeminiClient(
        apiKey: 'k',
        baseUrl: 'http://test',
        httpClient: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          url = request.url;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': '{"reason": "r", "vote": null}'},
                    ],
                  },
                },
              ],
              'usageMetadata': {
                'promptTokenCount': 9,
                'candidatesTokenCount': 4,
              },
            }),
            200,
          );
        }),
      );
      final result = await client.chat(
        [
          const ChatMessage.system('sys'),
          const ChatMessage.user('u'),
          const ChatMessage.assistant('a'),
        ],
        model: 'gemini-x',
        jsonSchema: spec,
      );
      expect(url.path, contains('models/gemini-x:generateContent'));
      final contents = (sent['contents'] as List).cast<Map<String, dynamic>>();
      expect(contents.map((c) => c['role']), ['user', 'model']);
      final config = sent['generationConfig'] as Map<String, dynamic>;
      expect(config['responseMimeType'], 'application/json');
      final voteSchema =
          (((config['responseSchema'] as Map<String, dynamic>)['properties']
                  as Map<String, dynamic>)['vote'])
              as Map<String, dynamic>;
      expect(voteSchema['nullable'], isTrue);
      expect(voteSchema['enum'], [1, 2]);
      expect(voteSchema.containsKey('anyOf'), isFalse);
      expect(jsonDecode(result.text), {'reason': 'r', 'vote': null});
      expect(client.usage.completionTokens, 4);
    });

    test('listModels strips the models/ prefix', () async {
      final client = GeminiClient(
        apiKey: 'k',
        baseUrl: 'http://test',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'models': [
                {'name': 'models/gemini-a'},
                {'name': 'models/gemini-b'},
              ],
            }),
            200,
          ),
        ),
      );
      expect(await client.listModels(), ['gemini-a', 'gemini-b']);
    });
  });

  group('RequestPolicy', () {
    test('retries 429/5xx and then succeeds', () async {
      var calls = 0;
      final policy = RequestPolicy(baseDelay: Duration.zero);
      final result = await policy.run(() async {
        calls++;
        if (calls < 3) {
          throw ChatClientException('busy', statusCode: calls == 1 ? 429 : 503);
        }
        return 'ok';
      });
      expect(result, 'ok');
      expect(calls, 3);
    });

    test('does not retry request rejections or give up late', () async {
      var calls = 0;
      final policy = RequestPolicy(baseDelay: Duration.zero);
      await expectLater(
        policy.run(() async {
          calls++;
          throw ChatClientException('bad request', statusCode: 400);
        }),
        throwsA(isA<ChatClientException>()),
      );
      expect(calls, 1);
      calls = 0;
      await expectLater(
        policy.run(() async {
          calls++;
          throw const SocketException('down');
        }),
        throwsA(isA<SocketException>()),
      );
      expect(calls, 3);
    });

    test('caps concurrency', () async {
      final policy = RequestPolicy(maxConcurrent: 2);
      var active = 0;
      var peak = 0;
      Future<void> job() => policy.run(() async {
        active++;
        peak = peak > active ? peak : active;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        active--;
      });
      await Future.wait([for (var i = 0; i < 6; i++) job()]);
      expect(peak, 2);
    });
  });

  group('StdinHumanController', () {
    DecisionContext ctx() => DecisionContext(
      seat: 0,
      role: Role.sheriff,
      day: 1,
      visibleEvents: const [GameStarted(seats: 7)],
      livingSeats: const [0, 1, 2],
    );

    test('reads a seat choice, rejecting invalid input', () async {
      final inputs = ['9', 'x', '2'];
      final out = <String>[];
      final human = StdinHumanController(
        names: const ['Alma', 'Boris', 'Clara'],
        readLine: () => inputs.removeAt(0),
        write: out.add,
      );
      expect(await human.sheriffInvestigate(ctx(), [1, 2]), 2);
      expect(out.join('\n'), contains('invalid'));
    });

    test('empty input passes when allowed and speech reads a line', () async {
      final inputs = ['', 'I suspect Boris.'];
      final human = StdinHumanController(
        names: const ['Alma', 'Boris', 'Clara'],
        readLine: () => inputs.removeAt(0),
        write: (_) {},
      );
      expect(await human.nominate(ctx(), [1, 2]), isNull);
      expect(await human.speak(ctx()), 'I suspect Boris.');
    });
  });
}
