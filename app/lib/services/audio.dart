import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:tts/tts.dart';

/// audioplayers-backed playback (spike 2): BytesSource must carry an
/// explicit audio/wav mimeType on macOS or playback silently fails.
class AudioplayersWavPlayer implements WavPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play(Uint8List wavBytes) async {
    final done = _player.onPlayerComplete.first;
    await _player.play(BytesSource(wavBytes, mimeType: 'audio/wav'));
    await done;
  }

  @override
  void stop() => _player.stop();

  void dispose() => _player.dispose();
}
