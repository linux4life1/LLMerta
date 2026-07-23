import 'dart:io';

import 'package:memory/memory.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'onnx_embedder.dart';

part 'embedding.g.dart';

/// bge-small-en-v1.5 (FPA parity; the bge-vs-nomic call landed on bge —
/// spike-proven, quantized, 384-dim). Missing model → hashing fallback.
/// Only caller-supplied directories are checked — the app never scans
/// dev checkouts or other apps' folders.
Directory? detectEmbeddingModelDir({required List<String> candidates}) {
  for (final path in candidates) {
    final dir = Directory(path);
    if (File('${dir.path}/vocab.txt').existsSync() &&
        File('${dir.path}/model_quantized.onnx').existsSync()) {
      return dir;
    }
  }
  return null;
}

@Riverpod(keepAlive: true)
Future<Directory?> embeddingModelDir(Ref ref) async {
  final support = await getApplicationSupportDirectory();
  return detectEmbeddingModelDir(
    candidates: ['${support.path}/models/bge-small-en-v1.5'],
  );
}

@Riverpod(keepAlive: true)
Embedder gameEmbedder(Ref ref) {
  final dir = ref.watch(embeddingModelDirProvider).value;
  // Cache in front of ONNX: all 13 seats ingest the same rendered event
  // text, so one forward pass serves the whole table (jank fix, v0.1.2).
  return dir == null
      ? const HashingEmbedder()
      : CachingEmbedder(OnnxEmbedder(dir));
}
