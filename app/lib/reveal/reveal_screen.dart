import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RevealScreen extends ConsumerWidget {
  const RevealScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const RevealScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('The Reveal')),
      body: const Center(
        child: Text('Roles, reasoning, and table talk land with M3.6.'),
      ),
    );
  }
}
