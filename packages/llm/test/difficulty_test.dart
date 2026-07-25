import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

void main() {
  test('standard ships two discussion rounds and runoff ties', () {
    final config = Difficulty.standard.applyRules(const GameConfig(seats: 10));
    expect(config.discussionRounds, 2);
    expect(config.crossfireRounds, 1);
    expect(config.tieRule, TieRule.runoff);
    expect(config.mafiaCountDelta, 0);
    expect(config.night0SheriffPeek, isFalse);
  });

  test('casual softens the table for town', () {
    final config = Difficulty.casual.applyRules(const GameConfig(seats: 10));
    expect(config.discussionRounds, 2);
    expect(config.tieRule, TieRule.runoff);
    expect(config.mafiaCountDelta, -1);
    expect(config.night0SheriffPeek, isTrue);
    // 10 seats, baseline 3 mafia − 1 = 2.
    expect(
      rolesForConfig(config).where((r) => r == Role.mafioso).length,
      2,
    );
  });

  test('cutthroat keeps full mafia and no-elim ties', () {
    final config = Difficulty.cutthroat.applyRules(const GameConfig(seats: 10));
    expect(config.discussionRounds, 2);
    expect(config.crossfireRounds, 2);
    expect(config.tieRule, TieRule.noElimination);
    expect(config.mafiaCountDelta, 0);
  });

  test('applyRules preserves unrelated house toggles', () {
    final base = const GameConfig(
      seats: 9,
      includeAssassin: false,
      revealRolesOnDeath: false,
    );
    final config = Difficulty.standard.applyRules(base);
    expect(config.includeAssassin, isFalse);
    expect(config.revealRolesOnDeath, isFalse);
    expect(config.seats, 9);
  });

  test('system prompt carries persona budget and anti-herd guidance', () {
    const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];
    const builder = AgentPromptBuilder(
      names: names,
      difficulty: Difficulty.standard,
    );
    final ctx = DecisionContext(
      seat: 0,
      role: Role.villager,
      day: 1,
      visibleEvents: const [GameStarted(seats: 7), RoleReceived(seat: 0, role: Role.villager)],
      livingSeats: const [0, 1, 2, 3, 4, 5, 6],
    );
    final system = builder.system(ctx);
    expect(system, contains('at most one short colorful sentence'));
    expect(system, contains('first person only'));
    expect(system, contains('crossfire'));
  });

  test('mafia system prompt pushes fakeclaims', () {
    const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];
    const builder = AgentPromptBuilder(names: names);
    final ctx = DecisionContext(
      seat: 0,
      role: Role.mafioso,
      day: 1,
      visibleEvents: const [
        GameStarted(seats: 7),
        RoleReceived(seat: 0, role: Role.mafioso),
        MafiaTeamRevealed({0, 1}),
      ],
      livingSeats: const [0, 1, 2, 3, 4, 5, 6],
    );
    final system = builder.system(ctx);
    expect(system, contains('DECEPTION'));
    expect(system, contains('fakeclaim'));
  });

  test('situation digests prior speeches and flags live sheriff hits', () {
    const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];
    const builder = AgentPromptBuilder(names: names);
    final sheriffCtx = DecisionContext(
      seat: 6,
      role: Role.sheriff,
      day: 2,
      visibleEvents: const [
        GameStarted(seats: 7),
        RoleReceived(seat: 6, role: Role.sheriff),
        DayBegan(2),
        DawnAnnounced(deaths: [0], revealedRoles: {0: Role.villager}),
        SpeechGiven(seat: 1, text: 'Boris is the fire, not the firefighter.'),
        SpeechGiven(
          seat: 2,
          text: 'I agree Boris is the fire not the firefighter.',
        ),
        SheriffInvestigated(sheriff: 6, target: 3, foundMafia: true),
      ],
      livingSeats: const [1, 2, 3, 4, 5, 6],
    );
    final situation = builder.situation(sheriffCtx);
    expect(situation, contains('ALREADY SAID TODAY'));
    expect(situation, contains('fire, not the firefighter'));
    expect(situation, contains('URGENT SHERIFF CLAIM'));
    expect(situation, contains('Dmitri'));
    expect(situation, contains('claiming Sheriff'));
  });

  test('assassin situation surfaces private shot results', () {
    const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];
    const builder = AgentPromptBuilder(names: names);
    final ctx = DecisionContext(
      seat: 3,
      role: Role.assassin,
      day: 2,
      visibleEvents: const [
        GameStarted(seats: 7),
        RoleReceived(seat: 3, role: Role.assassin),
        AssassinDecided(assassin: 3, target: 1),
        AssassinShotResolved(
          assassin: 3,
          target: 1,
          killed: true,
          wasMafia: true,
        ),
      ],
      livingSeats: const [0, 2, 3, 4, 5, 6],
    );
    final situation = builder.situation(ctx);
    expect(situation, contains('Your past shots'));
    expect(situation, contains('MAFIA'));
    expect(situation, contains('bullet is spent'));
  });
}
