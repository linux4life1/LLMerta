import 'dart:math' as math;
import 'dart:typed_data';

/// 16-bit PCM mono WAV writer (spike-2/5 proven; audioplayers needs a
/// well-formed header plus an explicit audio/wav mimeType on macOS).
Uint8List wavFromSamples(Float32List samples, int sampleRate) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(
      44 + i * 2,
      (samples[i].clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

Uint8List sineWav({
  double freqHz = 440,
  double seconds = 1.0,
  int sampleRate = 22050,
}) {
  final n = (seconds * sampleRate).round();
  final samples = Float32List(n);
  for (var i = 0; i < n; i++) {
    samples[i] = 0.4 * math.sin(2 * math.pi * freqHz * i / sampleRate);
  }
  return wavFromSamples(samples, sampleRate);
}
