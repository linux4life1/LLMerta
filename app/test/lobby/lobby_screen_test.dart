import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          fpaBackgroundsDirProvider.overrideWith((_) => null),
        ],
        child: const MaterialApp(home: LobbyScreen()),
      ),
    );
    await settle(tester);
    return ProviderScope.containerOf(tester.element(find.byType(LobbyScreen)));
  }

  Future<void> seedCastReady(AppDatabase db, ProviderContainer c) async {
    await db.upsertConnection(
      ConnectionsCompanion.insert(
        id: 'omlx',
        label: 'oMLX',
        kind: ProviderKind.openaiCompat,
        baseUrl: 'http://127.0.0.1:8000/v1',
      ),
    );
    await db.replaceModels('omlx', ['glm-5']);
    c.read(lobbySetupControllerProvider.notifier)
      ..castAllSeats(connectionId: 'omlx', model: 'glm-5')
      ..shufflePersonas([for (final p in personaLibrary) p.name]);
  }

  testWidgets('renders town name, config panel, and one card per AI seat', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final c = await pump(tester, db);
      final setup = c.read(lobbySetupControllerProvider);
      expect(find.text('Game Setup — ${setup.townName}'), findsOneWidget);
      expect(find.text('Casual'), findsOneWidget);
      expect(find.textContaining('seats at the table'), findsOneWidget);
      expect(find.textContaining('You — Seat 1'), findsOneWidget);
      expect(find.textContaining('Seat '), findsWidgets);
      expect(find.text('Deal the cards'), findsOneWidget);
    });
  });

  testWidgets('re-roll changes the town name', (tester) async {
    await runWithDb(tester, (db) async {
      final c = await pump(tester, db);
      final before = c.read(lobbySetupControllerProvider).townName;
      await tester.tap(find.byTooltip('Re-roll town name'));
      await settle(tester);
      final after = c.read(lobbySetupControllerProvider).townName;
      expect(after, isNot(before));
      expect(find.text('Game Setup — $after'), findsOneWidget);
    });
  });

  testWidgets('difficulty, grudge, scene, and slider bind to setup state', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final c = await pump(tester, db);

      await tester.tap(find.text('Cutthroat'));
      await settle(tester);
      expect(
        c.read(lobbySetupControllerProvider).difficulty,
        Difficulty.cutthroat,
      );

      await tester.tap(find.text('Grudge memory'));
      await settle(tester);
      expect(c.read(lobbySetupControllerProvider).grudgeMode, isFalse);

      await tester.tap(find.text('Neon District'));
      await settle(tester);
      expect(
        c.read(lobbySetupControllerProvider).scene,
        const BuiltInScene(BuiltInSceneId.neonDistrict),
      );

      await tester.drag(find.byType(Slider).first, const Offset(300, 0));
      await settle(tester);
      expect(c.read(lobbySetupControllerProvider).config.seats, 14);
    });
  });

  testWidgets('house rules toggles update the game config', (tester) async {
    await runWithDb(tester, (db) async {
      final c = await pump(tester, db);
      await tester.tap(find.text('House rules'));
      await settle(tester);
      await tester.ensureVisible(find.text('Sheriff peeks on Night 0'));
      await settle(tester);
      await tester.tap(find.text('Sheriff peeks on Night 0'));
      await settle(tester);
      expect(
        c.read(lobbySetupControllerProvider).config.night0SheriffPeek,
        isTrue,
      );
    });
  });

  testWidgets('human persona menu offers customs only, never the house', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await db.upsertPersona(
        CustomPersonasCompanion.insert(
          name: 'Vex',
          archetype: 'switchboard operator',
          style: 'clipped',
          quirk: 'listens in',
        ),
      );
      await pump(tester, db);
      await tester.tap(find.text('Your persona (optional)'));
      await settle(tester);
      expect(find.text('Vex'), findsWidgets);
      expect(find.text('Just yourself'), findsWidgets);
      for (final house in personaLibrary.take(3)) {
        expect(find.text(house.name), findsNothing);
      }
    });
  });

  testWidgets(
    'cast-ready lobby enables Deal and opens the table',
    (tester) async {
      await runWithDb(tester, (db) async {
        final c = await pump(tester, db);
        await seedCastReady(db, c);
        await settle(tester);

        FilledButton dealButton() => tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Deal the cards'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(dealButton().onPressed, isNull);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Your name'),
          'Sosuke',
        );
        await settle(tester);
        expect(dealButton().onPressed, isNotNull);

        await tester.tap(find.text('Deal the cards'));
        await settle(tester);
        expect(find.textContaining('The table is being set'), findsOneWidget);
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets('bulk bar casts every seat from the dropdown picks', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await db.upsertConnection(
        ConnectionsCompanion.insert(
          id: 'omlx',
          label: 'oMLX',
          kind: ProviderKind.openaiCompat,
          baseUrl: 'http://127.0.0.1:8000/v1',
        ),
      );
      await db.replaceModels('omlx', ['glm-5', 'qwen-3.6']);
      final c = await pump(tester, db);

      await tester.tap(
        find.descendant(
          of: find.byType(Card).at(1),
          matching: find.text('Connection'),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('oMLX').last);
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(Card).at(1),
          matching: find.text('Model'),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('glm-5').last);
      await settle(tester);
      await tester.tap(find.text('Cast all seats'));
      await settle(tester);

      final setup = c.read(lobbySetupControllerProvider);
      for (final s in setup.aiSeats) {
        expect(setup.seats[s].model, 'glm-5');
      }
    });
  });
}
