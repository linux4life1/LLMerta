import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/home.dart';
import 'theme/theme.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Limelight', 'LibreFranklin']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/OFL-$font.txt'));
    }
  });
  runApp(const ProviderScope(child: LlmertaApp()));
}

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
