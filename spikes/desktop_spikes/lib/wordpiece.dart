/// Minimal BERT-uncased WordPiece tokenizer — enough for the embedding spike.
/// Production parity (NFD accent stripping via unorm_dart, CJK handling)
/// follows Front Porch AI's implementation in the real `memory` package.
class WordPiece {
  WordPiece(List<String> vocabLines)
    : vocab = {for (var i = 0; i < vocabLines.length; i++) vocabLines[i]: i};

  final Map<String, int> vocab;

  int get cls => vocab['[CLS]']!;
  int get sep => vocab['[SEP]']!;
  int get unk => vocab['[UNK]']!;

  List<int> encode(String text) {
    final words =
        text
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
