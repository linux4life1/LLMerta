import 'package:llm/llm.dart';
import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clients.g.dart';

typedef ClientFactory =
    ChatProvider Function(Connection connection, String? apiKey);

ChatProvider buildClient(Connection connection, String? apiKey) =>
    switch (connection.kind) {
      ProviderKind.openaiCompat => OpenAiCompatClient(
        baseUrl: connection.baseUrl,
        apiKey: apiKey,
      ),
      ProviderKind.anthropic => AnthropicClient(
        apiKey: apiKey ?? '',
        baseUrl: connection.baseUrl,
      ),
      ProviderKind.gemini => GeminiClient(
        apiKey: apiKey ?? '',
        baseUrl: connection.baseUrl,
      ),
    };

@Riverpod(keepAlive: true)
ClientFactory clientFactory(Ref ref) => buildClient;
