@Tags(['golden'])
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:llmerta_app/theme/theme.dart';
import 'package:persistence/persistence.dart';

const _names = ['Sosuke', 'Edda', 'Alma', 'Jonas', 'Greta', 'Marlowe', 'Vex'];

class _FakeSession extends GameSessionController {
  _FakeSession(this._session);

  final GameSession _session;

  @override
  GameSession build() => _session;
}

/// One composed state exercises every card variant at once: the human,
/// a speaker, a nominee on trial, a revealed corpse, mafia badges, and
/// vote badges (CLAUDE.md golden matrix).
GameSession _daySession() => const GameSession(
  stage: GameStage.running,
  names: _names,
  townName: 'Brasshollow',
  humanIsMafia: true,
  modelBadges: {
    1: 'glm-5',
    2: 'qwen-3.6',
    3: 'grok-4.3',
    4: 'haiku-4.5',
    5: 'glm-5',
    6: 'kimi-2.6',
  },
  visibleEvents: [
    GameStarted(seats: 7),
    RoleReceived(seat: 0, role: Role.mafioso),
    MafiaTeamRevealed({0, 3}),
    DayBegan(2),
    DawnAnnounced(deaths: [4], revealedRoles: {4: Role.doctor}),
    SpeechGiven(seat: 2, text: 'The bakery was dark all night, I swear it.'),
    TrialStarted([1, 5]),
    VotesRevealed({0: 1, 2: 1, 3: null, 5: 1, 6: 5}),
  ],
);

GameSession _nightSession() => const GameSession(
  stage: GameStage.running,
  names: _names,
  townName: 'Brasshollow',
  modelBadges: {
    1: 'glm-5',
    2: 'qwen-3.6',
    3: 'grok-4.3',
    4: 'haiku-4.5',
    5: 'glm-5',
    6: 'kimi-2.6',
  },
  visibleEvents: [
    GameStarted(seats: 7),
    RoleReceived(seat: 0, role: Role.villager),
    DayBegan(1),
    NightBegan(1),
  ],
);

void main() {
  Future<AppDatabase> pumpTable(
    WidgetTester tester,
    GameSession session,
    Size size, {
    TableMood mood = TableMood.day,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          gameSessionControllerProvider.overrideWith(
            () => _FakeSession(session),
          ),
          humanRequestProvider.overrideWith((_) => Stream.value(null)),
        ],
        child: const MaterialApp(home: GameTableScreen()),
      ),
    );
    ProviderScope.containerOf(
      tester.element(find.byType(GameTableScreen)),
    ).read(tableMoodControllerProvider.notifier).set(mood);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    return db;
  }

  testWidgets('game table day at default window', (tester) async {
    final db = await pumpTable(tester, _daySession(), const Size(1280, 800));
    await expectLater(
      find.byType(GameTableScreen),
      matchesGoldenFile('goldens/table_day_1280x800.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });

  testWidgets('game table day at minimum window', (tester) async {
    final db = await pumpTable(tester, _daySession(), const Size(800, 600));
    await expectLater(
      find.byType(GameTableScreen),
      matchesGoldenFile('goldens/table_day_800x600.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });

  testWidgets('game table night veil at default window', (tester) async {
    final db = await pumpTable(
      tester,
      _nightSession(),
      const Size(1280, 800),
      mood: TableMood.night,
    );
    await expectLater(
      find.byType(GameTableScreen),
      matchesGoldenFile('goldens/table_night_1280x800.png'),
    );
    // The night overlay owns a periodic timer — unmount before teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });
}
