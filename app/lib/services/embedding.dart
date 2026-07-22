import 'dart:io';

import 'package:memory/memory.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'onnx_embedder.dart';

part 'embedding.g.dart';

/// bge-small-en-v1.5 (FPA parity; the bge-vs-nomic call landed on bge —
/// spike-proven, quantized, 384-dim). Missing model → hashing fallback.
Directory? detectEmbeddingModelDir({List<String>? candidates}) {
  final home = Platform.environment['HOME'] ?? '';
  final paths =
      candidates ??
      [
        '${Directory.current.path}/../spikes/models/bge-small-en-v1.5',
        '${Directory.current.path}/spikes/models/bge-small-en-v1.5',
        '$home/dev/Mafia/spikes/models/bge-small-en-v1.5',
      ];
  for (final path in paths) {
    final dir = Directory(path);
    if (File('${dir.path}/vocab.txt').existsSync() &&
        File('${dir.path}/model_quantized.onnx').existsSync()) {
      return dir;
    }
  }
  return null;
}

@Riverpod(keepAlive: true)
Directory? embeddingModelDir(Ref ref) => detectEmbeddingModelDir();

@Riverpod(keepAlive: true)
Embedder gameEmbedder(Ref ref) {
  final dir = ref.watch(embeddingModelDirProvider);
  return dir == null ? const HashingEmbedder() : OnnxEmbedder(dir);
}
