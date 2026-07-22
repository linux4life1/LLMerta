import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

/// String-level leak check: rendered prompts for a seat must never contain
/// hidden information from outside its visibility scope.
void main() {
  const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];

  test('prompts across simulated games leak no out-of-scope secrets', () async {
    const builder = AgentPromptBuilder(names: names);
    for (var seed = 0; seed < 10; seed++) {
      final result = await runScriptedGame(
        config: const GameConfig(seats: 7),
        seed: 400 + seed,
      );
      final roles = result.events.whereType<RolesDealt>().single.roles;
      final mafiaSeats = {
        for (final MapEntry(:key, :value) in roles.entries)
          if (value.faction == Faction.mafia) key,
      };
      // Prompt as if asking each seat to act right before the game ended,
      // excluding public reveal events so death reveals don't blur the check.
      final preReveal = result.events
          .where(
            (e) =>
                e is! DawnAnnounced &&
                e is! Verdict &&
                e is! GameEnded &&
                e is! LastWordsGiven,
          )
          .toList();
      for (var seat = 0; seat < 7; seat++) {
        final isMafia = mafiaSeats.contains(seat);
        final ctx = DecisionContext(
          seat: seat,
          role: roles[seat]!,
          day: 1,
          visibleEvents: preReveal.visibleTo(seat, isMafia: isMafia),
          livingSeats: const [0, 1, 2, 3, 4, 5, 6],
        );
        final text = '${builder.system(ctx)}\n${builder.situation(ctx)}';
        if (!isMafia) {
          for (final mafioso in mafiaSeats) {
            expect(
              text.contains('${names[mafioso]} (seat $mafioso)') &&
                  text.contains('mafia team'),
              isFalse,
              reason: 'seat $seat must not learn the mafia roster',
            );
          }
          expect(text, isNot(contains('[mafia chat]')));
          expect(text, isNot(contains('Tonight\'s target')));
        }
        // Nobody's prompt may reference engine internals.
        expect(text, isNot(contains('NightResolved')));
        expect(text, isNot(contains('FallbackApplied')));
        // Another seat's private sheriff results must be absent.
        final sheriffSeat = roles.entries
            .firstWhere((e) => e.value == Role.sheriff)
            .key;
        if (seat != sheriffSeat) {
          expect(text, isNot(contains('Investigation:')));
        }
      }
    }
  });

  test('mafia seats do see their team and night chat', () async {
    final result = await runScriptedGame(
      config: const GameConfig(seats: 7),
      seed: 5,
    );
    final roles = result.events.whereType<RolesDealt>().single.roles;
    final mafioso = roles.entries
        .firstWhere((e) => e.value == Role.mafioso)
        .key;
    const builder = AgentPromptBuilder(names: names);
    final ctx = DecisionContext(
      seat: mafioso,
      role: Role.mafioso,
      day: 1,
      visibleEvents: result.events.visibleTo(mafioso, isMafia: true),
      livingSeats: const [0, 1, 2, 3, 4, 5, 6],
    );
    final text = '${builder.system(ctx)}\n${builder.situation(ctx)}';
    expect(text, contains('Your mafia team'));
    expect(text, contains('[mafia chat]'));
  });
}
