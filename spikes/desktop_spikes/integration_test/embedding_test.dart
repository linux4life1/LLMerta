// M0 spike 3: local sentence embedding via in-process ONNX (the Front Porch
// AI pipeline: onnxruntime + BERT WordPiece), using bge-small-en-v1.5.
// Pass = embeddings have the right shape, are L2-normalizable, and cosine
// similarity ranks a related pair above an unrelated one.
import 'dart:io';
import 'dart:math' as math;

import 'package:desktop_spikes/wordpiece.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

const modelsRoot = String.fromEnvironment(
  'SPIKE_MODELS',
  defaultValue: '/Users/linux4life/dev/Mafia/spikes/models',
);

List<double> l2normalize(List<double> v) {
  final norm = math.sqrt(v.fold<double>(0, (s, x) => s + x * x));
  return [for (final x in v) x / norm];
}

double cosine(List<double> a, List<double> b) {
  var dot = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
  }
  return dot;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bge-small embeds sentences with sane similarity', (
    tester,
  ) async {
    final dir = '$modelsRoot/bge-small-en-v1.5';
    final tokenizer = WordPiece(await File('$dir/vocab.txt').readAsLines());
    OrtEnv.instance.init();
    final session = OrtSession.fromFile(
      File('$dir/model_quantized.onnx'),
      OrtSessionOptions(),
    );

    final sw = Stopwatch()..start();
    Future<List<double>> embed(String text) async {
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
      final outputs = session.run(OrtRunOptions(), inputs);
      // last_hidden_state [1, seq, 384] -> CLS token pooling, L2-normalized
      // (bge's recommended usage).
      final hidden = (outputs[0]!.value! as List)[0] as List; // [seq][384]
      final embedding = l2normalize((hidden[0] as List).cast<double>());
      for (final t in inputs.values) {
        t.release();
      }
      for (final o in outputs) {
        o?.release();
      }
      return embedding;
    }

    final mafia = await embed('The mafia secretly chooses a victim at night.');
    final wolf = await embed('Werewolves pick who to eliminate after dark.');
    final pasta = await embed('This recipe needs fresh basil and parmesan.');
    final ms = sw.elapsedMilliseconds;

    expect(mafia.length, 384);
    final near = cosine(mafia, wolf);
    final far = cosine(mafia, pasta);
    // ignore: avoid_print
    print(
      'SPIKE3: dim=384, 3 sentences in ${ms}ms, '
      'cos(mafia,werewolf)=${near.toStringAsFixed(3)}, '
      'cos(mafia,recipe)=${far.toStringAsFixed(3)}',
    );
    expect(near, greaterThan(far + 0.05));
    session.release();
    OrtEnv.instance.release();
  });
}
