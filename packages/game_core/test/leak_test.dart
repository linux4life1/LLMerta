import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

/// CI-required leak check (CLAUDE.md rule 7): across simulated games, no
/// seat's visible slice may contain out-of-scope hidden information.
void main() {
  test('no hidden information crosses a seat\'s visibility boundary', () async {
    for (var seed = 0; seed < 50; seed++) {
      final seats = minSeats + (seed % (maxSeats - minSeats + 1));
      final result = await runScriptedGame(
        config: GameConfig(seats: seats),
        seed: 10000 + seed,
      );
      final roles = result.events.whereType<RolesDealt>().single.roles;
      for (var seat = 0; seat < seats; seat++) {
        final isMafia = roles[seat]!.faction == Faction.mafia;
        final visible = result.events.visibleTo(seat, isMafia: isMafia);
        for (final event in visible) {
          switch (event) {
            case RolesDealt() || NightResolved() || FallbackApplied():
              fail('omniscient ${event.runtimeType} leaked to seat $seat');
            case MafiaChatSaid() ||
                MafiaKillVoteCast() ||
                MafiaKillChosen() ||
                MafiaTeamRevealed():
              if (!isMafia) {
                fail('mafia ${event.runtimeType} leaked to town seat $seat');
              }
            case RoleReceived(seat: final owner):
              if (owner != seat) fail('role card of $owner leaked to $seat');
            case DoctorProtected(:final doctor):
              if (doctor != seat) fail('doctor action leaked to seat $seat');
            case SheriffInvestigated(:final sheriff):
              if (sheriff != seat) {
                fail('sheriff result leaked to seat $seat');
              }
            case AssassinDecided(:final assassin):
              if (assassin != seat) {
                fail('assassin decision leaked to seat $seat');
              }
            case AssassinShotResolved(:final assassin):
              if (assassin != seat) {
                fail('assassin shot result leaked to seat $seat');
              }
            default:
              break;
          }
        }
        // Semantic check: a town seat must not be able to derive the mafia
        // roster from its visible role information before game end.
        if (!isMafia) {
          final knownRoles = <int>{
            for (final e in visible.whereType<RoleReceived>()) e.seat,
          };
          expect(knownRoles, {seat});
        }
      }
    }
  });
}
