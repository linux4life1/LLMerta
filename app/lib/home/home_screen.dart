import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MAFIA',
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
                    onPressed: null,
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
