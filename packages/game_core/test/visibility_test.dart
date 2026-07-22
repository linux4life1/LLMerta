import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  const events = <GameEvent>[
    GameStarted(seats: 7),
    RolesDealt({0: Role.mafioso, 1: Role.villager}),
    RoleReceived(seat: 1, role: Role.villager),
    MafiaTeamRevealed({0}),
    MafiaChatSaid(seat: 0, text: 'psst'),
    SheriffInvestigated(sheriff: 2, target: 0, foundMafia: true),
    SpeechGiven(seat: 1, text: 'hello'),
  ];

  test('public events reach everyone', () {
    for (final seat in [0, 1, 2]) {
      final visible = events.visibleTo(seat, isMafia: seat == 0);
      expect(visible, contains(events.first));
      expect(visible.whereType<SpeechGiven>(), isNotEmpty);
    }
  });

  test('omniscient events reach nobody', () {
    for (final seat in [0, 1, 2]) {
      expect(
        events.visibleTo(seat, isMafia: seat == 0).whereType<RolesDealt>(),
        isEmpty,
      );
    }
  });

  test('mafia events reach only mafia seats', () {
    expect(
      events.visibleTo(0, isMafia: true).whereType<MafiaChatSaid>(),
      hasLength(1),
    );
    expect(
      events.visibleTo(1, isMafia: false).whereType<MafiaChatSaid>(),
      isEmpty,
    );
  });

  test('private events reach exactly their seat', () {
    expect(
      events.visibleTo(2, isMafia: false).whereType<SheriffInvestigated>(),
      hasLength(1),
    );
    for (final other in [0, 1]) {
      expect(
        events
            .visibleTo(other, isMafia: other == 0)
            .whereType<SheriffInvestigated>(),
        isEmpty,
      );
    }
  });
}
