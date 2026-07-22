import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';

class _FakeGameSession extends GameSessionController {
  var started = false;

  @override
  GameSession build() => const GameSession();

  @override
  Future<void> startFromLobby() async {
    started = true;
  }
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    AppDatabase db, {
    List<FpPersona> fpPersonas = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          fpaBackgroundsDirProvider.overrideWith((_) => null),
          fpaPersonasProvider.overrideWith((_) => fpPersonas),
          gameSessionControllerProvider.overrideWith(_FakeGameSession.new),
          humanRequestProvider.overrideWith((_) => Stream.value(null)),
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

  testWidgets('Play as lists FP personas, prefills the name, never house', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final c = await pump(
        tester,
        db,
        fpPersonas: const [
          FpPersona(id: 'p1', name: 'Linus', title: 'Tech-Bro'),
          FpPersona(id: 'p2', name: 'Linus', title: 'Crime'),
        ],
      );
      await tester.tap(find.text('Play as'));
      await settle(tester);
      expect(find.text('Linus — Tech-Bro'), findsWidgets);
      expect(find.text('Just yourself'), findsWidgets);
      for (final house in personaLibrary.take(3)) {
        expect(find.text(house.name), findsNothing);
      }
      await tester.tap(find.text('Linus — Tech-Bro').last);
      await settle(tester);
      final setup = c.read(lobbySetupControllerProvider);
      expect(setup.humanPersona?.id, 'p1');
      expect(setup.humanName, 'Linus');
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
        expect(find.byType(GameTableScreen), findsOneWidget);
        final fake =
            c.read(gameSessionControllerProvider.notifier) as _FakeGameSession;
        expect(fake.started, isTrue);
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets('bulk bar casts every seat via the searchable model picker', (
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
      // Searchable picker dialog: filter, then choose.
      expect(find.text('Pick a model'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'glm');
      await settle(tester);
      expect(find.text('qwen-3.6'), findsNothing);
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
