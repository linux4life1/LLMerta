import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/home/home.dart';
import 'package:llmerta_app/main.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';

import 'support.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
        child: const LlmertaApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('home shows the wordmark and every menu action', (tester) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      expect(find.text('LLMerta'), findsOneWidget);
      for (final action in HomeAction.values) {
        expect(find.text(action.label), findsOneWidget);
      }
    });
  });

  testWidgets('actions without a backing feature stay disabled', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      for (final action in HomeAction.values.where((a) => !a.enabled)) {
        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text(action.label),
            matching: find.byType(FilledButton),
          ),
        );
        expect(button.onPressed, isNull, reason: action.label);
      }
    });
  });

  for (final (action, marker) in [
    (HomeAction.newGame, 'Game Setup'),
    (HomeAction.settings, 'No provider connections yet.'),
    (HomeAction.replays, 'once saves exist'),
  ]) {
    testWidgets('${action.label} navigates to its screen', (tester) async {
      await runWithDb(tester, (db) async {
        await pumpApp(tester, db);
        await tester.tap(find.text(action.label));
        await settle(tester);
        expect(find.textContaining(marker), findsOneWidget);
      });
    });
  }
}
