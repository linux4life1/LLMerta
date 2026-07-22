import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:memory/memory.dart';

void main() {
  test('model detection requires both vocab and onnx files', () async {
    final tmp = await Directory.systemTemp.createTemp('llmerta-bge');
    addTearDown(() => tmp.delete(recursive: true));
    expect(detectEmbeddingModelDir(candidates: [tmp.path]), isNull);

    File('${tmp.path}/vocab.txt').writeAsStringSync('[CLS]\n[SEP]\n[UNK]');
    expect(detectEmbeddingModelDir(candidates: [tmp.path]), isNull);

    File('${tmp.path}/model_quantized.onnx').writeAsBytesSync(const [1, 2]);
    expect(detectEmbeddingModelDir(candidates: [tmp.path])?.path, tmp.path);
  });

  test('gameEmbedder falls back to hashing without a model', () {
    final container = ProviderContainer(
      overrides: [embeddingModelDirProvider.overrideWith((_) => null)],
    );
    addTearDown(container.dispose);
    expect(container.read(gameEmbedderProvider), isA<HashingEmbedder>());
  });

  test('a broken ONNX model self-heals to the hashing fallback', () async {
    final tmp = await Directory.systemTemp.createTemp('llmerta-broken');
    addTearDown(() => tmp.delete(recursive: true));
    File('${tmp.path}/vocab.txt').writeAsStringSync('[CLS]\n[SEP]\n[UNK]');
    File('${tmp.path}/model_quantized.onnx').writeAsBytesSync(const [0]);

    final embedder = OnnxEmbedder(tmp);
    final vector = await embedder.embed('the night keeps its own ledger');
    expect(vector, hasLength(256), reason: 'hashing fallback dimensions');
    expect(
      cosine(vector, await embedder.embed('the night keeps its own ledger')),
      closeTo(1, 1e-9),
    );
  });
}
