import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart' show Persona;
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/theme/theme.dart';

const _names = ['Sosuke', 'Edda', 'Alma', 'Jonas', 'Greta', 'Marlowe', 'Vex'];

class _FakeSession extends GameSessionController {
  _FakeSession(this._session);

  final GameSession _session;

  @override
  GameSession build() => _session;
}

GameSession _runningSession(List<GameEvent> events, {bool mafia = false}) =>
    GameSession(
      stage: GameStage.running,
      visibleEvents: events,
      names: _names,
      townName: 'Brasshollow',
      humanIsMafia: mafia,
      modelBadges: const {
        1: 'glm-5',
        2: 'qwen-3.6',
        3: 'grok-4.3',
        4: 'haiku-4.5',
        5: 'glm-5',
        6: 'glm-5',
      },
      personas: const {
        1: Persona(
          name: 'Edda',
          archetype: 'retired judge',
          style: 'clipped',
          quirk: 'quotes case law',
        ),
      },
    );

void main() {
  Future<void> pump(
    WidgetTester tester,
    GameSession session, {
    HumanRequest? request,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSessionControllerProvider.overrideWith(
            () => _FakeSession(session),
          ),
          humanRequestProvider.overrideWith((_) => Stream.value(request)),
        ],
        child: const MaterialApp(home: GameTableScreen()),
      ),
    );
    await tester.pump();
    // The drivable fake session never fires _onEvent, so mirror the mood
    // the folded events imply (the overlay hides the center stage at
    // night by design).
    final element = tester.element(find.byType(GameTableScreen));
    final view = ProviderScope.containerOf(element).read(tableViewProvider);
    ProviderScope.containerOf(element)
        .read(tableMoodControllerProvider.notifier)
        .set(view.night ? TableMood.night : TableMood.day);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('idle stage points back to the lobby', (tester) async {
    await pump(tester, const GameSession());
    expect(find.textContaining('No game running'), findsOneWidget);
  });

  testWidgets('running table shows banner, cards, badges, and you-marker', (
    tester,
  ) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        RoleReceived(seat: 0, role: Role.sheriff),
        DayBegan(1),
        SpeechGiven(seat: 2, text: 'The bakery was dark all night.'),
      ]),
    );
    expect(find.text('Day 1 — discussion'), findsWidgets);
    expect(find.text('Brasshollow'), findsOneWidget);
    for (final name in _names) {
      expect(find.text(name), findsWidgets);
    }
    expect(find.text('seat 1 · you'), findsOneWidget);
    expect(find.text('seat 2 · glm-5'), findsOneWidget);
    expect(find.text('You are the sheriff'), findsOneWidget);
    expect(find.text('The bakery was dark all night.'), findsOneWidget);
  });

  testWidgets('dead seats show departure and revealed role', (tester) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        DayBegan(2),
        DawnAnnounced(deaths: [4], revealedRoles: {4: Role.doctor}),
      ]),
    );
    expect(find.text('was doctor'), findsOneWidget);
  });

  testWidgets('mafia human sees teammate badges', (tester) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        MafiaTeamRevealed({0, 3}),
        NightBegan(0),
      ], mafia: true),
    );
    expect(find.byIcon(Icons.handshake), findsNWidgets(2));
  });

  testWidgets('transcript drawer opens with visible lines only', (
    tester,
  ) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        DayBegan(1),
        SpeechGiven(seat: 1, text: 'Order in the court.'),
      ]),
    );
    await tester.tap(find.byTooltip('Transcript'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Order in the court.'), findsWidgets);
  });

  testWidgets('speak request renders the text dock and completes', (
    tester,
  ) async {
    final request = HumanRequest(
      kind: HumanActionKind.speak,
      ctx: const DecisionContext(
        seat: 0,
        role: Role.villager,
        day: 1,
        visibleEvents: [],
        livingSeats: [0, 1, 2],
      ),
    );
    await pump(
      tester,
      _runningSession(const [GameStarted(seats: 7), DayBegan(1)]),
      request: request,
    );
    expect(find.textContaining("You're up"), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'I trust nobody.');
    await tester.tap(find.text('Speak'));
    expect(
      await request.result.timeout(const Duration(seconds: 1)),
      'I trust nobody.',
    );
  });

  testWidgets('assassin request offers hold-your-fire and confirm-to-fire', (
    tester,
  ) async {
    final request = HumanRequest(
      kind: HumanActionKind.assassinShoot,
      ctx: const DecisionContext(
        seat: 0,
        role: Role.assassin,
        day: 2,
        visibleEvents: [],
        livingSeats: [0, 1, 2],
      ),
      targets: const [1, 2],
    );
    await pump(
      tester,
      _runningSession(const [GameStarted(seats: 7), NightBegan(2)]),
      request: request,
    );
    expect(find.text('Hold your fire'), findsOneWidget);
    final fire = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Fire'),
    );
    expect(
      fire.onPressed,
      isNull,
      reason: 'no mis-click shot without a target',
    );
    await tester.tap(find.text('Hold your fire'));
    expect(await request.result.timeout(const Duration(seconds: 1)), isNull);
  });

  testWidgets('assassin firing takes select, Fire, and an explicit confirm', (
    tester,
  ) async {
    final request = HumanRequest(
      kind: HumanActionKind.assassinShoot,
      ctx: const DecisionContext(
        seat: 0,
        role: Role.assassin,
        day: 2,
        visibleEvents: [],
        livingSeats: [0, 1, 2],
      ),
      targets: const [1, 2],
    );
    await pump(
      tester,
      _runningSession(const [GameStarted(seats: 7), NightBegan(2)]),
      request: request,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Edda'));
    await tester.pump();
    await tester.tap(find.text('Fire'));
    await tester.pump();
    expect(
      find.textContaining('The bullet does not come back'),
      findsOneWidget,
    );
    expect(request.isSubmitted, isFalse, reason: 'confirm step must gate');

    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text('Hold your fire'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Edda'));
    await tester.pump();
    await tester.tap(find.text('Fire'));
    await tester.pump();
    await tester.tap(find.text('Confirm the shot'));
    expect(await request.result.timeout(const Duration(seconds: 1)), 1);
  });

  testWidgets('vote is two-step: locked only after a selection', (
    tester,
  ) async {
    final request = HumanRequest(
      kind: HumanActionKind.vote,
      ctx: const DecisionContext(
        seat: 0,
        role: Role.villager,
        day: 2,
        visibleEvents: [],
        livingSeats: [0, 1, 2],
      ),
      targets: const [1, 5],
    );
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        TrialStarted([1, 5]),
      ]),
      request: request,
    );
    final lock = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Lock vote'),
    );
    expect(lock.onPressed, isNull);
    expect(find.text('Abstain'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Marlowe'));
    await tester.pump();
    await tester.tap(find.text('Lock vote'));
    expect(await request.result.timeout(const Duration(seconds: 1)), 5);
  });

  testWidgets('mafia chat request shows the family panel and whispers', (
    tester,
  ) async {
    final request = HumanRequest(
      kind: HumanActionKind.mafiaChat,
      ctx: const DecisionContext(
        seat: 0,
        role: Role.mafioso,
        day: 1,
        visibleEvents: [],
        livingSeats: [0, 1, 2, 3],
      ),
    );
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        MafiaTeamRevealed({0, 3}),
        NightBegan(0),
        MafiaChatSaid(seat: 3, text: 'Watch the judge.'),
      ], mafia: true),
      request: request,
    );
    expect(find.textContaining('The family: Sosuke, Jonas'), findsOneWidget);
    expect(find.textContaining('Watch the judge.'), findsOneWidget);
    expect(find.text('Private — the town never hears this'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Agreed. Tomorrow.');
    await tester.tap(find.text('Speak'));
    expect(
      await request.result.timeout(const Duration(seconds: 1)),
      'Agreed. Tomorrow.',
    );
  });

  testWidgets('speak dock counts words and allows saying nothing', (
    tester,
  ) async {
    final request = HumanRequest(
      kind: HumanActionKind.speak,
      ctx: const DecisionContext(
        seat: 0,
        role: Role.villager,
        day: 1,
        visibleEvents: [],
        livingSeats: [0, 1, 2],
      ),
    );
    await pump(
      tester,
      _runningSession(const [GameStarted(seats: 7), DayBegan(1)]),
      request: request,
    );
    expect(find.text('0 words — aim for under 120'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'I saw the fog roll in');
    await tester.pump();
    expect(find.text('6 words — aim for under 120'), findsOneWidget);
    await tester.tap(find.text('Say nothing'));
    expect(await request.result.timeout(const Duration(seconds: 1)), '');
  });

  testWidgets('passive night shows the veil and uniform thinking dots', (
    tester,
  ) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        RoleReceived(seat: 0, role: Role.villager),
        NightBegan(1),
      ]),
    );
    expect(find.text(nightOverlayMessages.first), findsOneWidget);
    expect(find.text('· · ·'), findsNWidgets(7));
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(nightOverlayMessages[1]), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('spent assassin gets the one-time notice the next night', (
    tester,
  ) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        RoleReceived(seat: 0, role: Role.assassin),
        NightBegan(2),
        AssassinDecided(assassin: 0, target: 3),
        DayBegan(3),
        NightBegan(3),
      ]),
    );
    expect(find.textContaining('Your bullet is gone'), findsOneWidget);
    expect(find.textContaining('bullet spent'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dead human becomes a spectator', (tester) async {
    await pump(
      tester,
      _runningSession(const [
        GameStarted(seats: 7),
        DayBegan(2),
        DawnAnnounced(deaths: [0], revealedRoles: {0: Role.villager}),
      ]),
    );
    expect(find.textContaining('You watch from beyond'), findsOneWidget);
  });

  testWidgets('finished game offers the Reveal from the dock', (tester) async {
    await pump(
      tester,
      GameSession(
        stage: GameStage.finished,
        visibleEvents: const [
          GameStarted(seats: 7),
          GameEnded(winner: Faction.town),
        ],
        names: _names,
        townName: 'Brasshollow',
      ),
    );
    expect(find.text('The game is over.'), findsOneWidget);
    await tester.tap(find.text('The Reveal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('every secret opens up here'),
      findsOneWidget,
      reason: 'fake session has no engine, so the reveal shows its empty state',
    );
  });

  testWidgets('leave flow confirms and resets the session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSessionControllerProvider.overrideWith(
            () => _FakeSession(
              _runningSession(const [GameStarted(seats: 7), DayBegan(1)]),
            ),
          ),
          humanRequestProvider.overrideWith((_) => Stream.value(null)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () =>
                  Navigator.of(context).push(GameTableScreen.route()),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Leave the table'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save & leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.byType(GameTableScreen), findsNothing);
  });
}
