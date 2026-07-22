import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/home/home.dart';
import 'package:llmerta_app/main.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';

import 'support.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    AppDatabase db, {
    bool firstRunSeen = true,
  }) async {
    if (firstRunSeen) await db.setPref('firstRunSeen', 'true');
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

  testWidgets('Continue stays disabled without a save', (tester) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Continue'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('How to play opens the rules primer', (tester) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      await tester.tap(find.text('How to play'));
      await settle(tester);
      expect(find.text('How LLMerta is played'), findsOneWidget);
      expect(
        find.textContaining('one bullet for the whole game'),
        findsOneWidget,
      );
    });
  });

  testWidgets('first run offers the welcome setup exactly once', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db, firstRunSeen: false);
      expect(find.text('Welcome to LLMerta'), findsOneWidget);
      await tester.tap(find.text("I'm set"));
      await settle(tester);
      expect(find.text('Welcome to LLMerta'), findsNothing);
      expect(await db.pref('firstRunSeen'), 'true');

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, db, firstRunSeen: false);
      expect(find.text('Welcome to LLMerta'), findsNothing);
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
