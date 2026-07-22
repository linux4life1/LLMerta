# Architecture

## 1. Framework decision: Flutter

Requirements driving the choice: one codebase for Windows/macOS/Linux, a real game UI
(animation, theming, audio), subprocess control (Piper), HTTP streaming (LLM APIs),
SQLite, and secure key storage.

| Option | Pros | Cons |
|---|---|---|
| **Flutter (chosen)** | True single codebase incl. rendering; strong desktop support; we have prior experience together (Front Porch AI); rich animation for the game table; Dart isolates for concurrency; mature plugins for SQLite/secure storage/audio | Larger binaries (~40–80 MB); a few desktop plugins need per-platform verification (audio on Linux) |
| Tauri (Rust + web UI) | Tiny binaries; Rust backend | Two languages/stacks; webview inconsistencies across OSes; no shared experience |
| Electron | Huge ecosystem | Heaviest footprint; poor fit for game-like UI performance |
| Godot | Built for games | LLM/HTTP/SQLite tooling is weak; GDScript ecosystem poor fit for API-heavy app |
| Avalonia (.NET) | Good desktop story | Smaller ecosystem; no shared experience |

**Decision: Flutter + Dart end-to-end.** The whole app — engine, LLM clients, UI — is
Dart, which keeps the mental model simple and the engine unit-testable without any UI.

## 2. Repository layout (planned)

Melos-style monorepo of Dart packages; only `app` depends on Flutter:

```
mafia_llmttg/
├── app/                    # Flutter application (UI, DI wiring, platform glue)
├── packages/
│   ├── game_core/          # Pure Dart: rules engine, roles, events, FSM. Zero IO.
│   ├── llm/                # Provider clients, model discovery, agent sessions, parsing
│   ├── memory/             # Summaries, embeddings, retrieval (RAG)
│   ├── tts/                # TTS engine abstraction: Piper process, HTTP speech APIs
│   └── persistence/        # Drift/SQLite schemas, save/replay, settings store
├── docs/                   # These design documents
└── .github/workflows/      # CI: analyze + test + build for all three platforms
```

Dependency rule: `game_core` depends on nothing. `llm`, `memory`, `tts` depend only on
`game_core` types. `app` wires everything. This keeps the engine deterministic and
testable, and means a headless simulation runner (LLM-only games, no UI) is trivial —
which is how we'll test game balance and prompts in CI.

## 3. Game engine (`game_core`)

- **Finite state machine** over phases: `Setup → Night0 → Day(dawn, discussion,
  nomination, defense, vote, verdict) → Night(actions, resolution) → … → GameOver`.
- **Event-sourced**: the single source of truth is an append-only list of `GameEvent`s,
  each with a **visibility scope** (`public | mafia | private(seat) | omniscient`, see
  GAME_DESIGN.md §6). Game state is a fold over events. This buys us:
  - *Spoiler-proofing*: any consumer (UI, agent, log) gets `events.visibleTo(seat)`.
  - *Save/load*: a save file is `{config, rngSeed, events[]}`.
  - *Replay*: re-render any past game; LLM responses are recorded as events, so replay
    needs no network.
- **PlayerController interface**: the engine requests decisions
  (`speak`, `nominate`, `vote`, `nightAction`) through one async interface with two
  implementations: `HumanController` (backed by UI futures) and `AgentController`
  (backed by the `llm` package). The engine cannot tell them apart — multi-human or
  fully-headless games come for free.
- **Determinism**: seeded RNG; all nondeterminism (LLM output) enters only as recorded
  events.
- Engine-level timeouts and fallback decisions per action type, so a hung provider
  degrades to a default move instead of freezing the game.

## 4. Concurrency model

- Turn-based flow keeps most LLM calls sequential (discussion is one speaker at a time).
- Night actions for AI players run **concurrently** (Doctor/Sheriff/Assassin/Mafia-chat
  are independent), bounded by a per-provider concurrency limit (default 2) and a
  global limit (default 4) to respect local servers and rate limits.
- LLM/TTS/embedding calls run outside the UI thread (async IO; CPU-heavy embedding in a
  Dart isolate). TTS synthesis is pipelined: while player N's speech plays, player N+1's
  speech is already being generated and synthesized.

## 5. Persistence

| Concern | Choice |
|---|---|
| Structured storage (games, events, agent memories, model cache) | **SQLite via `drift`** — typed schema, migrations, works on all 3 desktops |
| API keys | **`flutter_secure_storage`** → Windows Credential Manager / macOS Keychain / Linux Secret Service (libsecret). Never in SQLite, never in exported saves/logs |
| Settings (endpoints, defaults, personas, voice assignments) | SQLite (single source of truth, exportable minus secrets) |
| Vector data | Same SQLite DB (per-agent chunk tables, embedded vectors as blobs) — scale is tiny (thousands of chunks/game), brute-force cosine in memory is plenty; no vector DB dependency. Option to add `sqlite-vec` later if ever needed |

Save files and exports are **scrubbed by construction**: exports of an unfinished game
include only human-visible events; `omniscient` data is included only for finished games.

## 6. Key Flutter/Dart package choices (to validate in M0 spikes)

| Need | Candidate | Notes |
|---|---|---|
| State management | `flutter_riverpod` | Matches async-heavy app; testable |
| HTTP + SSE streaming | `http` + hand-rolled SSE | Spike-proven against oMLX (docs/SPIKES.md §1); parser must handle chunk-style keepalives and `reasoning_content` deltas |
| SQLite | `drift` | Mature, cross-platform |
| Secure storage | `flutter_secure_storage` | Verify Linux libsecret behavior on distros without a keyring |
| TTS synthesis | `sherpa_onnx` | Runs Piper (VITS) and Kokoro voices in-process, offline, on all 3 desktops — pattern proven in Front Porch AI |
| Audio playback | `audioplayers` (Front Porch AI's choice) | Spike-proven on macOS (docs/SPIKES.md §2); `BytesSource` needs a `mimeType` hint on macOS |
| Local embeddings | `onnxruntime_v2` in-process + bge-small (mirroring Front Porch AI; `unorm_dart` for BERT accent-strip parity) | Fully-offline RAG without asking the user to run an embedding server |
| Window management | `window_manager` | Min size, title, fullscreen |

## 7. Cross-platform packaging (M7)

- **Windows**: MSIX (winget-friendly) + portable zip.
- **macOS**: DMG; requires signing + notarization (Apple Developer account — flagged in
  OPEN_QUESTIONS #7). Universal binary (arm64 + x86_64).
- **Linux**: AppImage + portable tar.gz, attached to GitHub releases only — no hosted package repos (no Flatpak/PPA; maintainer call 2026-07-22).
- CI (GitHub Actions) builds all three on every tag; artifacts attached to releases.

## 8. Observability & testing

- **Structured app log** (never containing hidden-role info outside omniscient channel;
  log files tagged with the same visibility discipline as the UI).
- **Headless simulation mode**: run N full games with cheap/local models or scripted
  bots; assert invariants (game always terminates, visibility never leaks, fallbacks
  fire correctly). Runs in CI with scripted bots; with real local models on demand.
- **Unit tests**: `game_core` rules (role distribution, vote resolution, win detection,
  night resolution matrix incl. Doctor/Assassin/Mafia interactions).
- **Parser fuzz tests**: malformed LLM JSON → parser must recover or fall back, never
  throw into the engine.
- **Leak test as a first-class CI check**: for every generated agent prompt and every
  UI render state in simulation, assert no token of out-of-scope hidden info appears.
