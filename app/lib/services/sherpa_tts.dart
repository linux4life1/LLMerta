import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:tts/tts.dart';

/// sherpa_onnx-backed engine (spike 5): Piper VITS and Kokoro in-process.
/// Bundles are validated before any native load — the legacy npz Kokoro
/// files would hard-crash the process otherwise.
///
/// Synthesis runs in a dedicated worker isolate: `generate()` is a
/// blocking FFI call that takes seconds per line, and the speech queue
/// pipelines it continuously — on the UI isolate that beachballed the
/// whole table (field report, v0.1.1).
class SherpaTtsEngine implements TtsEngine {
  SherpaTtsEngine();

  Future<SendPort>? _worker;

  Future<SendPort> _ensureWorker() => _worker ??= () async {
    final ready = ReceivePort();
    await Isolate.spawn(
      _synthesisWorker,
      ready.sendPort,
      debugName: 'llmerta-tts',
    );
    return await ready.first as SendPort;
  }();

  @override
  Future<TtsAudio> synthesize(
    String text,
    Voice voice, {
    double speed = 1.0,
  }) async {
    final error = switch (voice.bundle.kind) {
      VoiceBundleKind.piper => validatePiperDir(voice.bundle.dir),
      VoiceBundleKind.kokoro => validateKokoroDir(voice.bundle.dir),
    };
    if (error != null) throw TtsUnavailable(error);

    final commands = await _ensureWorker();
    final reply = ReceivePort();
    commands.send([
      reply.sendPort,
      voice.bundle.kind.name,
      voice.bundle.dir.path,
      voice.speakerId,
      speed,
      text,
    ]);
    final result = await reply.first;
    reply.close();
    if (result is! Map) throw TtsUnavailable('$result');
    final wav = result['wav'] as Uint8List;
    final sampleRate = result['rate'] as int;
    final samples = result['samples'] as int;
    return TtsAudio(
      wavBytes: wav,
      sampleRate: sampleRate,
      duration: Duration(milliseconds: (samples * 1000 / sampleRate).round()),
    );
  }

  void dispose() {
    _worker?.then((port) => port.send('dispose'));
    _worker = null;
  }
}

void _synthesisWorker(SendPort ready) {
  final commands = ReceivePort();
  ready.send(commands.sendPort);
  var bindingsReady = false;
  final sessions = <String, sherpa.OfflineTts>{};

  commands.listen((message) {
    if (message == 'dispose') {
      for (final session in sessions.values) {
        session.free();
      }
      sessions.clear();
      commands.close();
      return;
    }
    final [
      SendPort reply,
      String kind,
      String dir,
      int speakerId,
      double speed,
      String text,
    ] = message as List;
    try {
      if (!bindingsReady) {
        sherpa.initBindings();
        bindingsReady = true;
      }
      final session = sessions[dir] ??= sherpa.OfflineTts(
        _configFor(VoiceBundleKind.values.byName(kind), dir),
      );
      final audio = session.generate(text: text, sid: speakerId, speed: speed);
      final samples = Float32List.fromList(audio.samples);
      reply.send({
        'wav': wavFromSamples(samples, audio.sampleRate),
        'rate': audio.sampleRate,
        'samples': samples.length,
      });
    } catch (error) {
      reply.send('$error');
    }
  });
}

sherpa.OfflineTtsConfig _configFor(VoiceBundleKind kind, String dir) =>
    switch (kind) {
      VoiceBundleKind.piper => sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: Directory(dir)
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
