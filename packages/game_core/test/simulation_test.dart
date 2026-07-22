import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    '1000 scripted games terminate across all seat counts',
    () async {
      var town = 0;
      var mafia = 0;
      var draws = 0;
      for (var i = 0; i < 1000; i++) {
        final seats = minSeats + (i % (maxSeats - minSeats + 1));
        final result = await runScriptedGame(
          config: GameConfig(seats: seats),
          seed: i,
        );
        expect(
          result.events.whereType<GameEnded>(),
          hasLength(1),
          reason: 'game $i (seats $seats) must end exactly once',
        );
        switch (result.winner) {
          case Faction.town:
            town++;
          case Faction.mafia:
            mafia++;
          case null:
            draws++;
        }
      }
      // Random-legal play must produce both outcomes and essentially
      // never stall into the backstop.
      expect(town, greaterThan(0));
      expect(mafia, greaterThan(0));
      expect(draws, lessThan(10));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
