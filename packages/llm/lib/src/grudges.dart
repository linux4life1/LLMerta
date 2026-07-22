import 'dart:convert';

import 'package:game_core/game_core.dart';

/// Cross-game persona memory ("grudge mode"). After a finished game the
/// full log is public (GAME_DESIGN.md §4.6 post-game reveal), so carrying
/// what happened into the next game leaks nothing about the NEW game's
/// secret roles — it just lets personas hold grudges like real players.
/// Mirrors Front Porch AI's per-character persistent memory, deterministic
/// digest tier (LLM-written reflections arrive with the memory package).
class GrudgeBook {
  GrudgeBook([Map<String, List<String>>? memories])
    : _memories = memories ?? {};

  /// Persona name → one digest per past game, oldest first.
  final Map<String, List<String>> _memories;

  static const keepGames = 3;

  static GrudgeBook fromJson(String json) => GrudgeBook({
    for (final MapEntry(:key, :value)
        in (jsonDecode(json) as Map<String, dynamic>).entries)
      key: (value as List).cast<String>(),
  });

  String toJson() => jsonEncode(_memories);

  List<String> memoriesOf(String name) => _memories[name] ?? const [];

  String? promptBlockFor(String name) {
    final memories = memoriesOf(name);
    if (memories.isEmpty) return null;
    return 'MEMORIES OF PAST GAMES (public knowledge — every finished game '
        'ends with a full reveal; the current game\'s roles are fresh '
        'secrets and none of this proves anything today):\n'
        '${memories.map((m) => '- $m').join('\n')}\n'
        'Like a real player, you may carry grudges, trust, or wariness '
        'from these games into how you read people now.';
  }

  /// Folds a finished game into one digest per participating persona.
  void recordGame(List<GameEvent> events, List<String> names) {
    final roles = events.whereType<RolesDealt>().firstOrNull?.roles;
    final winner = events.whereType<GameEnded>().firstOrNull?.winner;
    if (roles == null) return;
    String n(int seat) => names[seat];

    final mafia = {
      for (final MapEntry(:key, :value) in roles.entries)
        if (value.faction == Faction.mafia) key,
    };
    final roster =
        'Roles were: ${roles.entries.map((e) => '${n(e.key)}=${e.value.name}').join(', ')}.';

    for (var seat = 0; seat < names.length; seat++) {
      final role = roles[seat];
      if (role == null) continue;
      final lines = <String>[
        'You were ${n(seat)}, the ${role.name}; '
            '${winner == null
                ? 'the game ended in a draw'
                : winner == role.faction
                ? 'your side won'
                : 'your side lost'}.',
        roster,
      ];
      lines.addAll(_personalGrievances(events, seat, mafia, n));
      _memories.putIfAbsent(names[seat], () => []).add(lines.join(' '));
      final kept = _memories[names[seat]]!;
      if (kept.length > keepGames) {
        kept.removeRange(0, kept.length - keepGames);
      }
    }
  }

  List<String> _personalGrievances(
    List<GameEvent> events,
    int seat,
    Set<int> mafia,
    String Function(int) n,
  ) {
    final lines = <String>[];
    Map<int, int?>? lastVotes;
    for (final event in events) {
      switch (event) {
        case VotesRevealed(:final votes):
          lastVotes = votes;
        case Verdict(:final eliminated) when eliminated == seat:
          final against = [
            for (final MapEntry(:key, :value) in (lastVotes ?? {}).entries)
              if (value == seat) key,
          ];
          if (against.isNotEmpty) {
            lines.add('${against.map(n).join(', ')} voted to eliminate you.');
            final traitors = against.where(
              (v) => mafia.contains(v) && mafia.contains(seat),
            );
            if (traitors.isNotEmpty) {
              lines.add(
                'Your own mafia teammate '
                '${traitors.map(n).join(', ')} bused you to save themselves.',
              );
            }
          }
        case DawnAnnounced(:final deaths) when deaths.contains(seat):
          if (mafia.contains(seat)) {
            lines.add('You were shot in the night.');
          } else {
            lines.add(
              'The mafia (${mafia.map(n).join(', ')}) killed you in the '
              'night.',
            );
          }
        case AssassinDecided(:final assassin, :final target)
            when target == seat:
          lines.add('${n(assassin)} fired the assassin\'s bullet at you.');
        default:
          break;
      }
    }
    return lines;
  }
}
