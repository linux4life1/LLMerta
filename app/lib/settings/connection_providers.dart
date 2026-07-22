import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/services.dart';

part 'connection_providers.g.dart';

@riverpod
Stream<List<Connection>> connectionRows(Ref ref) =>
    ref.watch(appDatabaseProvider).watchConnections();

@riverpod
Stream<List<String>> connectionModels(Ref ref, String connectionId) =>
    ref.watch(appDatabaseProvider).watchModels(connectionId);

/// Test = fetch the live model list; success doubles as the cache refresh.
@riverpod
class ConnectionTest extends _$ConnectionTest {
  @override
  AsyncValue<int>? build(String connectionId) => null;

  Future<void> run() async {
    state = const AsyncValue.loading();
    final db = ref.read(appDatabaseProvider);
    final rows = await db.watchConnections().first;
    final connection = rows.firstWhere((c) => c.id == connectionId);
    final apiKey = await ref.read(apiKeyStoreProvider).read(connectionId);
    final factory = ref.read(clientFactoryProvider);
    try {
      final count = await refreshConnectionModels(
        db: db,
        factory: factory,
        connection: connection,
        apiKey: apiKey,
      );
      state = AsyncValue.data(count);
    } on Exception catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

/// Fetches and caches a connection's model list detached from any provider
/// lifecycle — dialogs may close before it lands.
Future<int> refreshConnectionModels({
  required AppDatabase db,
  required ClientFactory factory,
  required Connection connection,
  String? apiKey,
}) async {
  final client = factory(connection, apiKey);
  try {
    final models = await client.listModels();
    await db.replaceModels(connection.id, models);
    return models.length;
  } finally {
    client.close();
  }
}

// ── Local server discovery ──────────────────────────────────────────────
// Connect-only by decree: LLMerta probes servers the user already runs;
// it never launches, installs, or manages one.

class LocalServerPreset {
  const LocalServerPreset(this.name, this.port);

  final String name;
  final int port;

  String get baseUrl => 'http://127.0.0.1:$port/v1';
}

const localServerPresets = [
  LocalServerPreset('oMLX', 8000),
  LocalServerPreset('koboldcpp', 5001),
  LocalServerPreset('Ollama', 11434),
  LocalServerPreset('LM Studio', 1234),
  LocalServerPreset('llama.cpp', 8080),
];

class LocalScanHit {
  const LocalScanHit({required this.preset, required this.models});

  final LocalServerPreset preset;
  final List<String> models;
}

/// `null` means nothing answered at that port; a hit carries the served
/// model ids straight from `/v1/models`.
Future<List<String>?> probeLocalServer(
  http.Client client,
  String baseUrl,
) async {
  try {
    final response = await client
        .get(Uri.parse('$baseUrl/models'))
        .timeout(const Duration(milliseconds: 900));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    final data = body is Map ? body['data'] : null;
    if (data is! List) return null;
    return [
      for (final entry in data)
        if (entry case {'id': final String id}) id,
    ];
  } on Exception {
    return null;
  }
}

@riverpod
class LocalScan extends _$LocalScan {
  @override
  Future<List<LocalScanHit>> build() => _scan();

  Future<List<LocalScanHit>> _scan() async {
    final client = ref.read(scanHttpClientProvider);
    final probed = await Future.wait([
      for (final preset in localServerPresets)
        probeLocalServer(client, preset.baseUrl).then((m) => (preset, m)),
    ]);
    return [
      for (final (preset, models) in probed)
        if (models != null) LocalScanHit(preset: preset, models: models),
    ];
  }

  Future<void> rescan() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_scan);
  }
}

// ── Hosted presets: URL baked in, key is the whole ceremony ─────────────

class HostedPreset {
  const HostedPreset(this.name, this.kind, this.baseUrl, this.blurb);

  final String name;
  final ProviderKind kind;
  final String baseUrl;
  final String blurb;
}

const hostedPresets = [
  HostedPreset(
    'OpenRouter',
    ProviderKind.openaiCompat,
    'https://openrouter.ai/api/v1',
    'everything under one key',
  ),
  HostedPreset(
    'nano-GPT',
    ProviderKind.openaiCompat,
    'https://nano-gpt.com/api/v1',
    'pay-per-message',
  ),
  HostedPreset(
    'Anthropic',
    ProviderKind.anthropic,
    'https://api.anthropic.com',
    'Claude direct',
  ),
  HostedPreset(
    'Gemini',
    ProviderKind.gemini,
    'https://generativelanguage.googleapis.com',
    'Google direct',
  ),
];
