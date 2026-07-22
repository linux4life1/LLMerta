import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameTableScreen extends ConsumerWidget {
  const GameTableScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const GameTableScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(
        child: Text(
          'The table is being set — seating over scenes lands with M3.4.',
        ),
      ),
    );
  }
}
