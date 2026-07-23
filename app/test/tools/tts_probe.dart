// Local diagnostic — run by hand, never in CI:
//   flutter test test/tools/tts_probe.dart
// Synthesizes through the real worker-isolate engine against the real
// downloaded bundle and writes a WAV to the system temp dir.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/services/sherpa_tts.dart';
import 'package:tts/tts.dart';

void main() {
  testWidgets('probe: synthesize with the user-downloaded kokoro bundle', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final home = Platform.environment['HOME']!;
      final dir = Directory(
        '$home/Library/Application Support/com.antigravity.llmerta/'
        'voices/kokoro-multi-lang-v1_0',
      );
      // ignore: avoid_print
      print('validate: ${validateKokoroDir(dir) ?? 'OK'}');
      final bundle = detectKokoroBundle(candidates: [dir.path]);
      // ignore: avoid_print
      print('detected: ${bundle?.dir.path}');
      if (bundle == null) return;

      final engine = SherpaTtsEngine();
      try {
        final audio = await engine
            .synthesize(
              'The town sleeps, but I never do.',
              Voice(bundle: bundle, speakerId: 4, label: 'probe'),
            )
            .timeout(const Duration(minutes: 3));
        // ignore: avoid_print
        print(
          'SYNTH-OK bytes=${audio.wavBytes.length} '
          'rate=${audio.sampleRate} dur=${audio.duration}',
        );
        File(
          '${Directory.systemTemp.path}/llmerta-probe.wav',
        ).writeAsBytesSync(audio.wavBytes);
      } catch (error) {
        // ignore: avoid_print
        print('SYNTH-FAILED: $error');
      } finally {
        engine.dispose();
      }
    });
  });
}
