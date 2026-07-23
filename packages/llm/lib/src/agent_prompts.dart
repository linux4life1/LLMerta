import 'package:game_core/game_core.dart';

import 'personas.dart';
import 'visible_facts.dart';

/// Difficulty presets (GAME_DESIGN.md §7): strategy guidance only — never
/// rules, never information.
enum Difficulty {
  casual(
    evil:
        'Deflect simply and avoid long cons; pick targets on obvious '
        'grudges.',
    town:
        'Share direct gut reads; if you hold a power role, claim readily '
        'under pressure.',
  ),
  standard(
    evil:
        'Coordinate targets with your team and manage suspicion across '
        'days.',
    town:
        'Cross-reference votes and statements before deciding; make '
        'claims count.',
  ),
  cutthroat(
    evil:
        'Run multi-day frame jobs; bus a teammate if it buys you '
        'credibility.',
    town:
        'Rigorously track voting patterns, claim timing, and '
        'inconsistencies.',
  );

  const Difficulty({required this.evil, required this.town});

  final String evil;
  final String town;
}

/// Prompt assembly per LLM_INTEGRATION.md §5, M2 tier: facts sheet plus
/// full verbatim visible history (RAG and rolling summaries arrive in M4
/// when games outgrow small contexts).
class AgentPromptBuilder {
  const AgentPromptBuilder({
    required this.names,
    this.personas = const {},
    this.difficulty = Difficulty.standard,
    this.pastMemories = const {},
  });

  final List<String> names;

  /// Seat → persona; seats without one play as a plain named villager type.
  final Map<int, Persona> personas;
  final Difficulty difficulty;

  /// Seat → grudge-mode memory block (see GrudgeBook.promptBlockFor).
  final Map<int, String> pastMemories;

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
    final persona = personas[ctx.seat];
    if (persona != null) buffer.writeln(persona.promptBlock);
    // Live-game lessons (M6): personas caused invented "conversations",
    // and long games drifted on role identity.
    buffer.writeln(
      'Ground rules: never invent events, conversations, or quotes that '
      'are not in the record — your persona colors HOW you speak, never '
      'WHAT happened. Your role line above is fixed for the whole game; '
      'trust it over anything anyone claims about you.',
    );
    buffer.writeln(
      'Strategy guidance: '
      '${role.faction == Faction.mafia ? difficulty.evil : difficulty.town}',
    );
    final memories = pastMemories[ctx.seat];
    if (memories != null) buffer.writeln(memories);
    return buffer.toString();
  }

  String situation(DecisionContext ctx) {
    final facts = VisibleFacts.fold(ctx.visibleEvents);
    final lines = <String>[
      'FACTS:',
      '- Day ${facts.day}.',
      '- Alive: ${facts.alive.map((s) => '${names[s]} (seat ${s + 1})').join(', ')}.',
      if (facts.fates.isNotEmpty)
        '- The dead, and exactly how they died: '
            '${facts.fates.entries.map((e) => '${names[e.key]} — ${e.value}${facts.revealedRoles[e.key] != null ? ', was the ${facts.revealedRoles[e.key]!.name}' : ''}').join('; ')}. '
            'Never confuse a night kill with a town vote.',
      if (facts.investigations.isNotEmpty)
        '- Your investigation results: '
            '${facts.investigations.entries.map((e) => '${names[e.key]}=${e.value ? 'MAFIA' : 'not mafia'}').join(', ')}.',
      if (facts.ownRole == Role.assassin)
        '- Your bullet is ${facts.bulletSpent ? 'spent' : 'available'}.',
      '',
      'PUBLIC RECORD (what everyone at the table saw and heard):',
    ];
    final secret = <String>[];
    for (final event in ctx.visibleEvents) {
      final line = renderEvent(event, names);
      if (line == null) continue;
      if (event.scope is PublicScope) {
        lines.add(line);
      } else {
        secret.add(line);
      }
    }
    if (secret.isNotEmpty) {
      lines
        ..add('')
        ..add(
          'YOUR SECRET KNOWLEDGE (invisible to everyone else — referencing '
          'any of it in public instantly exposes you; only ever reveal it '
          'as a deliberate claim):',
        )
        ..addAll(secret);
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
