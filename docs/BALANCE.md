# Balance baseline — v0.1.x

Live-model benchmark of the shipped presets. Method: headless engine games
(`packages/llm/bin/headless_game.dart`), 10 seats, house personas, fixed seeds,
no human seat. Local games ran GLM-4.7-Flash-MLX-8bit on every seat via a local
oMLX server; the mixed game interleaved three backends across the table
(4× GLM-4.7-Flash local, 3× x-ai/grok-4.5, 3× anthropic/claude-haiku-4.5 via
OpenRouter). Run date: 2026-07-22.

## Results

| Game | Difficulty | Seed | Winner | Days | Wall clock | LLM calls | Fallbacks |
|---|---|---|---|---|---|---|---|
| 1 | casual | 11 | mafia | 2 | 11:38 | — | 0 |
| 2 | casual | 22 | mafia | 3 | 19:35 | — | 0 |
| 3 | standard | 11 | mafia | 4 | 14:58 | 114 | 1 |
| 4 | standard | 22 | mafia | 3 | 16:15 | — | 0 |
| 5 | cutthroat | 11 | mafia | 3 | 19:07 | — | 0 |
| 6 | cutthroat | 22 | **town** | 3 | 08:19 | 94 | 0 |
| 7 | mixed standard | 33 | mafia | 4 | 22:46 | 46 local + 67 OpenRouter | 3 |

## Reading the numbers — honestly

- **n = 2 per difficulty.** These are directional smoke signals, not statistics.
  Nothing below is a "measured win rate".
- **Mafia won 6 of 7.** Consistent with the social-deduction meta for
  similarly-capable models: deception is cheaper than detection. The town CAN
  win — game 6 was the fastest, cleanest game of the set (town connected a
  quiet seat's voting pattern by Day 3) — so the presets are not degenerate.
- **Game length lands where UI_UX.md wants it**: 2–4 in-game days, 8–23 wall
  minutes at 10 seats on a local model. Casual ends fastest, as designed.
- **Fallback rate is healthy**: 0–3 timeouts/parse fallbacks per ~100 calls,
  none cascading.
- The mixed game produced the set's best drama: the sheriff (local GLM seat)
  claimed on trial with a correct investigation, and the table — steered by a
  grok-4.5 mafia voice — voted her out anyway. Deception advantage, illustrated.

## Decisions for v0.1.1

1. **No preset changes.** Mafia-leaning results at n=2 don't justify retuning;
   the levers already exist as house rules (`discussionRounds: 2`,
   `mafiaCountDelta: -1`, `night0SheriffPeek`) for players who want a softer
   town game today.
2. **Watch item**: if larger samples keep mafia ≥75% on *standard*, the first
   lever is defaulting standard to 2 discussion rounds (more cross-examination
   surface), not touching role counts.
3. **Bug found and queued**: in game 7 a GLM seat's *defense* and *last words*
   surfaced the raw JSON envelope — including the private `reason` field — as
   spoken text. The constrained-speech parser must strip code fences, extract
   `speech`, and never let `reason` reach any public surface. Tracked for the
   next patch; the fuzz suite gains this exact shape.

## v0.1.x priority rebalance (implemented)

Shipped after the mafia-heavy smoke above (see also design review 2026-07):

1. **Standard defaults** → 2 discussion rounds + runoff ties (difficulty
   `applyRules` bundle; lobby + headless honor it).
2. **Difficulty = prompt guidance + house-rules bundle** (Casual softens mafia
   count and grants Night-0 sheriff peek; Cutthroat keeps no-elim ties).
3. **Prompt quality**: persona color budget, anti-invention, anti-volume-herd,
   structured mafia night chat (concrete kill first).
4. **Assassin private hit confirm** (`AssassinShotResolved`) — landed + wasMafia.
5. **Mafia facts sheet**: living teammates + last agreed kill target so night
   chat does not re-litigate resolved nights.

### Comparison run (post-change)

| Game | Setup | Seed | Winner | Days | Wall clock | LLM calls | Fallbacks | Notes |
|---|---|---|---|---|---|---|---|---|
| **A (old baseline #3)** | standard, 1 round, GLM-4.7-Flash all seats | 11 | mafia | 4 | 14:58 | 114 | 1 | pre-rebalance |
| **B (this run)** | standard bundle (2 rounds + runoff), Qwen3.6-35B-A3B-Claude-distilled | 11 | mafia | 3 | 11:01 | 102 | 0 | post-rebalance |

**Timeline B:** Day1 hang Assassin (Boris) → N1 kill villager Iris → Day2 hang villager Felix (Jonas mafia was co-trial and lost the vote) → N2 kill Doctor Alma → parity, mafia win. Sheriff Greta investigated Jonas=MAFIA on Night 2 but game ended at dawn before she could claim.

**Read:** still mafia win, but play quality moved. Mafia night chat named concrete kills; Day1 removed a real threat not a random power role; Day2 put a mafioso on trial and missed. Remaining bugs: copy-paste chorus, 3rd-person self-talk, mafia night chat sometimes re-litigates old days. n=1 — not a win-rate claim.

Record headless results here against the table above.
