// M0 spike 2: WAV playback via audioplayers (Front Porch AI's player choice).
// Pass = a generated WAV plays to completion and onPlayerComplete fires.
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_spikes/wav.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plays a generated WAV to completion', (tester) async {
    // Sandboxed container Caches dir may not exist on first run; audioplayers'
    // BytesSource also writes temp files here, so create it up front.
    final dir = await getTemporaryDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}/spike_sine.wav');
    await file.writeAsBytes(sineWav(seconds: 1.2));

    final player = AudioPlayer();
    final completed = player.onPlayerComplete.first;
    final sw = Stopwatch()..start();
    await player.play(DeviceFileSource(file.path));
    await completed.timeout(const Duration(seconds: 10));
    sw.stop();

    // Completion must arrive roughly after the clip's real duration —
    // proves actual playback, not an immediate synthetic event.
    expect(sw.elapsedMilliseconds, greaterThan(800));
    await player.dispose();
  });

  testWidgets('plays from in-memory bytes (BytesSource)', (tester) async {
    final player = AudioPlayer();
    final completed = player.onPlayerComplete.first;
    await player.play(
      BytesSource(sineWav(freqHz: 660, seconds: 0.8), mimeType: 'audio/wav'),
    );
    await completed.timeout(const Duration(seconds: 10));
    await player.dispose();
  });
}
