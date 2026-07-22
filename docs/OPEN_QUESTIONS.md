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

## Standing defaults (proceeding unless overridden)

5. **Vote visibility & ties** — Public simultaneous votes; tie = nobody eliminated.
   Runoff / random-among-tied / secret ballot remain config options.

6. **"oMLX" interpretation** — Read as **Ollama + MLX-family servers**
   (`mlx_lm.server`, mlx-omni-server), covered via the OpenAI-compatible adapter with
   custom base URLs. Correct this if a specific other tool was meant.

7. **Utility model** — Optional lobby setting designating one cheap/local model for
   background work (summaries); defaults to "each agent uses its own model."

## Open (decide by M7)

8. **macOS distribution** — Signed/notarized DMG requires an Apple Developer account
   ($99/yr). Decide before packaging: use an existing account, or ship unsigned
   ("right-click → Open") for v1.

9. **Project name** — Repo is `Mafia-LLMTTG`; working title **"Mafia: LLM Tabletop
   Game"**. Installers/bundle IDs (M7) will bake the final name in.
