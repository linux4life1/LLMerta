import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia_app/home/home.dart';
import 'package:mafia_app/main.dart';

void main() {
  testWidgets('home shows the wordmark and every menu action', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MafiaApp()));
    expect(find.text('MAFIA'), findsOneWidget);
    for (final action in HomeAction.values) {
      expect(find.text(action.label), findsOneWidget);
    }
  });
}
