import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_table/game_table.dart';
import '../lobby/lobby.dart';
import '../replays/replays.dart';
import '../services/services.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import 'rules_primer.dart';

enum HomeAction {
  newGame('New Game'),
  continueGame('Continue'),
  replays('Replays'),
  settings('Settings'),
  howToPlay('How to play');

  const HomeAction(this.label);

  final String label;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final games = ref.watch(savedGamesProvider).value ?? const [];
    final resumable = games.where((g) => !g.finished).firstOrNull;
    _offerFirstRun(context, ref);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: ParlorBackdropPainter()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LLMerta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Limelight',
                      fontSize: 72,
                      height: 1.05,
                      letterSpacing: 3,
                      color: LlmertaPalette.brass,
                      shadows: [
                        const Shadow(
                          offset: Offset(0, 2),
                          color: Colors.black54,
                        ),
                        Shadow(
                          blurRadius: 40,
                          color: LlmertaPalette.brass.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Seven to fourteen seats at the table. '
                    'One of them is human.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: LlmertaPalette.boneDim,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () =>
                        Navigator.of(context).push(LobbyScreen.route()),
                    child: Text(HomeAction.newGame.label.toUpperCase()),
                  ),
                  // No dead grey bar: the slot only exists with a live save.
                  if (resumable != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await ref
                            .read(gameSessionControllerProvider.notifier)
                            .resumeGame(resumable.id);
                        unawaited(navigator.push(GameTableScreen.route()));
                      },
                      child: Text('Continue — ${resumable.townName}'),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      _QuietAction(
                        label: HomeAction.replays.label,
                        onPressed: () =>
                            Navigator.of(context).push(ReplaysScreen.route()),
                      ),
                      _QuietAction(
                        label: HomeAction.settings.label,
                        onPressed: () =>
                            Navigator.of(context).push(SettingsScreen.route()),
                      ),
                      _QuietAction(
                        label: HomeAction.howToPlay.label,
                        onPressed: () => RulesPrimer.show(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 14, child: _Footer()),
        ],
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: LlmertaPalette.boneDim),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value ?? '';
    return Text(
      '${version.isEmpty ? '' : 'v$version · '}local-first · '
      'your table, your keys',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: LlmertaPalette.boneDim.withValues(alpha: 0.5),
        letterSpacing: 0.8,
      ),
    );
  }
}

/// The parlor: espresso gradient, a faint honey glow from below, and a
/// fourteen-seat ring behind the menu — one seat lit ivory. Static paint,
/// cheap every frame, identical in goldens.
class ParlorBackdropPainter extends CustomPainter {
  const ParlorBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1813), LlmertaPalette.ink],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.2),
          radius: 1.1,
          colors: [
            LlmertaPalette.brass.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) * 0.42;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = LlmertaPalette.brass.withValues(alpha: 0.13),
    );
    const seats = 14;
    for (var i = 0; i < seats; i++) {
      final angle = pi / 2 + 2 * pi * i / seats;
      final dot = center + Offset(cos(angle), sin(angle)) * radius;
      final isHuman = i == 0;
      canvas.drawCircle(
        dot,
        isHuman ? 6.0 : 4.5,
        Paint()
          ..color = isHuman
              ? LlmertaPalette.bone.withValues(alpha: 0.9)
              : LlmertaPalette.brassDeep.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(ParlorBackdropPainter oldDelegate) => false;
}

extension on HomeScreen {
  /// First-run setup check (UI_UX.md §5): once, after first frame.
  void _offerFirstRun(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = ref.read(appDatabaseProvider);
      try {
        if (await db.pref('firstRunSeen') != null) return;
        await db.setPref('firstRunSeen', 'true');
      } on Exception {
        return; // No DB (tests without override): skip quietly.
      }
      if (!context.mounted) return;
      final toSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Welcome to LLMerta'),
          content: const Text(
            'Two minutes of setup and the town is yours:\n\n'
            '1. Add a model connection under Settings → Connections — '
            'local servers are found automatically, hosted ones just '
            'need a key.\n'
            '2. Optional: voices under Settings → Voices — fully '
            'offline.\n'
            '3. Skim How to play if Mafia is new to you.\n\n'
            'Then New Game, cast your table, and deal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("I'm set"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (toSettings == true && context.mounted) {
        await Navigator.of(context).push(SettingsScreen.route());
      }
    });
  }
}
