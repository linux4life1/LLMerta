import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';

import '../game_table/game_table.dart';
import '../theme/theme.dart';
import 'reveal_stats.dart';

/// Spoiler rendering for the post-game timeline. Hidden events get
/// third-person tagged lines (renderEvent speaks actor-perspective,
/// wrong for an omniscient reveal); public ones keep their usual render.
String? revealLine(GameEvent event, List<String> names) =>
    _hiddenLine(event, names) ?? renderEvent(event, names);

String? _hiddenLine(GameEvent event, List<String> names) => switch (event) {
  // Arguments are public; renderEvent already covers them.
  ArgumentOpened() || ArgumentRebuttal() => null,
  MafiaChatSaid(:final seat, :final text) => '[family] ${names[seat]}: "$text"',
  MafiaKillVoteCast(:final by, :final target) =>
    '[family] ${names[by]} marks '
        '${target == null ? 'nobody' : names[target]}',
  MafiaKillChosen(:final target) =>
    '[family] the kill settles on '
        '${target == null ? 'no one' : names[target]}',
  DoctorProtected(:final doctor, :final target) =>
    '[doctor] ${names[doctor]} guards ${names[target]}',
  SheriffInvestigated(:final sheriff, :final target, :final foundMafia) =>
    '[sheriff] ${names[sheriff]} investigates ${names[target]}: '
        '${foundMafia ? 'MAFIA' : 'not mafia'}',
  AssassinDecided(:final assassin, :final target) =>
    target == null
        ? '[assassin] ${names[assassin]} holds fire'
        : '[assassin] ${names[assassin]} fires at ${names[target]}',
  AssassinShotResolved(
    :final assassin,
    :final target,
    :final killed,
    :final wasMafia,
  ) =>
      '[assassin] ${names[assassin]}\'s shot at ${names[target]} '
      '${killed ? 'landed' : 'was blocked'} '
      '(target was ${wasMafia ? 'mafia' : 'not mafia'})',
  NightResolved(:final killed, :final saved) =>
    '[night] killed: '
        '${killed.isEmpty ? 'nobody' : killed.map((s) => names[s]).join(', ')}'
        '${saved.isEmpty ? '' : ' — saved: ${saved.map((s) => names[s]).join(', ')}'}',
  MafiaTeamRevealed(:final team) =>
    '[family] the members: ${team.map((s) => names[s]).join(', ')}',
  FallbackApplied(:final seat, :final action, :final reason) =>
    '[engine] fallback for ${names[seat]} ($action): $reason',
  _ => null,
};

class RevealScreen extends ConsumerWidget {
  const RevealScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const RevealScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final events = ref
        .read(gameSessionControllerProvider.notifier)
        .revealEvents;
    if (session.stage != GameStage.finished || events.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('The Reveal')),
        body: const Center(
          child: Text('Finish a game and every secret opens up here.'),
        ),
      );
    }
    final roles = events.whereType<RolesDealt>().firstOrNull?.roles ?? {};
    return Scaffold(
      appBar: AppBar(
        title: Text('The Reveal — ${session.townName ?? 'the table'}'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(switch (session.winner) {
                  Faction.town => 'The town prevails.',
                  Faction.mafia => 'The mafia owns this town.',
                  null => 'A stalemate draws the curtain.',
                }, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final MapEntry(:key, :value) in roles.entries)
                      Chip(
                        avatar: Icon(
                          value.faction == Faction.mafia
                              ? Icons.handshake
                              : Icons.shield_outlined,
                          size: 16,
                          color: value.faction == Faction.mafia
                              ? LlmertaPalette.blood
                              : null,
                        ),
                        label: Text('${session.names[key]} — ${value.name}'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                StatsSection(
                  stats: computeRevealStats(events),
                  names: session.names,
                ),
                const ReasoningSection(),
                const CostSection(),
                const SizedBox(height: 16),
                Text(
                  'The full record',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final event in events)
                  if (revealLine(event, session.names) case final String line)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          const SizedBox(width: 360, child: TableTalkPanel()),
        ],
      ),
    );
  }
}

/// Post-game table talk (GAME_DESIGN.md §4.6): the cast rehashes the game
/// with full hindsight; the human joins from the input row.
class TableTalkPanel extends ConsumerStatefulWidget {
  const TableTalkPanel({super.key});

  @override
  ConsumerState<TableTalkPanel> createState() => _TableTalkPanelState();
}

class _TableTalkPanelState extends ConsumerState<TableTalkPanel> {
  final _lines = <(int, String)>[];
  final _input = TextEditingController();
  Completer<String?>? _humanTurn;
  var _running = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final session = ref.read(gameSessionControllerProvider);
    final controller = ref.read(gameSessionControllerProvider.notifier);
    setState(() {
      _running = true;
      _lines.clear();
    });
    try {
      await postGameTableTalk(
        events: controller.revealEvents,
        names: session.names,
        agentSeats: controller.agentBackends,
        personas: session.personas,
        rounds: 1,
        humanSeat: session.humanSeat,
        humanTurn: (_) {
          final completer = Completer<String?>();
          setState(() => _humanTurn = completer);
          return completer.future;
        },
        onLine: (seat, line) => setState(() => _lines.add((seat, line))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _humanTurn = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Table talk',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonal(
                onPressed: _running ? null : _start,
                child: Text(_lines.isEmpty ? 'Start' : 'Another round'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _lines.isEmpty && !_running
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nothing is secret anymore — let the cast rehash '
                      'the game with you.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final (seat, line) in _lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${session.names[seat]}: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: seat == session.humanSeat
                                      ? LlmertaPalette.brass
                                      : null,
                                ),
                              ),
                              TextSpan(text: line),
                            ],
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_running && _humanTurn == null)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: _humanTurn != null,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _humanTurn == null
                          ? 'Your turn comes each round…'
                          : 'Say your piece',
                    ),
                    onSubmitted: (_) => _sendHuman(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _humanTurn == null ? null : _sendHuman,
                  child: const Text('Send'),
                ),
                TextButton(
                  onPressed: _humanTurn == null
                      ? null
                      : () {
                          _humanTurn!.complete(null);
                          setState(() => _humanTurn = null);
                        },
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _sendHuman() {
    final turn = _humanTurn;
    if (turn == null) return;
    final text = _input.text.trim();
    _input.clear();
    turn.complete(text.isEmpty ? null : text);
    setState(() => _humanTurn = null);
  }
}
