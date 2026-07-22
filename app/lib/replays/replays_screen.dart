import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReplaysScreen extends ConsumerWidget {
  const ReplaysScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const ReplaysScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Replays')),
      body: const Center(
        child: Text('Step through finished games once saves exist (M3.6).'),
      ),
    );
  }
}
