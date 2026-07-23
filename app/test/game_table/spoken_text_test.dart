import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/game_table/game_table.dart';

void main() {
  test('revealCut advances word by word, proportional to characters', () {
    const text = 'one two three four';
    expect(revealCut(text, 0), 0);
    expect(revealCut(text, 1), text.length);
    expect(revealCut(text, 2), text.length);
    // Halfway lands on a word boundary at or before the midpoint.
    final half = revealCut(text, 0.5);
    expect(half, lessThanOrEqualTo(9));
    expect(half == 0 || text[half - 1] == ' ', isTrue);
    // A single word has no boundary to respect.
    expect(revealCut('supercalifragilistic', 0.5), greaterThan(0));
  });

  testWidgets('words fade in across the audio duration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpokenText(
            text: 'the town sleeps but I never do tonight',
            startedAt: DateTime.now(),
            duration: const Duration(seconds: 2),
          ),
        ),
      ),
    );
    Text visible() => tester.widget<Text>(find.byType(Text));
    TextSpan span() => visible().textSpan! as TextSpan;
    String revealed() => (span().children!.first as TextSpan).text!;

    await tester.pump(const Duration(milliseconds: 100));
    final early = revealed().length;
    await tester.pump(const Duration(seconds: 1));
    final mid = revealed().length;
    await tester.pump(const Duration(seconds: 2));
    final done = revealed().length;

    expect(early, lessThanOrEqualTo(mid));
    expect(mid, lessThan(done));
    expect(done, 'the town sleeps but I never do tonight'.length);
  });

  testWidgets('reduced motion shows the full line immediately', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SpokenText(
              text: 'no animation here',
              startedAt: DateTime.now(),
              duration: const Duration(seconds: 5),
            ),
          ),
        ),
      ),
    );
    expect(find.text('no animation here'), findsOneWidget);
  });
}
