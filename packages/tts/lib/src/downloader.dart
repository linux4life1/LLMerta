import 'dart:io';

import 'package:archive/archive.dart';
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

class VoiceDownloader {
  VoiceDownloader({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Downloads and (for .tar.bz2) extracts into [into]; returns the
  /// voice directory. Progress is bytes-received over total (-1 unknown).
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
    final bytes = <int>[];
    var received = 0;
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      onProgress?.call(received, total);
    }

    final target = Directory('${into.path}/${voice.dirName}');
    if (voice.url.endsWith('.tar.bz2')) {
      final tar = BZip2Decoder().decodeBytes(bytes);
      final files = TarDecoder().decodeBytes(tar);
      for (final file in files) {
        if (!file.isFile) continue;
        final out = File('${into.path}/${file.name}');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(file.content);
      }
    } else {
      await target.create(recursive: true);
      await File(
        '${target.path}/${voice.url.split('/').last}',
      ).writeAsBytes(bytes);
    }
    return target;
  }

  void close() => _http.close();
}
