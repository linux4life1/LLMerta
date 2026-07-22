import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/home/home.dart';
import 'package:llmerta_app/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) =>
      tester.pumpWidget(const ProviderScope(child: LlmertaApp()));

  testWidgets('home shows the wordmark and every menu action', (tester) async {
    await pumpApp(tester);
    expect(find.text('LLMerta'), findsOneWidget);
    for (final action in HomeAction.values) {
      expect(find.text(action.label), findsOneWidget);
    }
  });

  testWidgets('actions without a backing feature stay disabled', (
    tester,
  ) async {
    await pumpApp(tester);
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

  for (final (action, marker) in [
    (HomeAction.newGame, 'Game Setup'),
    (HomeAction.settings, 'arrive with M3.2'),
    (HomeAction.replays, 'once saves exist'),
  ]) {
    testWidgets('${action.label} navigates to its screen', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(action.label));
      await tester.pumpAndSettle();
      expect(find.textContaining(marker), findsOneWidget);
    });
  }
}
