# Open Questions

Decisions needing your sign-off. Each has a proposed default so work can proceed if
you simply say "defaults are fine."

1. **Assassin alignment** — Proposed: **Town-aligned** one-shot killer (a "vigilante
   with one bullet"): counts toward Town, wins with Town, investigates as *Not Mafia*.
   Alternatives: (a) independent third party with its own win condition, or (b)
   Mafia-aligned guaranteed-kill. Say the word and the design flips — it's isolated in
   GAME_DESIGN.md §2/§4.5.

2. **Human role assignment** — Proposed: random deal, with a hidden "choose my role"
   debug toggle. Alternative: always let the player choose (less authentic, more fun
   for some).

3. **Vote visibility & ties** — Proposed: public simultaneous votes; tie = nobody
   eliminated. Alternatives are config options already (runoff, random-among-tied,
   secret ballot) — question is only which is the *default*.

4. **"oMLX" interpretation** — I read this as **Ollama + MLX-family servers**
   (`mlx_lm.server`, mlx-omni-server), all covered via the OpenAI-compatible adapter
   with custom base URLs. Confirm, or tell me the specific tool you meant and I'll add
   a dedicated adapter to the plan.

5. **Voice input (STT)** — Proposed: out of scope for v1 (text input for the human;
   TTS output only). Whisper-based STT is a natural v2 feature. OK to park?

6. **Persona authoring** — Proposed: ship ~20 presets + free-text custom personas.
   Any preference on tone (serious noir vs. comedic vs. mixed library)?

7. **macOS distribution** — Signed/notarized DMG requires an Apple Developer account
   ($99/yr). Do you have one to use, or should macOS ship unsigned ("right-click →
   Open") for v1?

8. **Utility model** — Proposed: an optional lobby setting designating one cheap/local
   model for background work (summaries), defaulting to "each agent uses its own
   model." Fine?

9. **Project name** — Repo is `Mafia-LLMTTG`. Working title in docs is
   **"Mafia: LLM Tabletop Game"**. Happy to bikeshed a product name later; flagging
   only because installers/bundle IDs (M7) will bake it in.
