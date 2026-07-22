import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/home.dart';
import 'theme/theme.dart';

void main() => runApp(const ProviderScope(child: LlmertaApp()));

class LlmertaApp extends StatelessWidget {
  const LlmertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LLMerta',
      theme: LlmertaTheme.night,
      home: const HomeScreen(),
    );
  }
}
