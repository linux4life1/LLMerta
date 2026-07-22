import 'tokens.dart';

typedef Summarizer = Future<String> Function(String prompt);

/// Tier 2 (LLM_INTEGRATION.md §6): one compact line per phase from the
/// agent's own perspective; oldest lines re-compact when over budget.
class RollingSummary {
  RollingSummary({this.tokenBudget = 900});

  final int tokenBudget;
  final List<String> _lines = [];

  List<String> get lines => List.unmodifiable(_lines);

  String get text => _lines.join('\n');

  int get tokens => estimateTokens(text);

  bool get overBudget => tokens > tokenBudget;

  void add(String phaseSummary) {
    final line = phaseSummary.trim();
    if (line.isNotEmpty) _lines.add(line);
  }

  /// Re-compacts the older half of the summary through [summarize].
  /// Falls back to hard truncation if the model output is still too big.
  Future<void> compactIfNeeded(Summarizer summarize) async {
    if (!overBudget || _lines.length < 2) return;
    final keep = _lines.length ~/ 2;
    final old = _lines.sublist(0, _lines.length - keep);
    final recent = _lines.sublist(_lines.length - keep);
    var compacted = (await summarize(
      'Compress these game-phase notes into at most three short lines, '
      'keeping names, votes, and accusations:\n${old.join('\n')}',
    )).trim();
    final cap = tokenBudget ~/ 2;
    if (estimateTokens(compacted) > cap) {
      compacted = compacted.substring(0, cap * 4);
    }
    _lines
      ..clear()
      ..addAll([if (compacted.isNotEmpty) compacted, ...recent]);
  }
}
