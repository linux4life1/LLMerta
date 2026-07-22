import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// BERT-uncased WordPiece tokenizer (Front Porch AI pipeline parity:
/// NFD accent stripping via unorm_dart). Feeds the bge-small ONNX
/// embedder wired up on the app side.
class WordPiece {
  WordPiece(List<String> vocabLines)
    : vocab = {for (var i = 0; i < vocabLines.length; i++) vocabLines[i]: i};

  final Map<String, int> vocab;

  int get cls => vocab['[CLS]']!;
  int get sep => vocab['[SEP]']!;
  int get unk => vocab['[UNK]']!;

  List<int> encode(String text) {
    final stripped = unorm.nfd(text).replaceAll(RegExp(r'[̀-ͯ]'), '');
    final words =
        stripped
            .toLowerCase()
            .replaceAllMapped(
              RegExp(r'[\p{P}\p{S}]', unicode: true),
              (m) => ' ${m[0]} ',
            )
            .split(RegExp(r'\s+'))
          ..removeWhere((w) => w.isEmpty);
    final ids = <int>[cls];
    for (final word in words) {
      ids.addAll(_wordpiece(word));
    }
    ids.add(sep);
    return ids;
  }

  List<int> _wordpiece(String word) {
    final pieces = <int>[];
    var start = 0;
    while (start < word.length) {
      var end = word.length;
      int? id;
      while (end > start) {
        final sub = (start == 0 ? '' : '##') + word.substring(start, end);
        final found = vocab[sub];
        if (found != null) {
          id = found;
          break;
        }
        end--;
      }
      if (id == null) return [unk];
      pieces.add(id);
      start = end;
    }
    return pieces;
  }
}
