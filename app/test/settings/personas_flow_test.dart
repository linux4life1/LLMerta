import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';

Map<String, Object> _card(String name, String description) => {
  'spec': 'chara_card_v2',
  'spec_version': '2.0',
  'data': {
    'name': name,
    'description': description,
    'personality': 'observant, dry-witted',
    'mes_example': '<START>{{char}}: The night keeps its own ledger.',
    'first_mes': 'hello',
  },
};

void main() {
  late Directory cardsDir;
  String? pickedFile;

  setUp(() async {
    cardsDir = await Directory.systemTemp.createTemp('llmerta-cards');
    File('${cardsDir.path}/seraphina.json').writeAsStringSync(
      jsonEncode(_card('Seraphina', 'a wandering herbalist')),
    );
    pickedFile = null;
  });
  tearDown(() => cardsDir.delete(recursive: true));

  Future<void> pump(
    WidgetTester tester,
    AppDatabase db, {
    bool withFpa = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          fpaCharacterDirProvider.overrideWith(
            (_) => withFpa ? cardsDir : null,
          ),
          cardFilePickerProvider.overrideWith(
            (_) =>
                () async => pickedFile,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: PersonasSection())),
      ),
    );
    await settle(tester);
  }

  testWidgets('house library lists shipped personas read-only', (tester) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db);
      expect(find.textContaining('House library ('), findsOneWidget);
      expect(find.text('House'), findsWidgets);
    });
  });

  testWidgets('FPA one-click import pulls the whole card folder', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db);
      await tester.tap(find.textContaining('Import from Front Porch'));
      await settle(tester);

      expect(find.text('Imported 1 personas.'), findsOneWidget);
      expect(find.text('Imported & custom'), findsOneWidget);
      expect(find.text('Seraphina'), findsOneWidget);
    });
  });

  testWidgets('FPA button hidden without a detected install', (tester) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db, withFpa: false);
      expect(find.textContaining('Import from Front Porch'), findsNothing);
    });
  });

  testWidgets('single card import goes through the picker seam', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      final file = File('${cardsDir.path}/marlowe.json')
        ..writeAsStringSync(jsonEncode(_card('Marlowe', 'a dockside fixer')));
      pickedFile = file.path;
      await pump(tester, db);

      await tester.tap(find.text('Import card…'));
      await settle(tester);

      expect(find.text('Marlowe'), findsOneWidget);
    });
  });

  testWidgets('cancelled picker leaves state untouched', (tester) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db);
      await tester.tap(find.text('Import card…'));
      await settle(tester);
      expect(find.text('Imported & custom'), findsNothing);
    });
  });

  testWidgets('create, edit, and delete a custom persona', (tester) async {
    await runWithDb(tester, (db) async {
      await pump(tester, db);

      await tester.tap(find.text('New persona'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Vex');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Archetype (e.g. retired judge)'),
        'switchboard operator',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Speech style'),
        'clipped',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quirk'),
        'listens in',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('Vex'), findsOneWidget);
      expect(find.text('switchboard operator'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      expect(
        tester
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Name'))
            .enabled,
        isFalse,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Archetype (e.g. retired judge)'),
        'night operator',
      );
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('night operator'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove'));
      await settle(tester);
      expect(find.text('Vex'), findsNothing);
    });
  });
}
