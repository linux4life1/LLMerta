import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llmerta_app/game_table/game_table.dart';

const _names = ['Sosuke', 'Edda', 'Alma', 'Jonas', 'Greta', 'Marlowe', 'Vex'];

TableViewState _fold(List<GameEvent> events) =>
    buildTableView(events, humanSeat: 0, names: _names);

void main() {
  test('night and day phases drive banner, mood, and cleared speech', () {
    var view = _fold(const [GameStarted(seats: 7), NightBegan(0)]);
    expect(view.night, isTrue);
    expect(view.banner, contains('Night 0'));

    view = _fold(const [
      GameStarted(seats: 7),
      NightBegan(0),
      DayBegan(1),
      SpeechGiven(seat: 2, text: 'I heard footsteps.'),
    ]);
    expect(view.night, isFalse);
    expect(view.banner, 'Day 1 — discussion');
    expect(view.activeSpeech, (2, 'I heard footsteps.'));

    view = _fold(const [
      GameStarted(seats: 7),
      DayBegan(1),
      SpeechGiven(seat: 2, text: 'x'),
      NightBegan(1),
    ]);
    expect(view.activeSpeech, isNull);
    expect(view.banner, contains('the town sleeps'));
  });

  test('deaths, reveals, and the human role card accumulate', () {
    final view = _fold(const [
      GameStarted(seats: 7),
      RoleReceived(seat: 0, role: Role.sheriff),
      RoleReceived(seat: 3, role: Role.mafioso),
      DayBegan(1),
      DawnAnnounced(deaths: [4], revealedRoles: {4: Role.doctor}),
    ]);
    expect(view.humanRole, Role.sheriff);
    expect(view.dead, {4});
    expect(view.revealedRoles[4], Role.doctor);
    expect(view.isAlive(4), isFalse);
    expect(view.isAlive(3), isTrue);
    expect(view.narratorLine, isNotNull);
  });

  test('trial, votes, verdict lifecycle', () {
    const base = [
      GameStarted(seats: 7),
      DayBegan(2),
      TrialStarted([1, 5]),
    ];
    var view = _fold(base);
    expect(view.onTrial, {1, 5});
    expect(view.banner, 'Day 2 — the trial');

    view = _fold([
      ...base,
      const DefenseGiven(seat: 1, text: 'This is a stitch-up.'),
      const VotesRevealed({0: 1, 2: 1, 3: null, 4: 5}),
    ]);
    expect(view.activeSpeech, (1, 'This is a stitch-up.'));
    expect(view.lastVotes[3], isNull);
    expect(view.lastVotes[0], 1);
    expect(view.banner, 'Day 2 — the verdict');

    view = _fold([
      ...base,
      const VotesRevealed({0: 1}),
      const Verdict(eliminated: 1, revealedRole: Role.mafioso),
    ]);
    expect(view.dead, contains(1));
    expect(view.revealedRoles[1], Role.mafioso);
    expect(view.onTrial, isEmpty);
  });

  test('assassin bullet fold: spent night recorded, unspent while held', () {
    var view = _fold(const [
      GameStarted(seats: 7),
      RoleReceived(seat: 0, role: Role.assassin),
      NightBegan(2),
      AssassinDecided(assassin: 0, target: null),
    ]);
    expect(view.humanBulletSpent, isFalse);

    view = _fold(const [
      GameStarted(seats: 7),
      RoleReceived(seat: 0, role: Role.assassin),
      NightBegan(2),
      AssassinDecided(assassin: 0, target: 3),
    ]);
    expect(view.humanBulletSpent, isTrue);
    expect(view.bulletSpentNight, 2);
  });

  test('mafia team visibility and game end', () {
    final view = _fold(const [
      GameStarted(seats: 7),
      MafiaTeamRevealed({2, 5}),
      GameEnded(winner: Faction.mafia),
    ]);
    expect(view.mafiaTeam, {2, 5});
    expect(view.over, isTrue);
    expect(view.winner, Faction.mafia);
    expect(view.banner, contains('mafia owns'));
  });
}
