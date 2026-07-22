import 'dart:math';

abstract interface class Embedder {
  Future<List<double>> embed(String text);
}

List<double> l2normalize(List<double> v) {
  final norm = sqrt(v.fold<double>(0, (s, x) => s + x * x));
  if (norm == 0) return v;
  return [for (final x in v) x / norm];
}

double cosine(List<double> a, List<double> b) {
  var dot = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
  }
  return dot;
}

/// Zero-setup offline fallback: feature-hashed bag of words, L2-normalized.
/// Shared vocabulary overlap gives genuine cosine relevance — weaker than a
/// neural model but deterministic and dependency-free. The ONNX bge-small
/// embedder (Front Porch AI pipeline) plugs in via the same interface.
class HashingEmbedder implements Embedder {
  const HashingEmbedder({this.dimensions = 256});

  final int dimensions;

  @override
  Future<List<double>> embed(String text) async {
    final vector = List<double>.filled(dimensions, 0);
    final words =
        text
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
            .split(RegExp(r'\s+'))
          ..removeWhere((w) => w.isEmpty || w.length < 2);
    for (final word in words) {
      vector[word.hashCode.abs() % dimensions] += 1;
    }
    return l2normalize(vector);
  }
}

/// Memoizes embeddings — speeches are embedded once, queried many times.
class CachingEmbedder implements Embedder {
  CachingEmbedder(this.inner, {this.capacity = 4096});

  final Embedder inner;
  final int capacity;
  final _cache = <String, List<double>>{};

  @override
  Future<List<double>> embed(String text) async {
    final hit = _cache[text];
    if (hit != null) return hit;
    final vector = await inner.embed(text);
    if (_cache.length >= capacity) _cache.remove(_cache.keys.first);
    _cache[text] = vector;
    return vector;
  }
}
