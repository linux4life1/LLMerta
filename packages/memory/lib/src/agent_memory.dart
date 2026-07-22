import 'package:game_core/game_core.dart';

import 'chunk_store.dart';
import 'embedder.dart';
import 'rolling_summary.dart';
import 'tokens.dart';

/// Per-agent memory orchestrator (LLM_INTEGRATION.md §6). The caller
/// feeds it ONLY that seat's visibility slice — the same invariant as
/// prompts and render state (CLAUDE.md rule 7).
class AgentMemory {
  AgentMemory({
    required this.seat,
    required Embedder embedder,
    RollingSummary? summary,
  }) : _embedder = CachingEmbedder(embedder),
       summary = summary ?? RollingSummary();

  final int seat;
  final Embedder _embedder;
  final RollingSummary summary;
  final ChunkStore store = ChunkStore();
  int _day = 0;

  /// Chunk statements verbatim (speech = one chunk). [line] is the
  /// rendered transcript form the agent would have read.
  Future<void> ingest(GameEvent event, String? line) async {
    if (line == null) return;
    if (event is DayBegan) _day = event.day;
    if (event is NightBegan) _day = event.day;
    final speaker = switch (event) {
      SpeechGiven(:final seat) => seat,
      DefenseGiven(:final seat) => seat,
      LastWordsGiven(:final seat) => seat,
      MafiaChatSaid(:final seat) => seat,
      _ => null,
    };
    if (speaker == null) return;
    store.add(
      Chunk(
        text: line,
        vector: await _embedder.embed(line),
        day: _day,
        seat: speaker,
      ),
    );
  }

  Future<List<Scored>> retrieve(
    String query, {
    int k = 6,
    int? aboutSeat,
  }) async {
    final vector = await _embedder.embed(query);
    return store.topK(
      vector,
      k,
      where: aboutSeat == null ? null : (c) => c.seat == aboutSeat,
    );
  }

  /// The prompt block for the current task, trimmed to [budget]:
  /// summary first (it is the cheaper tier to keep), then as many
  /// relevant verbatim statements as fit.
  Future<String> memoryBlock(
    String query, {
    required TokenBudget budget,
    required int fixedTokens,
    int k = 8,
  }) async {
    final sections = <String>[];
    final summaryBudget = budget.summaryBudget(fixedTokens);
    if (summary.lines.isNotEmpty && summaryBudget > 0) {
      var text = summary.text;
      if (estimateTokens(text) > summaryBudget) {
        text = text.substring(text.length - summaryBudget * 4);
      }
      sections.add('WHAT YOU REMEMBER (your own running notes):\n$text');
    }
    var remaining = budget.retrievalBudget(fixedTokens);
    if (remaining > 0) {
      final hits = await retrieve(query, k: k);
      final quoted = <String>[];
      for (final hit in hits) {
        final cost = estimateTokens(hit.chunk.text) + 2;
        if (cost > remaining) break;
        remaining -= cost;
        quoted.add('- ${hit.chunk.text}');
      }
      if (quoted.isNotEmpty) {
        sections.add(
          'RELEVANT PAST STATEMENTS (verbatim):\n${quoted.join('\n')}',
        );
      }
    }
    return sections.join('\n\n');
  }
}
