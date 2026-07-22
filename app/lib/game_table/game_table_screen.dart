import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:game_core/game_core.dart' show Role;

import '../lobby/lobby.dart' show sceneDecoration;
import '../theme/theme.dart';
import 'game_session.dart';
import 'human_dock.dart';
import 'night_overlay.dart';
import 'seat_ring.dart';
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
                  const Center(child: _CenterStage()),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
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
            Material(
              color: scheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.names[speech.$1],
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LlmertaPalette.brass,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      speech.$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
