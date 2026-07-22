import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatMessage {
  const ChatMessage(this.role, this.content);

  const ChatMessage.system(String content) : this('system', content);

  const ChatMessage.user(String content) : this('user', content);

  const ChatMessage.assistant(String content) : this('assistant', content);

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatResult {
  const ChatResult({
    required this.text,
    required this.latency,
    this.promptTokens,
    this.completionTokens,
  });

  final String text;
  final Duration latency;
  final int? promptTokens;
  final int? completionTokens;
}

class ChatClientException implements Exception {
  ChatClientException(this.message);

  final String message;

  @override
  String toString() => 'ChatClientException: $message';
}

/// Non-streaming OpenAI-compatible client — the M2 workhorse adapter
/// (LLM_INTEGRATION.md §1). Streaming lands with the UI; headless play
/// only needs final messages.
class OpenAiCompatClient {
  OpenAiCompatClient({
    required this.baseUrl,
    this.apiKey,
    this.requestTimeout = const Duration(minutes: 5),
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String? apiKey;
  final Duration requestTimeout;
  final http.Client _http;

  var _totalPromptTokens = 0;
  var _totalCompletionTokens = 0;
  var _calls = 0;

  ({int calls, int promptTokens, int completionTokens}) get usage => (
    calls: _calls,
    promptTokens: _totalPromptTokens,
    completionTokens: _totalCompletionTokens,
  );

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    if (apiKey != null) 'authorization': 'Bearer $apiKey',
  };

  Future<List<String>> listModels() async {
    final res = await _http
        .get(Uri.parse('$baseUrl/models'), headers: _headers)
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw ChatClientException('GET /models -> ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List? ?? []).cast<Map<String, dynamic>>();
    return [for (final m in data) m['id'] as String];
  }

  Future<ChatResult> chat(
    List<ChatMessage> messages, {
    required String model,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final sw = Stopwatch()..start();
    final res = await _http
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: _headers,
          body: jsonEncode({
            'model': model,
            'temperature': temperature,
            'max_tokens': maxTokens,
            'messages': [for (final m in messages) m.toJson()],
          }),
        )
        .timeout(requestTimeout);
    if (res.statusCode != 200) {
      throw ChatClientException(
        'POST /chat/completions -> ${res.statusCode}: '
        '${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final choices = (body['choices'] as List?)?.cast<Map<String, dynamic>>();
    final message = choices?.firstOrNull?['message'] as Map<String, dynamic>?;
    final text = (message?['content'] as String?) ?? '';
    final usage = body['usage'] as Map<String, dynamic>?;
    final prompt = usage?['prompt_tokens'] as int?;
    final completion = usage?['completion_tokens'] as int?;
    _calls++;
    _totalPromptTokens += prompt ?? 0;
    _totalCompletionTokens += completion ?? 0;
    return ChatResult(
      text: text,
      latency: sw.elapsed,
      promptTokens: prompt,
      completionTokens: completion,
    );
  }

  void close() => _http.close();
}
