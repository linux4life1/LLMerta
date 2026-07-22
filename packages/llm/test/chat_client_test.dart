import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

void main() {
  test('chat posts messages and accumulates usage', () async {
    late Map<String, dynamic> sent;
    final client = OpenAiCompatClient(
      baseUrl: 'http://test/v1',
      apiKey: 'k',
      httpClient: MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.headers['authorization'], 'Bearer k');
        expect(request.url.path, '/v1/chat/completions');
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'hi'},
              },
            ],
            'usage': {'prompt_tokens': 7, 'completion_tokens': 3},
          }),
          200,
        );
      }),
    );
    final result = await client.chat([
      const ChatMessage.system('s'),
      const ChatMessage.user('u'),
    ], model: 'm');
    expect(result.text, 'hi');
    expect(result.promptTokens, 7);
    expect(sent['model'], 'm');
    expect((sent['messages'] as List), hasLength(2));
    await client.chat([const ChatMessage.user('u2')], model: 'm');
    expect(client.usage.calls, 2);
    expect(client.usage.promptTokens, 14);
    expect(client.usage.completionTokens, 6);
    client.close();
  });

  test('non-200 chat and model responses throw', () async {
    final client = OpenAiCompatClient(
      baseUrl: 'http://test/v1',
      policy: RequestPolicy(baseDelay: Duration.zero),
      httpClient: MockClient((_) async => http.Response('overloaded', 503)),
    );
    expect(
      () => client.chat([const ChatMessage.user('u')], model: 'm'),
      throwsA(isA<ChatClientException>()),
    );
    expect(client.listModels, throwsA(isA<ChatClientException>()));
  });

  test('listModels returns served ids', () async {
    final client = OpenAiCompatClient(
      baseUrl: 'http://test/v1',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 'a'},
              {'id': 'b'},
            ],
          }),
          200,
        ),
      ),
    );
    expect(await client.listModels(), ['a', 'b']);
  });

  test('missing content yields empty text', () async {
    final client = OpenAiCompatClient(
      baseUrl: 'http://test/v1',
      httpClient: MockClient(
        (_) async => http.Response(jsonEncode({'choices': <Object>[]}), 200),
      ),
    );
    final result = await client.chat([const ChatMessage.user('u')], model: 'm');
    expect(result.text, isEmpty);
  });
}
