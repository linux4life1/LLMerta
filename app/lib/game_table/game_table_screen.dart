import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:game_core/game_core.dart' show Role;

import '../lobby/lobby.dart' show sceneDecoration;
import '../services/services.dart'
    show
        nowSpeakingProvider,
        ttsDirectorProvider,
        ttsEnabledProvider,
        ttsStackProvider;
import '../settings/settings.dart' show SettingsScreen;
import '../theme/theme.dart';
import 'game_session.dart';
import 'human_dock.dart';
import 'night_overlay.dart';
import 'seat_ring.dart';
import 'session_providers.dart';
import 'session_state.dart';
import 'spoken_text.dart';
import 'table_view.dart';
import 'transcript_drawer.dart';
import 'ui_human_controller.dart' show HumanRequest;

class GameTableScreen extends ConsumerWidget {
  const GameTableScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const GameTableScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final mood = ref.watch(tableMoodControllerProvider);
    // Keeps the TTS director listening while the table is on screen.
    ref.watch(ttsDirectorProvider);
    final theme = mood == TableMood.day ? LlmertaTheme.day : LlmertaTheme.night;
    return Theme(
      data: theme,
      child: Scaffold(
        endDrawer: const TranscriptDrawer(),
        body: switch (session.stage) {
          GameStage.idle => const Center(
            child: Text('No game running — deal from the lobby.'),
          ),
          GameStage.casting => const Center(child: CircularProgressIndicator()),
          GameStage.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('The game hit a wall: ${session.error}'),
            ),
          ),
          _ => const _TableBody(),
        },
      ),
    );
  }
}

class _TableBody extends ConsumerWidget {
  const _TableBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final mood = ref.watch(tableMoodControllerProvider);
    final view = ref.watch(tableViewProvider);
    final HumanRequest? request = ref.watch(humanRequestProvider).value;
    final passiveNight =
        mood == TableMood.night &&
        session.stage == GameStage.running &&
        request == null &&
        view.isAlive(session.humanSeat);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: session.scene == null
              ? const BoxDecoration(color: LlmertaPalette.ink)
              : sceneDecoration(session.scene!),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          color: mood == TableMood.night
              ? LlmertaPalette.ink.withValues(alpha: 0.45)
              : LlmertaPalette.parchment.withValues(alpha: 0.10),
        ),
        Column(
          children: [
            const _StatusStrip(),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: SeatRing()),
                  // The overlay owns the night narration — never both.
                  if (!passiveNight) const Center(child: _CenterStage()),
                  if (passiveNight)
                    Positioned.fill(
                      child: NightOverlay(
                        spentAssassinNotice:
                            view.humanRole == Role.assassin &&
                            view.bulletSpentNight != null &&
                            view.day == view.bulletSpentNight! + 1,
                      ),
                    ),
                ],
              ),
            ),
            const HumanDock(),
          ],
        ),
      ],
    );
  }
}

class _StatusStrip extends ConsumerWidget {
  const _StatusStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final view = ref.watch(tableViewProvider);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.75),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Text(
              session.townName ?? '',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Chip(
                visualDensity: VisualDensity.compact,
                label: Text(view.banner, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (view.humanRole != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.badge_outlined, size: 14),
                  label: Text(
                    'You are the ${view.humanRole!.name}'
                    '${view.humanRole == Role.assassin
                        ? view.humanBulletSpent
                              ? ' · bullet spent'
                              : ' · bullet unspent'
                        : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            const Spacer(),
            const _VoicesButton(),
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Transcript',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            const _NotesButton(),
            IconButton(
              tooltip: 'Leave the table',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLeave(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave the table?'),
        content: const Text(
          'The game is saved at the last phase boundary — resume it '
          'anytime from Continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save & leave'),
          ),
        ],
      ),
    );
    if (leave != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(gameSessionControllerProvider.notifier).abandonGame();
    navigator.pop();
  }
}

/// Three honest states: speaking, muted, and "enabled but nothing to
/// speak with" — the last one used to masquerade as working (field
/// report: silent table, no hint why).
class _VoicesButton extends ConsumerWidget {
  const _VoicesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(ttsEnabledProvider);
    final stack = ref.watch(ttsStackProvider);
    if (enabled && stack == null) {
      return IconButton(
        tooltip: 'No voices downloaded — get them in Settings → Voices',
        icon: Icon(
          Icons.voice_over_off,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: () =>
            Navigator.of(context).push(SettingsScreen.route(initialSection: 2)),
      );
    }
    return IconButton(
      tooltip: enabled ? 'Mute voices' : 'Unmute voices',
      icon: Icon(enabled ? Icons.volume_up : Icons.volume_off),
      onPressed: () => ref.read(ttsEnabledProvider.notifier).set(!enabled),
    );
  }
}

class _NotesButton extends ConsumerWidget {
  const _NotesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Notes',
      icon: const Icon(Icons.edit_note),
      onPressed: () {
        final controller = TextEditingController(
          text: ref.read(gameSessionControllerProvider).notes,
        );
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Private notes'),
            content: SizedBox(
              width: 420,
              child: TextField(
                controller: controller,
                maxLines: 10,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Suspicions, claims, vote patterns…',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Persisted with the save (UI_UX.md §2 notes panel).
                  ref
                      .read(gameSessionControllerProvider.notifier)
                      .setNotes(controller.text);
                  Navigator.of(context).pop();
                },
                child: const Text('Save notes'),
              ),
            ],
          ),
        ).then((_) => controller.dispose());
      },
    );
  }
}

class _CenterStage extends ConsumerWidget {
  const _CenterStage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final view = ref.watch(tableViewProvider);
    final scheme = Theme.of(context).colorScheme;
    final speech = view.activeSpeech;
    // One scrim panel for everything: scenes are arbitrary images, so
    // theme ink straight on the backdrop was illegible (field report).
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                view.banner,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (view.narratorLine != null) ...[
                const SizedBox(height: 8),
                Text(
                  view.narratorLine!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
              if (speech != null) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: scheme.outline.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 10),
                Text(
                  session.names[speech.$1],
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: 4),
                // Words track the voice when this exact line is being
                // spoken; otherwise the full text shows immediately.
                if (ref.watch(nowSpeakingProvider) case (
                  final spokenText,
                  final startedAt,
                  final audioLength,
                ) when spokenText == speech.$2)
                  SpokenText(
                    text: speech.$2,
                    startedAt: startedAt,
                    duration: audioLength,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text(
                    speech.$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
              // The verdict, out in the open: tally first, ballots under.
              if (view.lastVotes.isNotEmpty && session.names.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: scheme.outline.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 10),
                Text(
                  voteTally(view.lastVotes, session.names),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 3,
                  children: [
                    for (final MapEntry(key: voter, value: target)
                        in view.lastVotes.entries)
                      Text(
                        '${session.names[voter]} → '
                        '${target == null ? 'abstain' : session.names[target]}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Silas 4 · Morgana 2 · abstain 1" — heaviest first.
String voteTally(Map<int, int?> votes, List<String> names) {
  final counts = <int, int>{};
  var abstain = 0;
  for (final target in votes.values) {
    if (target == null) {
      abstain++;
    } else {
      counts[target] = (counts[target] ?? 0) + 1;
    }
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final entry in ranked) '${names[entry.key]} ${entry.value}',
    if (abstain > 0) 'abstain $abstain',
  ].join('  ·  ');
}
