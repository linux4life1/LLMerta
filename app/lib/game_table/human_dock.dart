import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../reveal/reveal.dart';
import '../theme/theme.dart';
import 'game_session.dart';
import 'table_view.dart';
import 'ui_human_controller.dart';

/// The context-sensitive human dock (UI_UX.md §2). Actions are dedicated
/// UI, never free text (GAME_DESIGN.md §5); votes are two-step
/// (select, then Lock); the assassin's shot requires a confirm.
class HumanDock extends ConsumerStatefulWidget {
  const HumanDock({super.key});

  @override
  ConsumerState<HumanDock> createState() => _HumanDockState();
}

class _HumanDockState extends ConsumerState<HumanDock> {
  final _text = TextEditingController();
  int? _selected;
  var _confirmingFire = false;
  var _words = 0;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionControllerProvider);
    final view = ref.watch(tableViewProvider);
    final request = ref.watch(humanRequestProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: request == null
            ? _idle(session, view)
            : _prompt(request, session, view),
      ),
    );
  }

  Widget _idle(GameSession session, TableViewState view) {
    if (session.stage == GameStage.finished) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'The game is over.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(RevealScreen.route()),
            icon: const Icon(Icons.theater_comedy),
            label: const Text('The Reveal'),
          ),
        ],
      );
    }
    final humanDead = !view.isAlive(session.humanSeat);
    final floor = view.activeSpeech;
    final text = humanDead
        ? 'You watch from beyond. The town plays on without you.'
        : view.night
        ? 'The town sleeps.'
        : floor != null
        ? '${session.names[floor.$1]} has the floor…'
        : 'The table plays — your move will come.';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!humanDead) ...[
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ],
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _prompt(
    HumanRequest request,
    GameSession session,
    TableViewState view,
  ) {
    if (request.wantsText) {
      final isMafiaTalk = request.kind == HumanActionKind.mafiaChat;
      final field = Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              autofocus: true,
              onChanged: (value) => setState(
                () => _words = value
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((w) => w.isNotEmpty)
                    .length,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: switch (request.kind) {
                  HumanActionKind.speak => "You're up",
                  HumanActionKind.defend => 'Your defense',
                  HumanActionKind.lastWords => 'Your last words',
                  _ => 'To your team only',
                },
                helperText: isMafiaTalk
                    ? 'Private — the town never hears this'
                    : '$_words words — aim for under 120',
              ),
              onSubmitted: (_) => _sendText(request),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _sendText(request),
            child: const Text('Speak'),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: () {
              _text.clear();
              _sendText(request);
            },
            child: const Text('Say nothing'),
          ),
        ],
      );
      if (!isMafiaTalk) return field;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MafiaPanel(session: session),
          field,
        ],
      );
    }

    if (request.kind == HumanActionKind.assassinShoot && _confirmingFire) {
      final target = _selected;
      return Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Fire at ${target == null ? '?' : session.names[target]}? '
            'The bullet does not come back.',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          FilledButton(
            onPressed: () {
              setState(() => _confirmingFire = false);
              _sendChoice(request, target);
            },
            child: const Text('Confirm the shot'),
          ),
          OutlinedButton(
            onPressed: () => setState(() => _confirmingFire = false),
            child: const Text('Back'),
          ),
        ],
      );
    }

    final isMafiaKill = request.kind == HumanActionKind.mafiaKillVote;
    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(switch (request.kind) {
          HumanActionKind.nominate => 'Nominate for trial',
          HumanActionKind.vote => 'Your vote — select, then lock',
          HumanActionKind.mafiaKillVote => 'Mark tonight\'s kill',
          HumanActionKind.doctorProtect => 'Protect someone',
          HumanActionKind.sheriffInvestigate => 'Investigate someone',
          HumanActionKind.assassinShoot =>
            view.humanBulletSpent ? 'The chamber is empty' : 'One bullet',
          _ => 'Choose',
        }, style: Theme.of(context).textTheme.labelLarge),
        for (final target in request.targets)
          ChoiceChip(
            label: Text(session.names[target]),
            selected: _selected == target,
            onSelected: (_) => setState(() => _selected = target),
          ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () {
                  if (request.kind == HumanActionKind.assassinShoot) {
                    setState(() => _confirmingFire = true);
                  } else {
                    _sendChoice(request, _selected);
                  }
                },
          child: Text(switch (request.kind) {
            HumanActionKind.vote => 'Lock vote',
            HumanActionKind.assassinShoot => 'Fire',
            HumanActionKind.nominate => 'Nominate',
            HumanActionKind.mafiaKillVote => 'Mark the kill',
            HumanActionKind.doctorProtect => 'Protect',
            HumanActionKind.sheriffInvestigate => 'Investigate',
            _ => 'Confirm',
          }),
        ),
        if (!request.mustChoose)
          OutlinedButton(
            autofocus: request.kind == HumanActionKind.assassinShoot,
            onPressed: () => _sendChoice(request, null),
            child: Text(switch (request.kind) {
              HumanActionKind.assassinShoot => 'Hold your fire',
              HumanActionKind.vote => 'Abstain',
              _ => 'Pass',
            }),
          ),
      ],
    );
    if (!isMafiaKill) return chips;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MafiaPanel(session: session),
        chips,
      ],
    );
  }

  void _sendText(HumanRequest request) {
    request.submitText(_text.text.trim());
    _text.clear();
    setState(() => _words = 0);
  }

  void _sendChoice(HumanRequest request, int? choice) {
    request.submitChoice(choice);
    setState(() => _selected = null);
  }
}

/// Night chat context for a mafia human: teammates and their recent
/// whispers, straight from the (mafia-scoped) visible events.
class _MafiaPanel extends StatelessWidget {
  const _MafiaPanel({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final whispers = session.visibleEvents
        .whereType<MafiaChatSaid>()
        .toList()
        .reversed
        .take(4)
        .toList()
        .reversed;
    final teammates = session.visibleEvents
        .whereType<MafiaTeamRevealed>()
        .firstOrNull
        ?.team;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LlmertaPalette.blood.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LlmertaPalette.blood.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teammates == null
                ? 'The family'
                : 'The family: '
                      '${teammates.map((s) => session.names[s]).join(', ')}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LlmertaPalette.blood,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final line in whispers)
            Text(
              '${session.names[line.seat]}: ${line.text}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
