import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llmerta_app/home/home.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:persistence/persistence.dart';

import '../support.dart';
import 'update_logic_test.dart' show release;

http.Client github(List<Map<String, Object?>> releases) =>
    MockClient((request) async {
      if (request.url.host == 'api.github.com') {
        return http.Response(
          jsonEncode(releases),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response.bytes(const [7, 7, 7, 7], 200);
    });

void main() {
  setUp(() => UpdateController.supportedOverride = true);
  tearDown(() => UpdateController.supportedOverride = null);

  ProviderContainer harness(http.Client client, {String current = '0.1.0'}) {
    final container = ProviderContainer(
      overrides: [
        scanHttpClientProvider.overrideWith((_) => client),
        appVersionProvider.overrideWith((_) async => current),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'check finds a newer release and download stages the installer',
    () async {
      final c = harness(github([release('v0.1.1')]));
      final controller = c.read(updateControllerProvider.notifier);

      await controller.check();
      var state = c.read(updateControllerProvider);
      expect(state.phase, UpdatePhase.available);
      expect(state.latest?.version, '0.1.1');

      await controller.download();
      state = c.read(updateControllerProvider);
      expect(state.phase, UpdatePhase.ready);
      expect(controller.installerPath, isNotNull);
      final staged = File(controller.installerPath!);
      expect(staged.readAsBytesSync(), const [7, 7, 7, 7]);
      staged.deleteSync();
    },
  );

  test('an equal or older release means up to date', () async {
    final c = harness(github([release('v0.1.0')]));
    await c.read(updateControllerProvider.notifier).check();
    final state = c.read(updateControllerProvider);
    expect(state.phase, UpdatePhase.upToDate);
    expect(state.latest, isNull);
  });

  test('API failure surfaces as an error phase, not a crash', () async {
    final c = harness(
      MockClient((_) async => http.Response('rate limit', 403)),
    );
    await c.read(updateControllerProvider.notifier).check();
    expect(c.read(updateControllerProvider).phase, UpdatePhase.error);
  });

  test('unsupported builds never check', () async {
    UpdateController.supportedOverride = false;
    final c = harness(github([release('v9.9.9')]));
    final controller = c.read(updateControllerProvider.notifier);
    await controller.check();
    await controller.autoCheckOnLaunch();
    expect(c.read(updateControllerProvider).phase, UpdatePhase.idle);
  });

  test('auto-check pref persists and gates the launch check', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        scanHttpClientProvider.overrideWith((_) => github([release('v0.1.1')])),
        appVersionProvider.overrideWith((_) async => '0.1.0'),
      ],
    );
    addTearDown(c.dispose);
    final controller = c.read(updateControllerProvider.notifier);

    await controller.setAutoCheck(false);
    expect(await db.pref(updateAutoCheckPrefKey), 'false');
    await controller.autoCheckOnLaunch();
    expect(c.read(updateControllerProvider).phase, UpdatePhase.idle);

    await controller.setAutoCheck(true);
    await controller.autoCheckOnLaunch();
    expect(c.read(updateControllerProvider).phase, UpdatePhase.available);
  });

  testWidgets('updates section walks check → download → restart-ready', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((_) => db),
            scanHttpClientProvider.overrideWith(
              (_) => github([release('v0.1.1')]),
            ),
            appVersionProvider.overrideWith((_) async => '0.1.0'),
          ],
          child: const MaterialApp(home: Scaffold(body: UpdatesSection())),
        ),
      );
      await settle(tester);
      expect(find.text('LLMerta v0.1.0'), findsOneWidget);

      await tester.tap(find.text('Check now'));
      await settle(tester);
      expect(find.text('v0.1.1 is out'), findsOneWidget);
      expect(find.textContaining('notes for v0.1.1'), findsOneWidget);

      await tester.tap(find.text('Download update'));
      await settle(tester);
      expect(find.text('Restart & update'), findsOneWidget);

      final element = tester.element(find.byType(UpdatesSection));
      final controller = ProviderScope.containerOf(
        element,
      ).read(updateControllerProvider.notifier);
      final staged = controller.installerPath;
      expect(staged, isNotNull);
      File(staged!).deleteSync();
    });
  });

  testWidgets('home shows the update chip once something is ready', (
    tester,
  ) async {
    await runWithDb(tester, (db) async {
      await db.setPref('firstRunSeen', 'true');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((_) => db),
            scanHttpClientProvider.overrideWith(
              (_) => github([release('v0.1.1')]),
            ),
            appVersionProvider.overrideWith((_) async => '0.1.0'),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      // The post-frame launch auto-check runs against the mocked GitHub —
      // the chip appears without any manual action.
      await settle(tester);
      expect(find.text('Update ready — v0.1.1'), findsOneWidget);
    });
  });
}
