import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('home shows the wordmark, primary action, and quiet links', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      expect(find.text('LLMerta'), findsOneWidget);
      expect(find.text('NEW GAME'), findsOneWidget);
      expect(find.text('Replays'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('How to play'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  testWidgets('Continue is absent entirely without a save', (tester) async {
    await runWithDb(tester, (db) async {
      await pumpApp(tester, db);
      expect(find.textContaining('Continue'), findsNothing);
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

  for (final (label, marker) in [
    ('NEW GAME', 'Game Setup'),
    ('Settings', 'No provider connections yet.'),
    ('Replays', 'No games on the shelf'),
  ]) {
    testWidgets('$label navigates to its screen', (tester) async {
      await runWithDb(tester, (db) async {
        await pumpApp(tester, db);
        await tester.tap(find.text(label));
        await settle(tester);
        expect(find.textContaining(marker), findsOneWidget);
      });
    });
  }
}
