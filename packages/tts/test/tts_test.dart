import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:tts/tts.dart';

class _FakeEngine implements TtsEngine {
  final synthesized = <String>[];
  final started = <String>[];
  Duration latency = Duration.zero;

  @override
  Future<TtsAudio> synthesize(
    String text,
    Voice voice, {
    double speed = 1.0,
  }) async {
    started.add(text);
    await Future<void>.delayed(latency);
    synthesized.add(text);
    return TtsAudio(
      wavBytes: Uint8List.fromList(text.codeUnits),
      sampleRate: 22050,
      duration: const Duration(milliseconds: 500),
    );
  }
}

class _FakePlayer implements WavPlayer {
  final played = <String>[];
  final playbackStarted = <String>[];
  Completer<void>? gate;

  @override
  Future<void> play(Uint8List wavBytes) async {
    final text = String.fromCharCodes(wavBytes);
    playbackStarted.add(text);
    if (gate != null) await gate!.future;
    played.add(text);
  }

  @override
  void stop() => gate?.complete();
}

Voice _voice() => Voice(
  bundle: VoiceBundle(kind: VoiceBundleKind.piper, dir: Directory('/tmp/v')),
);

void main() {
  test('wav header is well-formed PCM16 mono', () {
    final wav = sineWav(seconds: 0.1, sampleRate: 16000);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    final bd = ByteData.sublistView(wav);
    expect(bd.getUint16(22, Endian.little), 1, reason: 'mono');
    expect(bd.getUint32(24, Endian.little), 16000);
    expect(bd.getUint16(34, Endian.little), 16, reason: 'PCM16');
    expect(wav.length, 44 + 1600 * 2);
  });

  test('queue plays in order and pipelines the next synthesis', () async {
    final engine = _FakeEngine();
    final player = _FakePlayer()..gate = Completer<void>();
    final queue = SpeechQueue(engine: engine, player: player);
    addTearDown(queue.dispose);

    queue
      ..add(SpeechItem(id: 1, text: 'first', voice: _voice()))
      ..add(SpeechItem(id: 2, text: 'second', voice: _voice()));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // While 'first' is still playing, 'second' must already be synthesizing.
    expect(player.playbackStarted, ['first']);
    expect(player.played, isEmpty);
    expect(engine.started, contains('second'));

    player.gate!.complete();
    player.gate = null;
    await queue.events.firstWhere((e) => e is QueueDrained);
    expect(player.played, ['first', 'second']);
  });

  test('queue caches synthesis by voice and text', () async {
    final engine = _FakeEngine();
    final player = _FakePlayer();
    final queue = SpeechQueue(engine: engine, player: player);
    addTearDown(queue.dispose);
    queue.add(SpeechItem(id: 1, text: 'again', voice: _voice()));
    await queue.events.firstWhere((e) => e is QueueDrained);
    queue.add(SpeechItem(id: 2, text: 'again', voice: _voice()));
    await queue.events.firstWhere((e) => e is QueueDrained);
    expect(engine.synthesized, hasLength(1));
    expect(player.played, hasLength(2));
  });

  test('muting clears the backlog and stops playback', () async {
    final engine = _FakeEngine()..latency = const Duration(milliseconds: 5);
    final player = _FakePlayer();
    final queue = SpeechQueue(engine: engine, player: player);
    addTearDown(queue.dispose);
    queue
      ..add(SpeechItem(id: 1, text: 'a', voice: _voice()))
      ..add(SpeechItem(id: 2, text: 'b', voice: _voice()))
      ..muted = true;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(queue.backlog, 0);
    queue.add(SpeechItem(id: 3, text: 'c', voice: _voice()));
    expect(queue.backlog, 0, reason: 'muted queue rejects new items');
  });

  test('piper validation demands model, tokens, espeak data', () async {
    final tmp = await Directory.systemTemp.createTemp('llmerta-piper');
    addTearDown(() => tmp.delete(recursive: true));
    expect(validatePiperDir(Directory('${tmp.path}/nope')), isNotNull);
    expect(validatePiperDir(tmp), contains('no .onnx'));
    File('${tmp.path}/v.onnx').writeAsBytesSync(const [1]);
    expect(validatePiperDir(tmp), contains('tokens.txt'));
    File('${tmp.path}/tokens.txt').writeAsStringSync('a');
    expect(validatePiperDir(tmp), contains('espeak-ng-data'));
    Directory('${tmp.path}/espeak-ng-data').createSync();
    expect(validatePiperDir(tmp), isNull);
    expect(detectPiperBundle(candidates: [tmp.path])?.dir.path, tmp.path);
  });

  test('kokoro validation rejects the legacy npz trap explicitly', () async {
    final tmp = await Directory.systemTemp.createTemp('llmerta-kokoro');
    addTearDown(() => tmp.delete(recursive: true));
    File('${tmp.path}/kokoro-v1_0.npz').writeAsBytesSync(const [1]);
    expect(validateKokoroDir(tmp), contains('npz'));

    final good = await Directory.systemTemp.createTemp('llmerta-kokoro2');
    addTearDown(() => good.delete(recursive: true));
    for (final f in ['model.onnx', 'voices.bin', 'tokens.txt']) {
      File('${good.path}/$f').writeAsBytesSync(const [1]);
    }
    expect(validateKokoroDir(good), contains('espeak-ng-data'));
    Directory('${good.path}/espeak-ng-data').createSync();
    expect(validateKokoroDir(good), isNull);
    expect(detectKokoroBundle(candidates: [good.path]), isNotNull);
  });

  test('voice assignment rotates seats and separates the narrator', () {
    final bundle = VoiceBundle(
      kind: VoiceBundleKind.kokoro,
      dir: Directory('/tmp/k'),
    );
    final speakers = kokoroSpeakers(bundle, count: 5);
    expect(speakers.map((v) => v.speakerId).toSet(), hasLength(5));
    final cast = assignVoices(seats: 7, available: speakers);
    expect(cast.bySeat, hasLength(7));
    expect(cast.bySeat[0]!.speakerId, cast.bySeat[5]!.speakerId);
    expect(cast.narrator.speakerId, isNot(cast.bySeat[0]!.speakerId));
  });

  test('downloader extracts a tar.bz2 voice bundle', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('voice-dir/tokens.txt', 5, 'a b c'.codeUnits))
      ..addFile(ArchiveFile('voice-dir/v.onnx', 3, const [1, 2, 3]));
    final tarBytes = TarEncoder().encode(archive);
    final bz2 = BZip2Encoder().encode(tarBytes);

    final downloader = VoiceDownloader(
      httpClient: MockClient((request) async => http.Response.bytes(bz2, 200)),
    );
    final into = await Directory.systemTemp.createTemp('llmerta-dl');
    addTearDown(() => into.delete(recursive: true));
    var lastReceived = 0;
    final dir = await downloader.download(
      const WellKnownVoice(
        name: 'test',
        url: 'https://example.test/voice-dir.tar.bz2',
        dirName: 'voice-dir',
      ),
      into,
      onProgress: (received, total) => lastReceived = received,
    );
    expect(lastReceived, bz2.length);
    expect(File('${dir.path}/tokens.txt').readAsStringSync(), 'a b c');
    expect(File('${dir.path}/v.onnx').existsSync(), isTrue);
  });
}
