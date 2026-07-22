import 'package:game_core/game_core.dart';

import 'personas.dart';
import 'provider.dart';
import 'visible_facts.dart';

/// Post-game table talk (GAME_DESIGN.md §4.6): the reveal has happened, so
/// every seat converses with full hindsight — confessions, told-you-sos,
/// and grudge foreshadowing. Rounds are sequential so later speakers react
/// to earlier banter. Returns (seat, line) in speaking order.
Future<List<(int, String)>> postGameTableTalk({
  required List<GameEvent> events,
  required List<String> names,
  required Map<int, (ChatProvider, String)> agentSeats,
  Map<int, Persona> personas = const {},
  int rounds = 2,
  int maxTokens = 1024,
  Future<String?> Function(List<(int, String)> soFar)? humanTurn,
  int? humanSeat,
}) async {
  final roles = events.whereType<RolesDealt>().firstOrNull?.roles ?? {};
  final winner = events.whereType<GameEnded>().firstOrNull?.winner;
  final transcript = [
    for (final event in events)
      if (renderEvent(event, names) case final String line) line,
  ].join('\n');
  final reveal =
      'Final roles: ${roles.entries.map((e) => '${names[e.key]}=${e.value.name}').join(', ')}. '
      'Winner: ${winner?.name ?? 'draw'}.';

  final talk = <(int, String)>[];
  for (var round = 0; round < rounds; round++) {
    for (final seat in [...agentSeats.keys]..sort()) {
      final (provider, model) = agentSeats[seat]!;
      final persona = personas[seat];
      final result = await provider.chat(
        [
          ChatMessage.system(
            'You are ${names[seat]}, who played the ${roles[seat]?.name} in '
            'a just-finished game of Mafia. The game is OVER and every role '
            'is revealed — nothing is secret anymore. '
            '${persona?.promptBlock ?? ''}',
          ),
          ChatMessage.user(
            'FULL GAME RECORD (including everything that was hidden):\n'
            '$transcript\n$reveal\n\n'
            'POST-GAME TABLE TALK so far:\n'
            '${talk.isEmpty ? '(you speak first)' : talk.map((t) => '${names[t.$1]}: "${t.$2}"').join('\n')}\n\n'
            'Say your piece to the table — react to the reveal, confess '
            'your schemes, call out great or terrible plays, tease, '
            'congratulate, or hold a grudge. Under 80 words, in character, '
            'plain text.',
          ),
        ],
        model: model,
        maxTokens: maxTokens,
      );
      final line = result.text.trim();
      if (line.isNotEmpty) talk.add((seat, line));
    }
    if (humanSeat != null && humanTurn != null) {
      final humanLine = await humanTurn(talk);
      if (humanLine != null && humanLine.isNotEmpty) {
        talk.add((humanSeat, humanLine));
      }
    }
  }
  return talk;
}
