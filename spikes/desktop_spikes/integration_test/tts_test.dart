// M0 spike 5: sherpa_onnx TTS round-trip — load a Piper (VITS) voice and
// Kokoro, synthesize a line, play it back via audioplayers.
// Model dirs are looked up under spikes/models/ (gitignored); a missing dir
// fails with a clear message telling you what to download.
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_spikes/wav.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

const modelsRoot = String.fromEnvironment(
  'SPIKE_MODELS',
  defaultValue: '/Users/linux4life/dev/Mafia/spikes/models',
);

const line = 'I am not the mafia, and I vote to eliminate seat four.';

Future<void> synthesizeAndPlay(
  sherpa.OfflineTtsConfig config, {
  required int sid,
}) async {
  final tts = sherpa.OfflineTts(config);
  final sw = Stopwatch()..start();
  final audio = tts.generate(text: line, sid: sid, speed: 1.0);
  final synthMs = sw.elapsedMilliseconds;
  tts.free();

  expect(audio.samples, isNotEmpty);
  expect(audio.sampleRate, greaterThan(8000));
  final seconds = audio.samples.length / audio.sampleRate;
  expect(seconds, greaterThan(1.0));
  // ignore: avoid_print
  print('SPIKE5: synthesized ${seconds.toStringAsFixed(2)}s '
      'at ${audio.sampleRate}Hz in ${synthMs}ms '
      '(${(seconds * 1000 / synthMs).toStringAsFixed(1)}x realtime)');

  final dir = await getTemporaryDirectory();
  await dir.create(recursive: true);
  final wav = File('${dir.path}/spike_tts_$sid.wav');
  await wav.writeAsBytes(wavFromSamples(audio.samples, audio.sampleRate));
  final player = AudioPlayer();
  final done = player.onPlayerComplete.first;
  await player.play(DeviceFileSource(wav.path));
  await done.timeout(const Duration(seconds: 30));
  await player.dispose();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sherpa.initBindings();

  testWidgets('Piper (VITS) voice synthesizes and plays', (tester) async {
    final dir = '$modelsRoot/vits-piper-en_US-lessac-medium';
    expect(
      Directory(dir).existsSync(),
      isTrue,
      reason: 'missing $dir — download vits-piper-en_US-lessac-medium '
          '(model, tokens.txt, espeak-ng-data)',
    );
    await synthesizeAndPlay(
      sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: '$dir/en_US-lessac-medium.onnx',
            tokens: '$dir/tokens.txt',
            dataDir: '$dir/espeak-ng-data',
          ),
          numThreads: 2,
          debug: false,
        ),
      ),
      sid: 0,
    );
  });

  testWidgets('Kokoro voice synthesizes and plays', (tester) async {
    final dir = '$modelsRoot/kokoro-v1.0';
    expect(
      Directory(dir).existsSync(),
      isTrue,
      reason: 'missing $dir — needs model.onnx, voices.bin, tokens.txt, '
          'espeak-ng-data (model+voices already on disk from Front Porch AI)',
    );
    await synthesizeAndPlay(
      sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          kokoro: sherpa.OfflineTtsKokoroModelConfig(
            model: '$dir/model.onnx',
            voices: '$dir/voices.bin',
            tokens: '$dir/tokens.txt',
            dataDir: '$dir/espeak-ng-data',
            lexicon: '$dir/lexicon-us-en.txt,$dir/lexicon-zh.txt',
            dictDir: '$dir/dict',
          ),
          numThreads: 2,
          debug: true,
        ),
      ),
      sid: 0,
    );
  });
}
