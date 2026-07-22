# Roadmap

Milestones are ordered so that every one ends with something runnable and testable.
Each lists its acceptance criteria ("done when").

## M0 — Scaffolding & risk spikes

- Monorepo layout (ARCHITECTURE.md §2), Flutter app shell booting on Win/macOS/Linux.
- CI: analyze + test on PR; build all three desktops.
- **Spikes for the riskiest plugin assumptions** (each a tiny throwaway proof):
  1. SSE streaming from an OpenAI-compatible server in Dart.
  2. WAV playback via `media_kit` on all three OSes.
  3. `fonnx` embedding of a sentence on all three OSes.
  4. `flutter_secure_storage` on Linux without a running keyring.
  5. Piper subprocess round-trip (text in → WAV out → playback).
- **Done when**: CI is green on all platforms and each spike has a written pass/fail
  note (failures re-route the affected design choice before M1).

## M1 — Game core, headless

- `game_core`: full rules FSM, roles, role distribution, event sourcing with
  visibility scopes, win detection, timeouts/fallbacks, seeded RNG.
- Headless simulation runner with **scripted bots** (random-but-legal players).
- Unit tests: night-resolution matrix, vote/tie rules, distribution table, termination
  (1000 simulated games, zero hangs), and the **visibility leak test**.
- **Done when**: simulations run clean in CI and the leak test passes.

## M2 — LLM players (text-only game)

- `llm` package: OpenAI-compatible + Anthropic + Gemini adapters; model discovery;
  connection manager with test/cache; request queue with retries/fallbacks.
- AgentSession with context isolation; two-step decide/speak; structured-output
  parsing + fuzz tests; facts sheet (no RAG yet — verbatim history while it fits).
- Difficulty-preset hook in the system prompt (three guidance blocks exist; tuning
  deferred to M6).
- Minimal debug UI (or CLI) to play a full game: human + 6–13 agents.
- **Done when**: a complete 8-player game runs against LM Studio *and* one hosted
  provider, with the human participating, no manual intervention.

## M3 — Real UI

- Lobby with seat grid and per-seat model dropdowns fed by discovery.
- Game Table screen with all human interactions (speak, nominate, vote, night
  actions), transcript, notes, status strip; spoiler rules enforced.
- Save/resume via event sourcing; autosave; Post-Game Reveal v1 (roles + timeline).
- **Done when**: a full game is playable start-to-finish in the UI with roles hidden
  correctly in every state, and can be resumed after an app restart.

## M4 — Memory / RAG

- `memory` package: rolling per-agent summaries, embedded chunk store, retrieval into
  prompts, token budgeter with graceful degradation.
- Local embeddings via `fonnx` bundled model; optional OpenAI-compatible embeddings.
- Long-game soak test: 14-player game forced past 30 phases on an 8k-context local
  model; agents must still reference early-game facts correctly (spot-check rubric).
- **Done when**: the soak test passes and prompt sizes stay under budget.

## M5 — TTS

- `tts` package: Piper subprocess engine + voice download manager; OpenAI-compatible
  speech endpoint engine (Kokoro-FastAPI); per-seat voice assignment; ordered playback
  queue with prefetch; audio cache; narrator voice.
- **Done when**: a full game plays with mixed Piper/Kokoro voices on all three OSes,
  skip/mute work, and text-only mode is unaffected.

## M6 — Play quality & balance

- Persona library (~20), prompt tuning per role, discussion-quality iteration using
  headless LLM-vs-LLM games as the benchmark (town win-rate in a sane band, low
  confession rate, vote-reason coherence).
- Tune all three difficulty presets (Casual / Standard / Cutthroat); each gets its
  own benchmark band (e.g., Casual skews town-favored, Cutthroat evens out).
- Post-game reveal v2: AI reasoning peek, stats, exports; token/cost report.
- **Done when**: benchmark metrics hit agreed thresholds across 2 local + 2 hosted
  models, per difficulty preset.

## M7 — Packaging & polish

- Installers: MSIX, DMG (signed/notarized — needs Apple account), AppImage + Flatpak.
- First-run setup flow, rules primer, settings import/export (sans secrets).
- Performance pass (14 seats + TTS on modest hardware), accessibility pass.
- **Done when**: a newcomer can download an installer, connect LM Studio, and finish a
  game without touching documentation.

## Explicitly out of scope for v1 (parking lot)

- Speech-to-text input for the human (OPEN_QUESTIONS #5)
- Multiplayer (>1 human) — the PlayerController design keeps the door open
- Mobile targets; additional roles/variants beyond config toggles; Flathub listing
