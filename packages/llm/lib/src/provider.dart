import 'dart:async';
import 'dart:io';
import 'dart:math';

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

/// Provider-neutral structured-output request; each adapter maps it to its
/// native mechanism (response_format / forced tool-use / responseSchema).
class JsonSchemaSpec {
  const JsonSchemaSpec({required this.name, required this.schema});

  final String name;
  final Map<String, dynamic> schema;
}

class ChatClientException implements Exception {
  ChatClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 4xx (except 429) means the request itself is unacceptable — e.g. the
  /// server doesn't support structured output — and retrying is pointless.
  bool get isRequestRejection =>
      statusCode != null &&
      statusCode! >= 400 &&
      statusCode! < 500 &&
      statusCode != 429;

  @override
  String toString() => 'ChatClientException: $message';
}

abstract interface class ChatProvider {
  Future<List<String>> listModels();

  Future<ChatResult> chat(
    List<ChatMessage> messages, {
    required String model,
    double temperature,
    int maxTokens,
    JsonSchemaSpec? jsonSchema,
  });

  ({int calls, int promptTokens, int completionTokens}) get usage;

  void close();
}

/// Shared resilience per LLM_INTEGRATION.md §1: bounded concurrency plus
/// exponential backoff on 429/5xx/network errors. Timeouts are NOT retried
/// — the engine's per-action fallback owns that budget.
class RequestPolicy {
  RequestPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    int maxConcurrent = 4,
    Random? jitter,
  }) : _slots = maxConcurrent,
       _jitter = jitter ?? Random();

  final int maxAttempts;
  final Duration baseDelay;
  final Random _jitter;
  int _slots;
  final _waiters = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() request) async {
    await _acquire();
    try {
      for (var attempt = 1; ; attempt++) {
        try {
          return await request();
        } on Object catch (error) {
          if (attempt >= maxAttempts || !_retryable(error)) rethrow;
          final backoff = baseDelay * (1 << (attempt - 1));
          await Future<void>.delayed(
            backoff + Duration(milliseconds: _jitter.nextInt(250)),
          );
        }
      }
    } finally {
      _release();
    }
  }

  static bool _retryable(Object error) => switch (error) {
    ChatClientException(:final statusCode) =>
      statusCode == 429 || (statusCode != null && statusCode >= 500),
    SocketException() || HttpException() => true,
    _ => false,
  };

  Future<void> _acquire() {
    if (_slots > 0) {
      _slots--;
      return Future.value();
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _slots++;
    }
  }
}

/// Usage accounting shared by adapters.
mixin UsageTracking {
  var _calls = 0;
  var _prompt = 0;
  var _completion = 0;

  ({int calls, int promptTokens, int completionTokens}) get usage =>
      (calls: _calls, promptTokens: _prompt, completionTokens: _completion);

  void recordUsage(int? promptTokens, int? completionTokens) {
    _calls++;
    _prompt += promptTokens ?? 0;
    _completion += completionTokens ?? 0;
  }
}
