/// Conservative token estimate (~4 chars/token for English) — used for
/// budgeting only, never billing.
int estimateTokens(String text) => (text.length / 4).ceil();

/// Splits a context budget across the three memory tiers
/// (LLM_INTEGRATION.md §6). The facts sheet is ground truth and never
/// compressed; summaries and retrieval flex.
class TokenBudget {
  const TokenBudget({
    required this.context,
    this.responseReserve = 1024,
    this.summaryShare = 0.35,
  }) : assert(summaryShare > 0 && summaryShare < 1);

  final int context;
  final int responseReserve;
  final double summaryShare;

  int available(int fixedTokens) =>
      (context - responseReserve - fixedTokens).clamp(0, context);

  int summaryBudget(int fixedTokens) =>
      (available(fixedTokens) * summaryShare).floor();

  int retrievalBudget(int fixedTokens) =>
      available(fixedTokens) - summaryBudget(fixedTokens);
}
