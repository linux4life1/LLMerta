import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;

class WellKnownVoice {
  const WellKnownVoice({
    required this.name,
    required this.url,
    required this.dirName,
  });

  final String name;
  final String url;
  final String dirName;
}

/// The zero-setup Piper voice (spike-5 proven, ~64 MB).
const piperLessac = WellKnownVoice(
  name: 'Piper — en_US lessac (medium)',
  url:
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-lessac-medium.tar.bz2',
  dirName: 'vits-piper-en_US-lessac-medium',
);

/// Kokoro v1.0, 53 speakers — the same sherpa bundle layout FPA ships,
/// fetched from the official sherpa-onnx releases (~330 MB).
const kokoroV1 = WellKnownVoice(
  name: 'Kokoro v1.0 — 53 speakers',
  url:
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-multi-lang-v1_0.tar.bz2',
  dirName: 'kokoro-multi-lang-v1_0',
);

class VoiceDownloader {
  VoiceDownloader({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Streams the archive to disk (bundles run to hundreds of MB — never
  /// buffered in RAM), then extracts into [into]; returns the voice
  /// directory. Progress is bytes-received over total (-1 unknown); the
  /// unpack phase reports progress == total.
  Future<Directory> download(
    WellKnownVoice voice,
    Directory into, {
    void Function(int received, int total)? onProgress,
  }) async {
    await into.create(recursive: true);
    final response = await _http.send(
      http.Request('GET', Uri.parse(voice.url)),
    );
    if (response.statusCode != 200) {
      throw HttpException('GET ${voice.url} -> ${response.statusCode}');
    }
    final total = response.contentLength ?? -1;
    // extractFileToDisk dispatches on the extension — keep the real one.
    final archiveName = voice.url.split('/').last;
    final tmp = File('${into.path}/.dl-$archiveName');
    final sink = tmp.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
    } finally {
      await sink.close();
    }

    final target = Directory('${into.path}/${voice.dirName}');
    if (archiveName.endsWith('.tar.bz2')) {
      onProgress?.call(total < 0 ? received : total, total);
      await extractFileToDisk(tmp.path, into.path);
      await tmp.delete();
    } else {
      await target.create(recursive: true);
      await tmp.rename('${target.path}/$archiveName');
    }
    return target;
  }

  void close() => _http.close();
}
