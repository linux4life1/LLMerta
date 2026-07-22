import 'embedder.dart';

class Chunk {
  const Chunk({
    required this.text,
    required this.vector,
    required this.day,
    this.seat,
  });

  final String text;
  final List<double> vector;
  final int day;

  /// Speaker seat when the chunk is a statement; null for narrator facts.
  final int? seat;
}

class Scored {
  const Scored(this.chunk, this.score);

  final Chunk chunk;
  final double score;
}

/// Brute-force cosine over an agent's private chunks — thousands at most,
/// microseconds to scan (ARCHITECTURE.md §5: no vector DB).
class ChunkStore {
  final _chunks = <Chunk>[];

  int get length => _chunks.length;

  void add(Chunk chunk) => _chunks.add(chunk);

  List<Chunk> where(bool Function(Chunk chunk) test) => [
    for (final c in _chunks)
      if (test(c)) c,
  ];

  List<Scored> topK(
    List<double> query,
    int k, {
    bool Function(Chunk chunk)? where,
  }) {
    final scored = [
      for (final chunk in _chunks)
        if (where == null || where(chunk))
          Scored(chunk, cosine(query, chunk.vector)),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).toList();
  }
}
