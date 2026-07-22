import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';

class _MemKeyStore implements ApiKeyStore {
  @override
  Future<String?> read(String id) async => null;

  @override
  Future<void> write(String id, String apiKey) async {}

  @override
  Future<void> delete(String id) async {}
}

class _StubChat implements ChatProvider {
  const _StubChat(this.models);

  final List<String> models;

  @override
  Future<List<String>> listModels() async => models;

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

void main() {
  const catalog = ['x-ai/grok-4.3', 'anthropic/claude-fable-5', 'z-ai/glm-5'];

  Future<void> pumpField(
    WidgetTester tester,
    AppDatabase db, {
    required ValueChanged<String> onPicked,
  }) async {
    await db.upsertConnection(
      ConnectionsCompanion.insert(
        id: 'or',
        label: 'OpenRouter',
        kind: ProviderKind.openaiCompat,
        baseUrl: 'https://openrouter.ai/api/v1',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          apiKeyStoreProvider.overrideWith((_) => _MemKeyStore()),
          clientFactoryProvider.overrideWith(
            (_) =>
                (connection, apiKey) => const _StubChat(catalog),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: ModelPickerField(
                  connectionId: 'or',
                  model: null,
                  onPicked: onPicked,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('empty cache offers a fetch, then search filters the list', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      String? picked;
      await pumpField(tester, db, onPicked: (m) => picked = m);

      await tester.tap(find.byType(ModelPickerField));
      await settle(tester);
      expect(find.text('Pick a model'), findsOneWidget);
      expect(
        find.text('No model list cached for this connection yet.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Fetch models'));
      await settle(tester);
      expect(find.text('z-ai/glm-5'), findsOneWidget);
      expect(await db.modelsFor('or'), hasLength(3));

      await tester.enterText(find.byType(TextField).first, 'grok');
      await settle(tester);
      expect(find.text('z-ai/glm-5'), findsNothing);

      await tester.tap(find.text('x-ai/grok-4.3'));
      await settle(tester);
      expect(picked, 'x-ai/grok-4.3');
      expect(find.text('Pick a model'), findsNothing);
    });
  });

  testWidgets('a search with no hits says so instead of an empty pane', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await pumpField(tester, db, onPicked: (_) {});
      await db.replaceModels('or', catalog);
      await settle(tester);
      await tester.tap(find.byType(ModelPickerField));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'mistral');
      await settle(tester);
      expect(find.text('No model matches.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
    });
  });
}
