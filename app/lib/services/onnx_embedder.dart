import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:memory/memory.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

/// bge-small via in-process ONNX — the Front Porch AI pipeline proven in
/// spike 3 (CLS pooling, L2-normalized). Any failure (missing native lib,
/// bad model files) flips permanently to the hashing fallback so RAG
/// degrades instead of breaking a live game.
///
/// Inference lives in a worker isolate: the ~90 MB session load and every
/// forward pass are synchronous native calls that janked the table when
/// run on the UI isolate (field report, v0.1.1).
class OnnxEmbedder implements Embedder {
  OnnxEmbedder(this.modelDir);

  final Directory modelDir;
  static const _fallback = HashingEmbedder();
  Future<SendPort>? _worker;
  var _broken = false;

  Future<SendPort> _ensureWorker() => _worker ??= () async {
    final ready = ReceivePort();
    await Isolate.spawn(_embeddingWorker, [
      ready.sendPort,
      modelDir.path,
    ], debugName: 'llmerta-embed');
    return await ready.first as SendPort;
  }();

  @override
  Future<List<double>> embed(String text) async {
    if (_broken) return _fallback.embed(text);
    try {
      final commands = await _ensureWorker();
      final reply = ReceivePort();
      commands.send([reply.sendPort, text]);
      final result = await reply.first;
      reply.close();
      if (result is! List<double>) throw StateError('$result');
      return result;
    } catch (_) {
      _broken = true;
      return _fallback.embed(text);
    }
  }
}

void _embeddingWorker(List<Object?> init) {
  final ready = init[0]! as SendPort;
  final modelPath = init[1]! as String;
  final commands = ReceivePort();
  ready.send(commands.sendPort);
  WordPiece? tokenizer;
  OrtSession? session;

  commands.listen((message) {
    final [SendPort reply, String text] = message as List;
    try {
      tokenizer ??= WordPiece(File('$modelPath/vocab.txt').readAsLinesSync());
      if (session == null) {
        OrtEnv.instance.init();
        session = OrtSession.fromFile(
          File('$modelPath/model_quantized.onnx'),
          OrtSessionOptions(),
        );
      }
      final ids = tokenizer!.encode(text);
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
      final outputs = session!.run(OrtRunOptions(), inputs);
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
      reply.send(embedding);
    } catch (error) {
      reply.send('$error');
    }
  });
}
