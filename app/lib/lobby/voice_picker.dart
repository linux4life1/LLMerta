import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tts/tts.dart';

import '../services/services.dart';
import 'lobby_setup.dart';

/// Per-seat voice casting: pick by ear. Every row previews a line
/// through the real engine; "Auto" keeps the rotating assignment.
class VoicePickerButton extends ConsumerWidget {
  const VoicePickerButton({required this.seat, super.key});

  final int seat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(
      lobbySetupControllerProvider.select((s) => s.seats[seat].voice),
    );
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: choice == null ? 'Voice: auto' : 'Voice: $choice',
      icon: Icon(
        Icons.record_voice_over,
        size: 20,
        color: choice == null ? scheme.outline : scheme.primary,
      ),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => VoicePickerDialog(seat: seat),
      ),
    );
  }
}

class VoicePickerDialog extends ConsumerWidget {
  const VoicePickerDialog({required this.seat, super.key});

  final int seat;

  static const _previewLines = [
    'The town sleeps, but I never do.',
    'I saw who left the bakery last night.',
    'Trust me — or better, watch me closely.',
    'Somebody at this table is lying beautifully.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = ref.watch(ttsStackProvider);
    final selected = ref.watch(
      lobbySetupControllerProvider.select((s) => s.seats[seat].voice),
    );
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    return AlertDialog(
      title: Text('Voice for seat ${seat + 1}'),
      content: SizedBox(
        width: 380,
        height: 420,
        child: stack == null
            ? const Center(
                child: Text(
                  'No voice bundles downloaded yet.\n'
                  'Settings → Voices gets you Kokoro (53 speakers) '
                  'or Piper.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  _VoiceRow(
                    label: 'Auto — rotate with the table',
                    selected: selected == null,
                    onPick: () {
                      controller.castSeat(
                        seat,
                        ref
                            .read(lobbySetupControllerProvider)
                            .seats[seat]
                            .copyWith(voice: null),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  for (final voice in stack.voices)
                    _VoiceRow(
                      label: voice.label,
                      selected: selected == voiceChoiceKey(voice),
                      onPreview: () => stack.queue.add(
                        SpeechItem(
                          id: -seat - 1,
                          text:
                              _previewLines[voice.speakerId %
                                  _previewLines.length],
                          voice: voice,
                        ),
                      ),
                      onPick: () {
                        controller.castSeat(
                          seat,
                          ref
                              .read(lobbySetupControllerProvider)
                              .seats[seat]
                              .copyWith(voice: voiceChoiceKey(voice)),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _VoiceRow extends StatelessWidget {
  const _VoiceRow({
    required this.label,
    required this.selected,
    required this.onPick,
    this.onPreview,
  });

  final String label;
  final bool selected;
  final VoidCallback onPick;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      leading: onPreview == null
          ? const SizedBox(width: 32)
          : IconButton(
              tooltip: 'Hear this voice',
              icon: const Icon(Icons.play_circle_outline, size: 22),
              onPressed: onPreview,
            ),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, size: 18) : null,
      onTap: onPick,
    );
  }
}
