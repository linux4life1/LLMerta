import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/reveal/reveal.dart';
import 'package:llmerta_app/theme/theme.dart';

void main() {
  for (final (name, route, marker) in [
    ('game table', GameTableScreen.route, 'No game running'),
    ('reveal', RevealScreen.route, 'The Reveal'),
  ]) {
    testWidgets('$name route builds its placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: LlmertaTheme.day,
            home: Builder(
              builder: (context) => FilledButton(
                onPressed: () => Navigator.of(context).push(route()),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.textContaining(marker), findsOneWidget);
    });
  }
}
