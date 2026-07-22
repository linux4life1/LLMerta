import 'package:flutter/material.dart';

/// The two-minute rules primer (UI_UX.md §5) — also the How-to-play page.
class RulesPrimer extends StatelessWidget {
  const RulesPrimer({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const Dialog(
      child: SizedBox(width: 560, height: 520, child: RulesPrimer()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget h(String s) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(s, style: text.titleSmall),
    );
    Widget p(String s) => Text(s, style: text.bodySmall);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            children: [
              Text('How LLMerta is played', style: text.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              p(
                'A town of 7–14 sits at the table; every seat but yours is '
                'a language model in character. A hidden mafia kills by '
                'night; the town votes by day. Nobody knows who is who — '
                'that includes you.',
              ),
              h('The roles'),
              p(
                'Mafioso — knows its partners; picks a victim each night.\n'
                'Doctor — protects one player a night (can be themself).\n'
                'Sheriff — investigates one player a night: mafia or not.\n'
                'Assassin — town-aligned, one bullet for the whole game; '
                'fire it or hold it, any night.\n'
                'Villager — no powers, just wits and a vote.',
              ),
              h('The loop'),
              p(
                'Night: the mafia whispers and marks a kill; power roles '
                'act. Dawn: deaths are announced. Day: everyone speaks '
                'once, nominations follow, the top two stand trial, defend '
                'themselves, and the town votes. Ties spare the accused '
                '(house rules can change that).',
              ),
              h('Winning'),
              p(
                'Town wins when every mafioso is gone. Mafia wins at '
                'parity — when they control half the living table.',
              ),
              h('Your dock'),
              p(
                'Everything you can do appears in the dock at the bottom: '
                'speak (aim under 120 words), nominate, vote (pick, then '
                'Lock), and your night action when you have one. The game '
                'waits for you — there is no timer. Notes and the '
                'transcript live in the top strip; leaving the table saves '
                'the game for Continue.',
              ),
              h('After the game'),
              p(
                'The Reveal opens every secret: roles, the mafia\'s night '
                'chat, each model\'s private reasoning, the vote ledger — '
                'and the cast will happily rehash the whole thing with you '
                'in table talk.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
