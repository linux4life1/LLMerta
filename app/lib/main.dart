import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tts/tts.dart';

import 'home/home.dart';
import 'services/services.dart';
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
  // Hidden field diagnostic: LLMERTA_TTS_PROBE=1 <app binary> exercises
  // the full voice path (detect → worker synth → playback) with results
  // on stderr, in the exact shipped configuration.
  if (Platform.environment['LLMERTA_TTS_PROBE'] == '1') {
    Timer(const Duration(seconds: 2), () => unawaited(_ttsProbe()));
  }
}

Future<void> _ttsProbe() async {
  void say(String line) => stderr.writeln('[tts-probe] $line');
  try {
    final support = await getApplicationSupportDirectory();
    final bundle = detectKokoroBundle(
      candidates: ['${support.path}/voices/${kokoroV1.dirName}'],
    );
    say('bundle: ${bundle?.dir.path ?? 'NOT FOUND'}');
    if (bundle == null) exit(2);
    final engine = SherpaTtsEngine();
    final audio = await engine.synthesize(
      'The town sleeps, but I never do.',
      Voice(bundle: bundle, speakerId: 4, label: 'probe'),
    );
    say(
      'synth OK: ${audio.wavBytes.length} bytes, '
      '${audio.duration.inMilliseconds} ms',
    );
    await AudioplayersWavPlayer().play(audio.wavBytes);
    say('play() returned — listen for audio');
    await Future<void>.delayed(const Duration(seconds: 5));
    exit(0);
  } catch (error, stack) {
    say('FAILED: $error');
    say('$stack');
    exit(1);
  }
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
