import 'dart:typed_data';

import 'voices.dart';

class TtsAudio {
  const TtsAudio({
    required this.wavBytes,
    required this.sampleRate,
    required this.duration,
  });

  final Uint8List wavBytes;
  final int sampleRate;
  final Duration duration;
}

class TtsUnavailable implements Exception {
  const TtsUnavailable(this.message);

  final String message;

  @override
  String toString() => 'TtsUnavailable: $message';
}

/// One engine per app; voices select the model/speaker. The sherpa_onnx
/// implementation (Piper VITS + Kokoro, spike-5 proven) lives on the app
/// side — this package stays free of native dependencies.
abstract interface class TtsEngine {
  Future<TtsAudio> synthesize(String text, Voice voice, {double speed = 1.0});
}
