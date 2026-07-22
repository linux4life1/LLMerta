import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lobby_draft.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LobbyScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(lobbyDraftProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup')),
      body: Center(
        child: Text(
          '${draft.seats} seats at the table — casting, scenes, and rules '
          'land with M3.3.',
        ),
      ),
    );
  }
}
