import 'dart:io';

import 'package:memory/memory.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

/// bge-small via in-process ONNX — the Front Porch AI pipeline proven in
/// spike 3 (CLS pooling, L2-normalized). Any failure (missing native lib,
/// bad model files) flips permanently to the hashing fallback so RAG
/// degrades instead of breaking a live game.
class OnnxEmbedder implements Embedder {
  OnnxEmbedder(this.modelDir);

  final Directory modelDir;
  static const _fallback = HashingEmbedder();
  WordPiece? _tokenizer;
  OrtSession? _session;
  var _broken = false;

  @override
  Future<List<double>> embed(String text) async {
    if (_broken) return _fallback.embed(text);
    try {
      final tokenizer = _tokenizer ??= WordPiece(
        File('${modelDir.path}/vocab.txt').readAsLinesSync(),
      );
      if (_session == null) {
        OrtEnv.instance.init();
        _session = OrtSession.fromFile(
          File('${modelDir.path}/model_quantized.onnx'),
          OrtSessionOptions(),
        );
      }
      final ids = tokenizer.encode(text);
      final shape = [1, ids.length];
      final inputs = {
        'input_ids': OrtValueTensor.createTensorWithDataList(ids, shape),
        'attention_mask': OrtValueTensor.createTensorWithDataList(
          List.filled(ids.length, 1),
          shape,
        ),
        'token_type_ids': OrtValueTensor.createTensorWithDataList(
          List.filled(ids.length, 0),
          shape,
        ),
      };
      final outputs = _session!.run(OrtRunOptions(), inputs);
      final hidden = (outputs[0]!.value! as List)[0] as List;
      final embedding = l2normalize(
        ((hidden[0] as List).cast<num>()).map((n) => n.toDouble()).toList(),
      );
      for (final t in inputs.values) {
        t.release();
      }
      for (final o in outputs) {
        o?.release();
      }
      return embedding;
    } catch (_) {
      _broken = true;
      return _fallback.embed(text);
    }
  }
}
