import 'package:game_core/game_core.dart';
import 'package:memory/memory.dart';
import 'package:test/test.dart';

void main() {
  test(
    'hashing embedder gives cosine relevance to shared vocabulary',
    () async {
      const embedder = HashingEmbedder();
      final mafia = await embedder.embed('the mafia picks a victim at night');
      final wolf = await embedder.embed('the mafia met again at night');
      final pasta = await embedder.embed('fresh basil parmesan recipe');
      expect(cosine(mafia, wolf), greaterThan(cosine(mafia, pasta)));
      expect(cosine(mafia, mafia), closeTo(1, 1e-9));
    },
  );

  test('caching embedder memoizes by text', () async {
    var calls = 0;
    final embedder = CachingEmbedder(_CountingEmbedder(() => calls++));
    await embedder.embed('a');
    await embedder.embed('a');
    await embedder.embed('b');
    expect(calls, 2);
  });

  test('chunk store ranks by cosine and honors filters', () {
    final store = ChunkStore()
      ..add(const Chunk(text: 'x', vector: [1, 0], day: 1, seat: 2))
      ..add(const Chunk(text: 'y', vector: [0.9, 0.1], day: 1, seat: 3))
      ..add(const Chunk(text: 'z', vector: [0, 1], day: 2, seat: 2));
    final top = store.topK([1, 0], 2);
    expect([for (final s in top) s.chunk.text], ['x', 'y']);
    final only2 = store.topK([1, 0], 5, where: (c) => c.seat == 2);
    expect([for (final s in only2) s.chunk.text], ['x', 'z']);
  });

  test('wordpiece tokenizes with accents stripped and subwords matched', () {
    final wp = WordPiece([
      '[CLS]',
      '[SEP]',
      '[UNK]',
      'the',
      'night',
      'watch',
      '##man',
      'cafe',
    ]);
    expect(wp.encode('The café watchman'), [
      wp.cls,
      wp.vocab['the'],
      wp.vocab['cafe'],
      wp.vocab['watch'],
      wp.vocab['##man'],
      wp.sep,
    ]);
    expect(wp.encode('zzz'), [wp.cls, wp.unk, wp.sep]);
  });

  test(
    'rolling summary compacts the older half through the summarizer',
    () async {
      final summary = RollingSummary(tokenBudget: 30);
      for (var day = 1; day <= 6; day++) {
        summary.add(
          'Day $day: long accusations flew around the table about seat $day '
          'and everyone argued for a very long time indeed.',
        );
      }
      expect(summary.overBudget, isTrue);
      await summary.compactIfNeeded((prompt) async {
        expect(prompt, contains('Day 1'));
        return 'Days 1-3: chaos, no eliminations.';
      });
      expect(summary.lines.first, startsWith('Days 1-3'));
      expect(summary.lines.length, 4);
    },
  );

  test('token budget splits and clamps', () {
    const budget = TokenBudget(context: 8000, responseReserve: 1000);
    expect(budget.available(2000), 5000);
    expect(budget.summaryBudget(2000), 1750);
    expect(budget.retrievalBudget(2000), 3250);
    expect(budget.available(9000), 0);
  });

  test(
    'agent memory ingests only statements and retrieves by speaker',
    () async {
      final memory = AgentMemory(seat: 0, embedder: const HashingEmbedder());
      await memory.ingest(const DayBegan(1), 'Day 1 dawns.');
      await memory.ingest(
        const SpeechGiven(seat: 3, text: 'ignored'),
        'P3 (seat 3): "I saw someone near the bakery at midnight."',
      );
      await memory.ingest(
        const SpeechGiven(seat: 5, text: 'ignored'),
        'P5 (seat 5): "The harvest festival needs volunteers."',
      );
      await memory.ingest(const NightBegan(1), null);
      expect(memory.store.length, 2);

      final hits = await memory.retrieve('who was near the bakery?', k: 1);
      expect(hits.single.chunk.seat, 3);
      final only5 = await memory.retrieve('anything', k: 5, aboutSeat: 5);
      expect(only5.single.chunk.seat, 5);
    },
  );
}

class _CountingEmbedder implements Embedder {
  _CountingEmbedder(this.onCall);

  final void Function() onCall;

  @override
  Future<List<double>> embed(String text) async {
    onCall();
    return [1, 0];
  }
}
