import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart' show renderEvent;
import 'package:llmerta_app/game_table/game_table.dart';

/// The M3 UI leak gate (CLAUDE.md rule 7): simulated games through the
/// real session controller, asserting no out-of-scope hidden info can
/// reach any human-visible render surface. Required check — do not weaken.
void main() {
  const roleWords = ['mafioso', 'doctor', 'sheriff', 'assassin'];

  test('scripted games never leak hidden info into render state', () async {
    for (var seed = 0; seed < 12; seed++) {
      final seats = 7 + (seed % 8);
      final names = [for (var s = 0; s < seats; s++) 'P$s'];
      final container = ProviderContainer();
      final controller = container.read(gameSessionControllerProvider.notifier);
      final result = await controller.startScripted(
        config: GameConfig(seats: seats),
        controllers: {
          for (var s = 0; s < seats; s++) s: RandomLegalController(seed + s),
        },
        names: names,
        seed: 1000 + seed,
      );
      final session = container.read(gameSessionControllerProvider);
      final roles = result.events.whereType<RolesDealt>().first.roles;
      final humanRole = roles[session.humanSeat]!;
      final humanIsMafia = humanRole.faction == Faction.mafia;
      expect(session.humanIsMafia, humanIsMafia);

      // Structural sweep: event types that must never reach the human's
      // slice unless their scope grants it.
      for (final event in session.visibleEvents) {
        final allowed = switch (event) {
          RolesDealt() || NightResolved() => false,
          RoleReceived(:final seat) => seat == session.humanSeat,
          MafiaTeamRevealed() ||
          MafiaChatSaid() ||
          MafiaKillVoteCast() ||
          MafiaKillChosen() => humanIsMafia,
          DoctorProtected() => humanRole == Role.doctor,
          SheriffInvestigated() => humanRole == Role.sheriff,
          AssassinDecided() || AssassinShotResolved() =>
            humanRole == Role.assassin,
          _ => true,
        };
        expect(allowed, isTrue, reason: 'seed $seed leaked $event');
      }

      // Fold every prefix: render state must never claim knowledge the
      // human's slice cannot justify.
      final dead = <int>{};
      for (var upTo = 1; upTo <= session.visibleEvents.length; upTo++) {
        final events = session.visibleEvents.sublist(0, upTo);
        for (final e in events.sublist(upTo - 1)) {
          if (e is DawnAnnounced) dead.addAll(e.deaths);
          if (e is Verdict && e.eliminated != null) dead.add(e.eliminated!);
        }
        final view = buildTableView(
          events,
          humanSeat: session.humanSeat,
          names: names,
        );
        if (!humanIsMafia) {
          expect(view.mafiaTeam, isEmpty, reason: 'seed $seed');
        }
        expect(
          view.revealedRoles.keys.every(dead.contains),
          isTrue,
          reason: 'seed $seed revealed a living seat\'s role',
        );
      }

      // Transcript sweep: role words may appear only on lines that a
      // public reveal (or the human's own private info) justifies.
      for (final event in session.visibleEvents) {
        final line = renderEvent(event, names);
        if (line == null) continue;
        final justified = switch (event) {
          DawnAnnounced() || Verdict() || GameEnded() => true,
          RoleReceived() ||
          SheriffInvestigated() ||
          DoctorProtected() ||
          AssassinDecided() ||
          AssassinShotResolved() => true,
          MafiaTeamRevealed() || MafiaChatSaid() => humanIsMafia,
          MafiaKillVoteCast() || MafiaKillChosen() => humanIsMafia,
          GameStarted() => true,
          _ => false,
        };
        if (justified) continue;
        for (final word in roleWords) {
          expect(
            line.toLowerCase().contains(word),
            isFalse,
            reason: 'seed $seed: "$line" names a role without a reveal',
          );
        }
      }
      container.dispose();
    }
  });
}
