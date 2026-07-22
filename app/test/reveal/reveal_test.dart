import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/game_table/game_table.dart';
import 'package:llmerta_app/reveal/reveal.dart';

const _names = ['Sosuke', 'Edda', 'Alma', 'Jonas', 'Greta', 'Marlowe', 'Vex'];

const _events = <GameEvent>[
  GameStarted(seats: 7),
  RolesDealt({
    0: Role.sheriff,
    1: Role.mafioso,
    2: Role.doctor,
    3: Role.mafioso,
    4: Role.assassin,
    5: Role.villager,
    6: Role.villager,
  }),
  MafiaTeamRevealed({1, 3}),
  NightBegan(1),
  MafiaChatSaid(seat: 1, text: 'The sheriff sleeps lightly.'),
  MafiaKillVoteCast(by: 1, target: 5),
  MafiaKillChosen(5),
  DoctorProtected(doctor: 2, target: 5),
  SheriffInvestigated(sheriff: 0, target: 3, foundMafia: true),
  AssassinDecided(assassin: 4, target: null),
  NightResolved(killed: [], saved: [5]),
  DayBegan(1),
  DawnAnnounced(deaths: [], revealedRoles: {}),
  GameEnded(winner: Faction.town),
];

class _TalkStub implements ChatProvider {
  @override
  Future<ChatResult> chat(
    List<ChatMessage> messages, {
    required String model,
    double temperature = 0.7,
    int maxTokens = 1024,
    JsonSchemaSpec? jsonSchema,
  }) async =>
      const ChatResult(text: 'Well played, town.', latency: Duration.zero);

  @override
  Future<List<String>> listModels() async => const ['stub'];

  @override
  ({int calls, int promptTokens, int completionTokens}) get usage =>
      (calls: 0, promptTokens: 0, completionTokens: 0);

  @override
  void close() {}
}

class _FakeRevealSession extends GameSessionController {
  _FakeRevealSession(this._session, this._events, this._backends);

  final GameSession _session;
  final List<GameEvent> _events;
  final Map<int, (ChatProvider, String)> _backends;

  @override
  GameSession build() => _session;

  @override
  List<GameEvent> get revealEvents => _events;

  @override
  Map<int, (ChatProvider, String)> get agentBackends => _backends;
}

void main() {
  test('revealLine tags every hidden event type', () {
    final lines = [
      for (final event in _events)
        if (revealLine(event, _names) case final String line) line,
    ];
    expect(
      lines.join('\n'),
      allOf([
        contains('[family] Edda: "The sheriff sleeps lightly."'),
        contains('[family] Edda marks Marlowe'),
        contains('[family] the kill settles on Marlowe'),
        contains('[doctor] Alma guards Marlowe'),
        contains('[sheriff] Sosuke investigates Jonas: MAFIA'),
        contains('[assassin] Greta holds fire'),
        contains('[night] killed: nobody — saved: Marlowe'),
        contains('[family] the members: Edda, Jonas'),
      ]),
    );
  });

  testWidgets('reveal shows winner, roles, record, and runs table talk', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSessionControllerProvider.overrideWith(
            () => _FakeRevealSession(
              GameSession(
                stage: GameStage.finished,
                names: _names,
                townName: 'Brasshollow',
                winner: Faction.town,
                visibleEvents: const [GameStarted(seats: 7)],
              ),
              _events,
              {1: (_TalkStub(), 'stub')},
            ),
          ),
        ],
        child: const MaterialApp(home: RevealScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('The town prevails.'), findsOneWidget);
    expect(find.text('Sosuke — sheriff'), findsOneWidget);
    expect(find.text('Edda — mafioso'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('[sheriff] Sosuke investigates'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('[sheriff] Sosuke investigates'),
      findsOneWidget,
    );

    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Well played, town.'), findsOneWidget);

    // The human's turn: input goes live, a sent line lands in the talk.
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'You had me fooled, Edda.');
    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('You had me fooled, Edda.'), findsOneWidget);
    expect(find.text('Another round'), findsOneWidget);
  });

  testWidgets('reveal before any finished game shows the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RevealScreen())),
    );
    await tester.pump();
    expect(find.textContaining('every secret opens up here'), findsOneWidget);
  });
}
