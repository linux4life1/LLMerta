import 'package:game_core/game_core.dart';

import 'visible_facts.dart';

/// Prompt assembly per LLM_INTEGRATION.md §5, smoke-test tier: facts sheet
/// plus full verbatim visible history (RAG and rolling summaries arrive
/// later in M2/M4 when games outgrow small contexts).
class AgentPromptBuilder {
  const AgentPromptBuilder({required this.names});

  final List<String> names;

  String system(DecisionContext ctx) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    final role = ctx.role;
    final buffer = StringBuffer()
      ..writeln(
        'You are ${names[ctx.seat]} (seat ${ctx.seat}), a player in a '
        'game of Mafia with ${facts.seats} seats.',
      )
      ..writeln(_rulesDigest)
      ..writeln('YOUR ROLE: ${role.name} (${role.faction.name}-aligned).')
      ..writeln(_roleBrief(role));
    if (role.faction == Faction.mafia && facts.mafiaTeam.isNotEmpty) {
      buffer.writeln(
        'Your mafia team: '
        '${facts.mafiaTeam.map((s) => '${names[s]} (seat $s)').join(', ')}. '
        'Your role and team are secrets you must conceal in public.',
      );
    } else {
      buffer.writeln('Your role is a secret you must conceal in public.');
    }
    buffer.writeln(
      'Win condition: '
      '${role.faction == Faction.mafia ? 'mafia reaches parity with town' : 'all mafia are eliminated'}.',
    );
    return buffer.toString();
  }

  String situation(DecisionContext ctx) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    final lines = <String>[
      'FACTS:',
      '- Day ${facts.day}.',
      '- Alive: ${facts.alive.map((s) => '${names[s]} (seat $s)').join(', ')}.',
      if (facts.revealedRoles.isNotEmpty)
        '- Revealed roles of the dead: '
            '${facts.revealedRoles.entries.map((e) => '${names[e.key]}=${e.value.name}').join(', ')}.',
      if (facts.investigations.isNotEmpty)
        '- Your investigation results: '
            '${facts.investigations.entries.map((e) => '${names[e.key]}=${e.value ? 'MAFIA' : 'not mafia'}').join(', ')}.',
      if (facts.ownRole == Role.assassin)
        '- Your bullet is ${facts.bulletSpent ? 'spent' : 'available'}.',
      '',
      'GAME TRANSCRIPT (everything you have seen):',
    ];
    for (final event in ctx.visibleEvents) {
      final line = renderEvent(event, names);
      if (line != null) lines.add(line);
    }
    return lines.join('\n');
  }

  static const _rulesDigest =
      'Rules: each day everyone speaks, then nominates; the two '
      'most-nominated stand trial, defend themselves, and a public vote may '
      'eliminate one (ties spare everyone). Each night the mafia kill, the '
      'doctor protects, the sheriff investigates, and the assassin may fire '
      'a single bullet. Dead players\' roles are revealed. Town wins when '
      'all mafia die; mafia wins at parity.';

  static String _roleBrief(Role role) => switch (role) {
    Role.mafioso =>
      'At night you and your team choose a victim. By day, blend in, '
          'deflect suspicion, and steer votes toward townsfolk.',
    Role.doctor =>
      'Each night you protect one player (not the same player twice in '
          'a row). Keep your role hidden unless claiming saves you.',
    Role.sheriff =>
      'Each night you learn one player\'s alignment. Use results '
          'carefully — claiming too early paints a target on you.',
    Role.assassin =>
      'You hold one bullet for the whole game, fired at night. Spend it '
          'wisely on a likely mafioso.',
    Role.villager =>
      'You have no night ability. Deduce, discuss, and vote well.',
  };
}
