import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistence/persistence.dart';

/// Drift schedules real timers that the widget-test fake zone can't see;
/// any test touching the DB must run its whole body under [WidgetTester.runAsync]
/// and close the DB before returning, or the binding's `!timersPending`
/// invariant trips and each affected file drains the 10-minute suite timeout.
Future<void> runWithDb(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) body,
) async {
  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() async {
    try {
      await body(db);
    } finally {
      // Unmount before the binding's end-of-test verification: widgets
      // holding SemanticsHandles (and provider subscriptions) dispose here.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    }
  });
}

/// pumpAndSettle replacement for runAsync bodies: real delays let drift
/// emit, pumped durations advance route/dialog animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
