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

  testWidgets('Continue and How-to-play stay disabled without their backing', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      for (final label in const ['Continue', 'How to play']) {
        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FilledButton),
          ),
        );
        expect(button.onPressed, isNull, reason: label);
      }
    });
  });

  testWidgets('an unfinished save lights up Continue with its town', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await db.upsertGame(
        GamesCompanion.insert(
          id: 'g1',
          townName: 'Veilport',
          savedAt: DateTime(2026, 7, 22),
          humanSeat: 0,
          rngSeed: 7,
          difficulty: 'standard',
          namesJson: '[]',
          badgesJson: '{}',
          configJson: '{}',
          eventsJson: '[]',
        ),
      );
      await pumpApp(tester, db);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continue — Veilport'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  for (final (action, marker) in [
    (HomeAction.newGame, 'Game Setup'),
    (HomeAction.settings, 'No provider connections yet.'),
    (HomeAction.replays, 'No games on the shelf'),
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
