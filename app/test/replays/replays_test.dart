import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llmerta_app/replays/replays.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';

const _publicEvents = <GameEvent>[
  GameStarted(seats: 7),
  RolesDealt({0: Role.villager, 1: Role.mafioso}),
  DayBegan(1),
  SpeechGiven(seat: 1, text: 'A quiet night, was it not?'),
  GameEnded(winner: Faction.mafia),
];

GamesCompanion _row(
  String id, {
  required bool finished,
  String? winner,
  int minute = 0,
}) => GamesCompanion.insert(
  id: id,
  townName: 'Veilport',
  savedAt: DateTime(2026, 7, 22, 4, minute),
  finished: Value(finished),
  winner: Value(winner),
  humanSeat: 0,
  rngSeed: 7,
  difficulty: 'standard',
  namesJson: jsonEncode(const [
    'Sosuke',
    'Edda',
    'Alma',
    'Jonas',
    'Greta',
    'Marlowe',
    'Vex',
  ]),
  badgesJson: '{}',
  configJson: '{}',
  eventsJson: jsonEncode([for (final e in _publicEvents) eventToJson(e)]),
);

void main() {
  Future<void> pump(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
        child: const MaterialApp(home: ReplaysScreen()),
      ),
    );
    await settle(tester);
  }

  testWidgets('empty shelf invites playing', (tester) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db);
      expect(find.textContaining('No games on the shelf'), findsOneWidget);
    });
  });

  testWidgets('lists saves; only finished ones open; delete removes', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await db.upsertGame(_row('done', finished: true, winner: 'mafia'));
      await db.upsertGame(_row('live', finished: false, minute: 1));
      await pump(tester, db);

      expect(find.text('Veilport'), findsNWidgets(2));
      expect(find.textContaining('the mafia won'), findsOneWidget);
      expect(find.textContaining('In progress'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete save').first);
      await settle(tester);
      expect(find.text('Veilport'), findsOneWidget);
    });
  });

  testWidgets('viewer steps through the human-visible record', (tester) async {
    await runWithDb(tester, (db) async {
      await db.upsertGame(_row('done', finished: true, winner: 'mafia'));
      await pump(tester, db);

      await tester.tap(find.text('Veilport'));
      await settle(tester);
      expect(find.textContaining('— replay'), findsOneWidget);
      expect(find.textContaining('A quiet night, was it not?'), findsOneWidget);
      expect(find.textContaining('mafia wins'), findsOneWidget);

      await tester.tap(find.byTooltip('Back one event'));
      await settle(tester);
      expect(find.textContaining('mafia wins'), findsNothing);
      expect(find.textContaining('A quiet night'), findsOneWidget);

      await tester.tap(find.byTooltip('Forward one event'));
      await settle(tester);
      expect(find.textContaining('mafia wins'), findsOneWidget);
    });
  });
}
