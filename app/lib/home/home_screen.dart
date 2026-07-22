import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_table/game_table.dart';
import '../lobby/lobby.dart';
import '../replays/replays.dart';
import '../services/services.dart';
import '../settings/settings.dart';
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'LLMerta',
                style: text.displayMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                'Fourteen seats at the table. One of them is human.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              for (final action in HomeAction.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: switch (action) {
                      HomeAction.newGame => () => Navigator.of(
                        context,
                      ).push(LobbyScreen.route()),
                      HomeAction.continueGame when resumable != null =>
                        () async {
                          final navigator = Navigator.of(context);
                          await ref
                              .read(gameSessionControllerProvider.notifier)
                              .resumeGame(resumable.id);
                          unawaited(navigator.push(GameTableScreen.route()));
                        },
                      HomeAction.replays => () => Navigator.of(
                        context,
                      ).push(ReplaysScreen.route()),
                      HomeAction.settings => () => Navigator.of(
                        context,
                      ).push(SettingsScreen.route()),
                      HomeAction.howToPlay => () => RulesPrimer.show(context),
                      // Continue still needs an unfinished save.
                      _ => null,
                    },
                    child: Text(
                      action == HomeAction.continueGame && resumable != null
                          ? 'Continue — ${resumable.townName}'
                          : action.label,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
            '1. Add a model connection (a local server like oMLX or a '
            'hosted API) under Settings → Connections and hit Test.\n'
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
