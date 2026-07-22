import 'package:game_core/game_core.dart';
import 'package:memory/memory.dart';
import 'package:test/test.dart';

/// M4 acceptance (ROADMAP): 14 players, 30 phases, and the assembled
/// prompt block still fits an 8k context with facts + summary +
/// retrieval all present.
void main() {
  test('14-player 30-phase soak stays inside an 8k context', () async {
    const seats = 14;
    final memory = AgentMemory(seat: 0, embedder: const HashingEmbedder());
    final topics = [
      'the bakery fire',
      'the harbor ledger',
      'the missing key',
      'the vote that failed',
      'the doctor claim',
      'the quiet ones',
    ];

    for (var phase = 0; phase < 30; phase++) {
      final day = phase ~/ 2 + 1;
      if (phase.isEven) {
        await memory.ingest(DayBegan(day), 'Day $day dawns.');
        for (var s = 1; s < seats; s++) {
          final topic = topics[(phase + s) % topics.length];
          await memory.ingest(
            SpeechGiven(seat: s, text: 'ignored'),
            'P$s (seat $s): "About $topic — I watched P${(s + day) % seats} '
            'closely and their story about $topic keeps shifting."',
          );
        }
        memory.summary.add(
          'Day $day: argued over ${topics[phase % topics.length]}; '
          'no verdict; P${day % seats} drew suspicion.',
        );
      } else {
        await memory.ingest(NightBegan(day), 'Night $day falls.');
        memory.summary.add('Night $day: quiet; nobody died by morning.');
      }
      await memory.summary.compactIfNeeded(
        (prompt) async => 'Earlier days: rotating suspicion, no verdicts.',
      );
    }

    expect(memory.store.length, 15 * (seats - 1));
    expect(memory.summary.tokens, lessThanOrEqualTo(900));

    // 8k context: ~2.2k fixed (system + facts sheet + task), 1k response.
    const budget = TokenBudget(context: 8000);
    const fixed = 2200;
    final block = await memory.memoryBlock(
      'Who should I vote for? P3 keeps changing their story about the '
      'bakery fire.',
      budget: budget,
      fixedTokens: fixed,
    );

    expect(block, contains('WHAT YOU REMEMBER'));
    expect(block, contains('RELEVANT PAST STATEMENTS'));
    expect(block, contains('P3'));
    final total = fixed + estimateTokens(block) + budget.responseReserve;
    expect(total, lessThanOrEqualTo(8000), reason: 'block must fit 8k');
  });
}
