import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider.dart';

/// Native Anthropic Messages API adapter. Structured output is a forced
/// tool call; the tool input comes back re-encoded as JSON text so the
/// shared parser path handles every provider identically.
class AnthropicClient with UsageTracking implements ChatProvider {
  AnthropicClient({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com',
    this.requestTimeout = const Duration(minutes: 5),
    RequestPolicy? policy,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client(),
       _policy = policy ?? RequestPolicy();

  final String apiKey;
  final String baseUrl;
  final Duration requestTimeout;
  final http.Client _http;
  final RequestPolicy _policy;

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
  };

  @override
  Future<List<String>> listModels() => _policy.run(() async {
    final res = await _http
        .get(Uri.parse('$baseUrl/v1/models'), headers: _headers)
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw ChatClientException(
        'GET /v1/models -> ${res.statusCode}',
        statusCode: res.statusCode,
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List? ?? []).cast<Map<String, dynamic>>();
    return [for (final m in data) m['id'] as String];
  });

  @override
  Future<ChatResult> chat(
    List<ChatMessage> messages, {
    required String model,
    double temperature = 0.7,
    int maxTokens = 1024,
    JsonSchemaSpec? jsonSchema,
  }) => _policy.run(() async {
    final sw = Stopwatch()..start();
    final system = messages
        .where((m) => m.role == 'system')
        .map((m) => m.content)
        .join('\n\n');
    final res = await _http
        .post(
          Uri.parse('$baseUrl/v1/messages'),
          headers: _headers,
          body: jsonEncode({
            'model': model,
            'max_tokens': maxTokens,
            'temperature': temperature,
            if (system.isNotEmpty) 'system': system,
            'messages': [
              for (final m in messages)
                if (m.role != 'system') m.toJson(),
            ],
            if (jsonSchema != null) ...{
              'tools': [
                {
                  'name': jsonSchema.name,
                  'description': 'Submit your decision.',
                  'input_schema': jsonSchema.schema,
                },
              ],
              'tool_choice': {'type': 'tool', 'name': jsonSchema.name},
            },
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw ChatClientException(
        'POST /v1/messages -> ${res.statusCode}: '
        '${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
        statusCode: res.statusCode,
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final blocks = (body['content'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final toolUse = blocks.where((b) => b['type'] == 'tool_use').firstOrNull;
    final text = toolUse != null
        ? jsonEncode(toolUse['input'])
        : blocks
              .where((b) => b['type'] == 'text')
              .map((b) => b['text'] as String? ?? '')
              .join();
    final usage = body['usage'] as Map<String, dynamic>?;
    final prompt = usage?['input_tokens'] as int?;
    final completion = usage?['output_tokens'] as int?;
    recordUsage(prompt, completion);
    return ChatResult(
      text: text,
      latency: sw.elapsed,
      promptTokens: prompt,
      completionTokens: completion,
    );
  });

  @override
  void close() => _http.close();
}
