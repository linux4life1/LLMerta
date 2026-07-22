import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';

class _MemKeyStore implements ApiKeyStore {
  final keys = <String, String>{};

  @override
  Future<String?> read(String id) async => keys[id];

  @override
  Future<void> write(String id, String apiKey) async => keys[id] = apiKey;

  @override
  Future<void> delete(String id) async => keys.remove(id);
}

class _StubChat implements ChatProvider {
  _StubChat(this.models, {this.fail = false});

  final List<String> models;
  final bool fail;

  @override
  Future<List<String>> listModels() async {
    if (fail) throw ChatClientException('bad key', statusCode: 401);
    return models;
  }

  @override
  Future<ChatResult> chat(
    List<ChatMessage> messages, {
    required String model,
    double temperature = 0.7,
    int maxTokens = 1024,
    JsonSchemaSpec? jsonSchema,
  }) => throw UnimplementedError();

  @override
  ({int calls, int promptTokens, int completionTokens}) get usage =>
      (calls: 0, promptTokens: 0, completionTokens: 0);

  @override
  void close() {}
}

Future<void> _seedOmlx(AppDatabase db, {String id = 'omlx'}) =>
    db.upsertConnection(
      ConnectionsCompanion.insert(
        id: id,
        label: 'oMLX',
        kind: ProviderKind.openaiCompat,
        baseUrl: 'http://127.0.0.1:8000/v1',
      ),
    );

void main() {
  Future<void> pump(
    WidgetTester tester,
    AppDatabase db,
    _MemKeyStore keyStore, {
    bool failTest = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          apiKeyStoreProvider.overrideWith((_) => keyStore),
          clientFactoryProvider.overrideWith(
            (_) =>
                (connection, apiKey) => _StubChat(const [
                  'glm-5',
                  'qwen-3.6',
                  'grok-4.3',
                ], fail: failTest),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await settle(tester);
  }

  testWidgets('empty state offers adding the first connection', (tester) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db, _MemKeyStore());
      expect(find.text('No provider connections yet.'), findsOneWidget);
    });
  });

  testWidgets('add dialog saves connection and keychains the key', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final keyStore = _MemKeyStore();
      await pump(tester, db, keyStore);
      await tester.tap(find.text('Add connection'));
      await settle(tester);

      // Local scan (blocked network in tests) shows nothing running; the
      // classic form lives under the Custom expander.
      expect(find.text('Custom server…'), findsOneWidget);
      await tester.ensureVisible(find.text('Custom server…'));
      await settle(tester);
      await tester.tap(find.text('Custom server…'));
      await settle(tester);
      await tester.ensureVisible(find.widgetWithText(TextFormField, 'Label'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Label'),
        'Local oMLX',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'API key'),
        'sk-test-123',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Local oMLX'), findsOneWidget);
      expect(
        find.textContaining('OpenAI-compatible · http://127.0.0.1:8000/v1'),
        findsOneWidget,
      );
      expect(keyStore.keys.values.single, 'sk-test-123');
    });
  });

  testWidgets('scanned local server adds with one click, models included', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((_) => db),
            apiKeyStoreProvider.overrideWith((_) => _MemKeyStore()),
            scanHttpClientProvider.overrideWith(
              (_) => MockClient(
                (request) async => request.url.port == 8000
                    ? http.Response(
                        jsonEncode({
                          'data': [
                            {'id': 'glm-5'},
                          ],
                        }),
                        200,
                      )
                    : (throw http.ClientException('refused')),
              ),
            ),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Add connection'));
      await settle(tester);

      expect(find.textContaining('localhost:8000 · 1 model'), findsOneWidget);
      expect(find.textContaining('not running'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Add').first);
      await settle(tester);

      final rows = await db.watchConnections().first;
      expect(rows.single.label, 'oMLX');
      expect(rows.single.baseUrl, 'http://127.0.0.1:8000/v1');
      expect(await db.modelsFor(rows.single.id), ['glm-5']);
    });
  });

  testWidgets('hosted preset adds OpenRouter with only a key', (tester) async {
    await runWithDb(tester, (db) async {
      final keyStore = _MemKeyStore();
      await pump(tester, db, keyStore);
      await tester.tap(find.text('Add connection'));
      await settle(tester);

      await tester.ensureVisible(find.text('OpenRouter'));
      await settle(tester);
      await tester.tap(find.text('OpenRouter'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'OpenRouter API key'),
        'sk-or-abc',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await settle(tester);

      // Row created with the baked-in URL, key keychained, models fetched
      // automatically via the stub factory — no Test step needed.
      expect(find.textContaining('openrouter.ai/api/v1'), findsOneWidget);
      expect(keyStore.keys.values.single, 'sk-or-abc');
      final rows = await db.watchConnections().first;
      expect(rows.single.label, 'OpenRouter');
      expect(await db.modelsFor(rows.single.id), hasLength(3));
    });
  });

  testWidgets('test button fetches and caches the model list', (tester) async {
    await runWithDb(tester, (db) async {
      await _seedOmlx(db);
      await pump(tester, db, _MemKeyStore());

      await tester.tap(find.text('Test'));
      await settle(tester);

      expect(find.text('3 models'), findsOneWidget);
      expect(find.textContaining('3 models cached'), findsOneWidget);
      expect(await db.modelsFor('omlx'), hasLength(3));
    });
  });

  testWidgets('failed test surfaces without crashing', (tester) async {
    await runWithDb(tester, (db) async {
      await _seedOmlx(db, id: 'bad');
      await pump(tester, db, _MemKeyStore(), failTest: true);

      await tester.tap(find.text('Test'));
      await settle(tester);

      expect(find.text('Failed'), findsOneWidget);
    });
  });

  testWidgets('delete confirms, removes row, and drops the stored key', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final keyStore = _MemKeyStore()..keys['omlx'] = 'sk-old';
      await _seedOmlx(db);
      await pump(tester, db, keyStore);

      await tester.tap(find.byTooltip('Delete'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(find.text('No provider connections yet.'), findsOneWidget);
      expect(keyStore.keys, isEmpty);
    });
  });

  testWidgets('edit keeps the id and updates the label', (tester) async {
    await runWithDb(tester, (db) async {
      await _seedOmlx(db);
      await pump(tester, db, _MemKeyStore());

      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Label'),
        'oMLX (M3 Ultra)',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('oMLX (M3 Ultra)'), findsOneWidget);
      final rows = await db.watchConnections().first;
      expect(rows.single.id, 'omlx');
    });
  });
}
