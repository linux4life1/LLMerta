import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_session.dart';
import 'ui_human_controller.dart';

/// v1 dock: keeps games fully playable until the spec'd dock (M3.5 —
/// two-step vote lock, mafia chat panel, night overlays) replaces it.
class InterimDock extends ConsumerStatefulWidget {
  const InterimDock({super.key});

  @override
  ConsumerState<InterimDock> createState() => _InterimDockState();
}

class _InterimDockState extends ConsumerState<InterimDock> {
  final _text = TextEditingController();
  int? _selected;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionControllerProvider);
    final request = ref.watch(humanRequestProvider).value;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: request == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    session.stage == GameStage.finished
                        ? 'The game is over.'
                        : 'The table plays — your move will come.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : _prompt(request, session.names),
      ),
    );
  }

  Widget _prompt(HumanRequest request, List<String> names) {
    if (request.wantsText) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              autofocus: true,
              decoration: InputDecoration(
                isDense: true,
                labelText: switch (request.kind) {
                  HumanActionKind.speak =>
                    "You're up — aim for under 120 words",
                  HumanActionKind.defend => 'Your defense',
                  HumanActionKind.lastWords => 'Your last words',
                  _ => 'Say it to your team (private)',
                },
              ),
              onSubmitted: (_) => _sendText(request),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _sendText(request),
            child: const Text('Speak'),
          ),
        ],
      );
    }
    final verb = switch (request.kind) {
      HumanActionKind.nominate => 'Nominate',
      HumanActionKind.vote => 'Vote',
      HumanActionKind.mafiaKillVote => 'Mark the kill',
      HumanActionKind.doctorProtect => 'Protect someone',
      HumanActionKind.sheriffInvestigate => 'Investigate someone',
      HumanActionKind.assassinShoot => 'A bullet, or patience',
      _ => 'Choose',
    };
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(verb, style: Theme.of(context).textTheme.labelLarge),
        for (final target in request.targets)
          ChoiceChip(
            label: Text(names[target]),
            selected: _selected == target,
            onSelected: (_) => setState(() => _selected = target),
          ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => _sendChoice(request, _selected),
          child: Text(
            request.kind == HumanActionKind.assassinShoot ? 'Fire' : 'Confirm',
          ),
        ),
        if (!request.mustChoose)
          OutlinedButton(
            onPressed: () => _sendChoice(request, null),
            child: Text(switch (request.kind) {
              HumanActionKind.assassinShoot => 'Hold your fire',
              HumanActionKind.vote => 'Abstain',
              _ => 'Pass',
            }),
          ),
      ],
    );
  }

  void _sendText(HumanRequest request) {
    request.submitText(_text.text.trim());
    _text.clear();
  }

  void _sendChoice(HumanRequest request, int? choice) {
    request.submitChoice(choice);
    setState(() => _selected = null);
  }
}
