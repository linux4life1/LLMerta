import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tts/tts.dart';

/// audioplayers-backed playback (spike 2): BytesSource must carry an
/// explicit audio/wav mimeType on macOS or playback silently fails.
///
/// BytesSource is staged as a file in the app's Caches directory, which
/// audioplayers assumes exists but never creates — on a fresh install
/// every play() threw PathNotFoundException and voices were silent for
/// three releases (v0.1.5 field diagnosis). Ensure it once.
class AudioplayersWavPlayer implements WavPlayer {
  final _player = AudioPlayer();
  Future<void>? _cacheDirReady;

  Future<void> _ensureCacheDir() => _cacheDirReady ??= () async {
    try {
      await (await getApplicationCacheDirectory()).create(recursive: true);
    } on Exception {
      // Tests / platforms without the provider: let play() surface it.
    }
  }();

  @override
  Future<void> play(Uint8List wavBytes) async {
    await _ensureCacheDir();
    final done = _player.onPlayerComplete.first;
    await _player.play(BytesSource(wavBytes, mimeType: 'audio/wav'));
    await done;
  }

  @override
  void stop() => _player.stop();

  void dispose() => _player.dispose();
}
