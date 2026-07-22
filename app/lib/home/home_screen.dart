import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Continue needs saves (M3.6); the rules primer ships with first-run (M7).
  bool get enabled => switch (this) {
    newGame || replays || settings => true,
    continueGame || howToPlay => false,
  };
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, HomeAction action) {
    final route = switch (action) {
      HomeAction.newGame => LobbyScreen.route(),
      HomeAction.settings => SettingsScreen.route(),
      HomeAction.replays => ReplaysScreen.route(),
      HomeAction.continueGame || HomeAction.howToPlay => null,
    };
    if (route != null) Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
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
                    onPressed: action.enabled
                        ? () => _open(context, action)
                        : null,
                    child: Text(action.label),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
