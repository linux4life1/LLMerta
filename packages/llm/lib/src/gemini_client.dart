import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider.dart';

/// Native Gemini adapter. Structured output maps to responseSchema, whose
/// dialect differs from JSON Schema: no additionalProperties, and
/// `anyOf [T, null]` becomes `nullable: true`.
class GeminiClient with UsageTracking implements ChatProvider {
  GeminiClient({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com',
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
    'x-goog-api-key': apiKey,
  };

  @override
  Future<List<String>> listModels() => _policy.run(() async {
    final res = await _http
        .get(Uri.parse('$baseUrl/v1beta/models'), headers: _headers)
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw ChatClientException(
        'GET /v1beta/models -> ${res.statusCode}',
        statusCode: res.statusCode,
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final models = (body['models'] as List? ?? []).cast<Map<String, dynamic>>();
    return [
      for (final m in models) (m['name'] as String).replaceFirst('models/', ''),
    ];
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
          Uri.parse('$baseUrl/v1beta/models/$model:generateContent'),
          headers: _headers,
          body: jsonEncode({
            if (system.isNotEmpty)
              'systemInstruction': {
                'parts': [
                  {'text': system},
                ],
              },
            'contents': [
              for (final m in messages)
                if (m.role != 'system')
                  {
                    'role': m.role == 'assistant' ? 'model' : 'user',
                    'parts': [
                      {'text': m.content},
                    ],
                  },
            ],
            'generationConfig': {
              'temperature': temperature,
              'maxOutputTokens': maxTokens,
              if (jsonSchema != null) ...{
                'responseMimeType': 'application/json',
                'responseSchema': toGeminiSchema(jsonSchema.schema),
              },
            },
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw ChatClientException(
        'POST :generateContent -> ${res.statusCode}: '
        '${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
        statusCode: res.statusCode,
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = (body['candidates'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final parts =
        ((candidates.firstOrNull?['content'] as Map<String, dynamic>?)?['parts']
                    as List? ??
                [])
            .cast<Map<String, dynamic>>();
    final text = parts.map((p) => p['text'] as String? ?? '').join();
    final usage = body['usageMetadata'] as Map<String, dynamic>?;
    final prompt = usage?['promptTokenCount'] as int?;
    final completion = usage?['candidatesTokenCount'] as int?;
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

Map<String, dynamic> toGeminiSchema(Map<String, dynamic> schema) {
  final out = <String, dynamic>{};
  for (final MapEntry(:key, :value) in schema.entries) {
    switch (key) {
      case 'additionalProperties' || 'strict':
        break;
      case 'anyOf' when value is List:
        final options = value.cast<Map<String, dynamic>>();
        final nonNull =
            options.where((o) => o['type'] != 'null').firstOrNull ?? {};
        out.addAll(toGeminiSchema(nonNull));
        if (options.any((o) => o['type'] == 'null')) out['nullable'] = true;
      case 'properties' when value is Map<String, dynamic>:
        out['properties'] = {
          for (final MapEntry(key: name, value: prop) in value.entries)
            name: toGeminiSchema(prop as Map<String, dynamic>),
        };
      default:
        out[key] = value;
    }
  }
  return out;
}
