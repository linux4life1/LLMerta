import 'package:game_core/game_core.dart';

import 'personas.dart';
import 'visible_facts.dart';

/// Difficulty presets (GAME_DESIGN.md §7): strategy guidance **plus** a
/// small house-rules bundle. Visibility and role abilities are identical
/// at every level; only discussion depth, ties, mafia count delta, and
/// Night-0 sheriff peek shift.
enum Difficulty {
  casual(
    evil:
        'Deflect simply; a soft fakeclaim is fine if pressed. Avoid long '
        'cons; pick targets on obvious grudges.',
    town:
        'Share direct gut reads; if you hold a power role, claim readily '
        'under pressure. Prefer evidence over volume. Challenge players '
        'who dodge.',
    discussionRounds: 2,
    crossfireRounds: 1,
    tieRule: TieRule.runoff,
    mafiaCountDelta: -1,
    night0SheriffPeek: true,
  ),
  standard(
    evil:
        'Coordinate kills and day reads with your team. Use fakeclaims '
        '(fake Sheriff digs, fake Doctor protect stories, villager '
        'innocence plays) to steer the hang. Lie about motives; do not '
        'invent public events that never happened.',
    town:
        'Cross-reference votes and statements; demand claims when the '
        'board stalls. Call out inconsistencies in crossfire. Do not '
        'pile onto volume alone.',
    discussionRounds: 2,
    crossfireRounds: 1,
    tieRule: TieRule.runoff,
    mafiaCountDelta: 0,
    night0SheriffPeek: false,
  ),
  cutthroat(
    evil:
        'Run multi-day frame jobs and fakeclaims; bus a teammate if it '
        'buys credibility. Plant false investigation results as Sheriff '
        'claims when useful.',
    town:
        'Rigorously track voting patterns, claim timing, and '
        'inconsistencies. Force counterclaims in crossfire.',
    discussionRounds: 2,
    crossfireRounds: 2,
    tieRule: TieRule.noElimination,
    mafiaCountDelta: 0,
    night0SheriffPeek: false,
  );

  const Difficulty({
    required this.evil,
    required this.town,
    required this.discussionRounds,
    required this.crossfireRounds,
    required this.tieRule,
    required this.mafiaCountDelta,
    required this.night0SheriffPeek,
  });

  final String evil;
  final String town;
  final int discussionRounds;
  final int crossfireRounds;
  final TieRule tieRule;
  final int mafiaCountDelta;
  final bool night0SheriffPeek;

  /// Applies this preset's house-rules knobs to [base], keeping seat count
  /// and any non-difficulty toggles the player already set.
  GameConfig applyRules(GameConfig base) => base.copyWith(
    discussionRounds: discussionRounds,
    crossfireRounds: crossfireRounds,
    tieRule: tieRule,
    mafiaCountDelta: mafiaCountDelta,
    night0SheriffPeek: night0SheriffPeek,
  );
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
        'You are ${names[ctx.seat]} (seat ${ctx.seat + 1}), a player in a '
        'game of Mafia with ${facts.seats} seats.',
      )
      ..writeln(_rulesDigest)
      ..writeln('YOUR ROLE: ${role.name} (${role.faction.name}-aligned).')
      ..writeln(_roleBrief(role));
    if (role.faction == Faction.mafia && facts.mafiaTeam.isNotEmpty) {
      buffer.writeln(
        'Your mafia team: '
        '${facts.mafiaTeam.map((s) => '${names[s]} (seat ${s + 1})').join(', ')}. '
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
    // Live-game lessons (M6 / rebalance): invented whispers, role drift,
    // persona monologues, and herd copy-paste catchphrases
    // ("fire not firefighter") collapsed discussion quality.
    buffer.writeln(
      'Ground rules: never invent private conversations, whispers, or '
      'quotes that are not in the public record — your persona colors HOW '
      'you speak (at most one short colorful sentence), never fabricates '
      'what others already said. Speak in first person only (I / me / my). '
      'Do not restate another player\'s catchphrase; add something new. '
      'Your true role line above is fixed; trust it over anyone\'s claims '
      'about you. Do not accuse solely on volume or quirks — cite the '
      'public record when accusing about past play.',
    );
    if (role.faction == Faction.mafia) {
      buffer.writeln(
        'DECEPTION: you must conceal that you are mafia. Public lies are '
        'allowed and expected: fakeclaim Sheriff/Doctor/Villager, invent '
        'false investigation or protect stories, feign town motives, and '
        'frame townsfolk. Never name real teammates as mafia. Do not invent '
        'speeches or votes that are not in the public record. When pressured, '
        'a bold fakeclaim beats silent guilt.',
      );
    } else {
      buffer.writeln(
        'Town deception is limited: bluff only if it serves town (e.g. soft '
        'claim to bait mafia). Real power info should be claimed when it '
        'swings a hang. Challenge dodges and fakeclaims in crossfire.',
      );
    }
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
      if (facts.ownRole == Role.sheriff && facts.liveMafiaHits.isNotEmpty)
        '- URGENT SHERIFF CLAIM: you have confirmed MAFIA still alive — '
            '${facts.liveMafiaHits.map((s) => '${names[s]} (seat ${s + 1})').join(', ')}. '
            'This information dies with you. Open today\'s speech by claiming '
            'Sheriff and naming them (and any other results), then push the '
            'table to vote that seat. Do not sit on a live mafia hit while '
            'town is bleeding or about to hang a villager.',
      if (facts.ownRole == Role.assassin)
        '- Your bullet is ${facts.bulletSpent ? 'spent' : 'available'}.',
      if (facts.shotResults.isNotEmpty)
        '- Your past shots: '
            '${facts.shotResults.map((r) {
              final name = '${names[r.target]} (seat ${r.target + 1})';
              final land = r.killed ? 'landed' : 'blocked (they lived)';
              final align = r.wasMafia ? 'MAFIA' : 'not mafia';
              return '$name — bullet $land, target was $align';
            }).join('; ')}.',
      if (facts.ownRole == Role.mafioso && facts.mafiaTeam.isNotEmpty) ...[
        '- Living mafia teammates: '
            '${facts.mafiaTeam.where(facts.alive.contains).map((s) => '${names[s]} (seat ${s + 1})').join(', ')}.',
        if (facts.lastMafiaKill != null)
          '- Last agreed mafia kill target: '
              '${names[facts.lastMafiaKill!]} (seat ${facts.lastMafiaKill! + 1}). '
              'Do not re-plan nights that already resolved; use the public '
              'death list and this line as ground truth.',
      ],
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
    final already = _alreadySaidToday(ctx.visibleEvents, facts.day, ctx.seat);
    if (already.isNotEmpty) {
      lines
        ..add('')
        ..add(
          'ALREADY SAID TODAY (do not restate these talking points or '
          'catchphrases; respond with something new):',
        )
        ..addAll(already);
    }
    return lines.join('\n');
  }

  /// Compact digest of each other seat's latest speech/nomination today so
  /// later speakers stop cloning the opening of the round.
  static List<String> _alreadySaidToday(
    Iterable<GameEvent> events,
    int dayNumber,
    int self,
  ) {
    final latest = <int, String>{};
    var inDay = false;
    for (final event in events) {
      switch (event) {
        case DayBegan(:final day):
          inDay = day == dayNumber;
          if (inDay) latest.clear();
        case SpeechGiven(:final seat, :final text) when inDay && seat != self:
          latest[seat] = _digestSpeech(text);
        case ArgumentOpened(:final by, :final to, :final text)
            when inDay && by != self && to != null && text.isNotEmpty:
          latest[by] = 'argues at seat ${to + 1}: ${_digestSpeech(text)}';
        case ArgumentRebuttal(:final by, :final to, :final text)
            when inDay && by != self && text.isNotEmpty:
          latest[by] = 'rebuts seat ${to + 1}: ${_digestSpeech(text)}';
        case NominationCast(:final by, :final target, :final statement)
            when inDay && by != self && target != null:
          final charge = statement.trim().isEmpty
              ? 'nominates seat ${target + 1}'
              : _digestSpeech(statement);
          latest[by] = 'nominates seat ${target + 1}: $charge';
        default:
          break;
      }
    }
    final ordered = latest.keys.toList()..sort();
    return [for (final s in ordered) '- seat ${s + 1}: ${latest[s]}'];
  }

  static String _digestSpeech(String text) {
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.length <= 140) return oneLine;
    return '${oneLine.substring(0, 137)}...';
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
      'At night name a living non-mafia kill target with your team. By day '
          'blend in, fakeclaim when useful, frame townsfolk, and never out '
          'teammates. Crossfire is a chance to dig in or force a counterclaim.',
    Role.doctor =>
      'Each night you protect one player (not the same player twice in '
          'a row). Keep your role hidden unless claiming saves you or '
          'stops a mislynch.',
    Role.sheriff =>
      'Each night you learn one player\'s alignment. Soft not-mafia results '
          'can stay private early. A live MAFIA hit must be claimed on the '
          'next day you speak — open with "I am the Sheriff" and the name. '
          'In crossfire, defend your digs and call out fakeclaimers.',
    Role.assassin =>
      'You hold one bullet for the whole game, fired at night. After you '
          'fire you learn privately whether it landed and whether the '
          'target was mafia. Claim with that result when it swings town.',
    Role.villager =>
      'You have no night ability. Deduce, discuss, demand claims, and vote '
          'well. Use crossfire to press people who named you.',
  };
}
