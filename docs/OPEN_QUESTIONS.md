# Open Questions

## Resolved (2026-07-22)

1. **Assassin alignment** — **Town-aligned** one-shot killer ("vigilante with one
   bullet"): counts toward Town, wins with Town, investigates as *Not Mafia*.
   (GAME_DESIGN.md §2/§4.5 stands as written.)

2. **Human role assignment** — **Random deal only**, with a hidden "choose my role"
   debug toggle for testing.

3. **Voice input (STT)** — **Parked for v2.** Human types; AI players speak via TTS.

4. **Persona tone** — **Mixed library**: grounded townsfolk, noir archetypes, and a
   few comedic characters; filterable by tone in the lobby.

## Resolved — UX Draft v1 review (2026-07-22)

All seven UX review questions locked; full list in UI_UX.md §4: unified table layout
across 7–14 seats, transcript drawer collapsed by default, two-step vote lock,
narrator as voice-only, soft speech-length guidance, random town name per game,
ambient audio on by default.

## Resolved — gameplay internals (2026-07-22)

- **Day 1** is a full day (discussion, nomination, vote) — no special first-day rule.
- **Mafia kill** is decided by majority vote after the night chat; senior member
  breaks ties.
- **Trials** take the top 2 nominees (defense speeches, then one vote).
- **Difficulty presets ship in v1**: Casual / Standard / Cutthroat (GAME_DESIGN.md §7).
- Standing gameplay defaults confirmed by review: one discussion round per day
  (second round as config), reveal roles on death, role composition is public
  knowledge, seat↔model mapping hidden from agents, Assassin fires at night only, no
  Sheriff peek on Night 0, game waits indefinitely for the human.

## Standing defaults (proceeding unless overridden)

5. **Vote visibility & ties** — Public simultaneous votes; tie = nobody eliminated.
   Runoff / random-among-tied / secret ballot remain config options.

6. **"oMLX" interpretation** — Resolved: **oMLX is a specific macOS app** the user
   runs (managed CLI at `~/.local/bin/omlx`, OpenAI-compatible server on
   `127.0.0.1:8000`, models under `~/.omlx/models`). Covered by the OpenAI-compatible
   adapter with a custom base URL; it is the primary local-testing server
   (see docs/SPIKES.md §1 for its streaming quirks).

7. **Utility model** — Optional lobby setting designating one cheap/local model for
   background work (summaries); defaults to "each agent uses its own model."

8. **Front Porch AI reference** — TTS (sherpa_onnx running Piper + Kokoro) and RAG
   embedding implementations must mirror the Front Porch AI repo. The repo could not
   be attached to this session (repo-add approval blocked); docs encode the approach,
   and exact model/runtime/package details get aligned as soon as it's linked.

## Open (decide by M7)

8. **macOS distribution** — Signed/notarized DMG requires an Apple Developer account
   ($99/yr). Decide before packaging: use an existing account, or ship unsigned
   ("right-click → Open") for v1.

9. **Project name** — **Resolved (2026-07-22): the app is "LLMafia"** (LLM + Mafia).
   Repo stays `Mafia-LLMTTG` for now; installers/bundle IDs (M7) bake LLMafia in.
