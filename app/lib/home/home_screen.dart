import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_table/game_table.dart';
import '../lobby/lobby.dart';
import '../replays/replays.dart';
import '../settings/settings.dart';

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
                      // Needs a save to continue; primer ships with M7.
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
