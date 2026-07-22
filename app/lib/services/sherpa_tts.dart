import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:tts/tts.dart';

/// sherpa_onnx-backed engine (spike 5): Piper VITS and Kokoro in-process.
/// Bundles are validated before any native load — the legacy npz Kokoro
/// files would hard-crash the process otherwise.
class SherpaTtsEngine implements TtsEngine {
  SherpaTtsEngine();

  static var _bindingsReady = false;
  final _sessions = <String, sherpa.OfflineTts>{};

  sherpa.OfflineTts _sessionFor(VoiceBundle bundle) {
    final cached = _sessions[bundle.dir.path];
    if (cached != null) return cached;
    final error = switch (bundle.kind) {
      VoiceBundleKind.piper => validatePiperDir(bundle.dir),
      VoiceBundleKind.kokoro => validateKokoroDir(bundle.dir),
    };
    if (error != null) throw TtsUnavailable(error);
    if (!_bindingsReady) {
      sherpa.initBindings();
      _bindingsReady = true;
    }
    final dir = bundle.dir.path;
    final config = switch (bundle.kind) {
      VoiceBundleKind.piper => sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: bundle.dir
                .listSync()
                .map((e) => e.path)
                .firstWhere((p) => p.endsWith('.onnx')),
            tokens: '$dir/tokens.txt',
            dataDir: '$dir/espeak-ng-data',
          ),
          numThreads: 2,
        ),
      ),
      VoiceBundleKind.kokoro => sherpa.OfflineTtsConfig(
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
        ),
      ),
    };
    final session = sherpa.OfflineTts(config);
    _sessions[bundle.dir.path] = session;
    return session;
  }

  @override
  Future<TtsAudio> synthesize(
    String text,
    Voice voice, {
    double speed = 1.0,
  }) async {
    try {
      final session = _sessionFor(voice.bundle);
      final audio = session.generate(
        text: text,
        sid: voice.speakerId,
        speed: speed,
      );
      final samples = Float32List.fromList(audio.samples);
      return TtsAudio(
        wavBytes: wavFromSamples(samples, audio.sampleRate),
        sampleRate: audio.sampleRate,
        duration: Duration(
          milliseconds: (samples.length * 1000 / audio.sampleRate).round(),
        ),
      );
    } on TtsUnavailable {
      rethrow;
    } catch (error) {
      throw TtsUnavailable('$error');
    }
  }

  void dispose() {
    for (final session in _sessions.values) {
      session.free();
    }
    _sessions.clear();
  }
}
