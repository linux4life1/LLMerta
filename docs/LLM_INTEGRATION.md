# LLM Integration

Covers: provider abstraction, model discovery, per-player agent design, context
isolation, structured decision-making, RAG memory, and TTS.

## 1. Provider abstraction

One Dart interface, several adapters:

```
LlmProvider
├── listModels() → List<ModelInfo>        # populates the per-player dropdown
├── chat(messages, params, {tools?, jsonSchema?}) → stream of tokens / final message
└── capabilities                           # streaming? json mode? tool calls? embeddings?
```

### Adapters

| Adapter | Covers | Model listing | Notes |
|---|---|---|---|
| **OpenAI-compatible** | OpenAI, **LM Studio**, **KoboldCpp** (`/v1`), **Ollama** (`/v1`), **MLX servers** (`mlx_lm.server`, mlx-omni-server), OpenRouter, Groq, Mistral, DeepSeek, xAI, Together, vLLM, llama.cpp server… | `GET /v1/models` | One adapter + user-configurable base URL covers the whole local ecosystem and most hosted ones. This is the workhorse. |
| **Anthropic** | Claude models | `GET /v1/models` | Native Messages API (system prompt handling and streaming differ enough to warrant a dedicated adapter) |
| **Google Gemini** | Gemini models | `GET /v1beta/models` | Native API adapter |
| **Ollama native** *(optional)* | Ollama | `GET /api/tags` | Nice-to-haves over its OpenAI shim: richer model metadata, `keep_alive` control |

The brief's "oMLX" is interpreted as **Ollama + MLX-family servers** — both are covered
by the OpenAI-compatible adapter (flagged for confirmation in OPEN_QUESTIONS #4).

### Endpoint configuration UX

Users define **Connections** in Settings: `name + adapter type + base URL + API key
(optional for local)`. Presets ship for the common ones (LM Studio
`http://localhost:1234/v1`, Ollama `http://localhost:11434/v1`, KoboldCpp
`http://localhost:5001/v1`, OpenAI, Anthropic, Google, OpenRouter, Groq…). Each
connection has a **Test** button (ping + list models) and a cached model list with a
refresh action and "last fetched" timestamp. Model dropdowns in the lobby read from
this cache and offer inline refresh; a connection that's down shows its cached list
with a warning badge.

### Resilience

Per-provider request queue with: concurrency limit, timeout, retry w/ exponential
backoff on 429/5xx/network errors, and circuit-breaker status surfaced in the UI
("LM Studio not responding — seat 4 fell back to default action"). Every AI decision
has a deterministic fallback (GAME_DESIGN.md §4.4) so the game always proceeds.

## 2. Per-player agent configuration

Each AI seat in the lobby configures:

- **Connection + model** (dropdown fed by model discovery) — every seat independent.
- **Persona**: display name, avatar, personality archetype, speech style. Ships with a
  library of ~20 presets; user can edit or write custom ones. Persona is cosmetic +
  behavioral flavor only; it never grants game information.
- **Sampling**: temperature, top-p, max output tokens (defaults tuned per phase —
  speeches warmer, decisions cooler).
- **TTS voice** (see §7).
- Bulk actions: "same model for all seats", "randomize personas", "randomize voices".

## 3. Agent session = the unit of context isolation

One `AgentSession` per AI player, holding:

1. **System prompt**: game rules digest, their role card (incl. Mafia teammates if
   applicable), win condition, persona, strategy-guidance block selected by the
   game's difficulty preset (GAME_DESIGN.md §7 — concealment strategy for evil roles,
   claim strategy for power roles), output-format contract.
2. **Facts sheet** (structured, always current, never summarized): alive/dead roster
   with revealed roles, day number, own ability state (bullet spent? last protect?),
   own investigation results, current nominations/votes.
3. **Memory** (§6): rolling summary + retrieved snippets.
4. **Recent verbatim window**: the last K visible events, word-for-word.

Sessions **never** share objects, caches, or histories. The only inputs to a session
are `events.visibleTo(seat)` from the engine. Mafia coordination happens exclusively
through engine-mediated `mafia`-scoped events (their night chat), never through shared
context. This is enforced structurally (the session type has no access to the full
event log) and verified by the CI leak test (ARCHITECTURE.md §8).

## 4. Two-step decisions: think privately, then speak

Every consequential turn is two LLM steps:

1. **Decide** (structured, hidden): "Given your role, goals, and the situation, decide
   your objective for this speech / your vote / your night action, with a one-line
   rationale." → JSON, stored as a `private(seat)` event (visible in post-game reveal).
2. **Perform** (public): "Write your speech (≤120 words) in persona, serving that
   objective. Do not reveal hidden information unless your objective says to claim."

This separation measurably reduces accidental role confession, keeps public speech in
persona, and gives the post-game reveal fascinating "what were they thinking" material.

### Structured output strategy

- Where supported (OpenAI `json_schema`, Ollama/LM Studio structured output, Anthropic
  tool-use), use native structured modes.
- Otherwise: JSON-in-prompt with a tolerant extractor (strip code fences, find first
  balanced object, coerce enums, fuzzy-match player names to seat IDs).
- On parse failure: one corrective retry with the error shown to the model; then
  deterministic fallback. Parse failures are logged per model to help users spot weak
  models.

## 5. Prompt assembly (per call)

```
[system]  rules digest + role card + persona + format contract
[user]    FACTS (verbatim, structured)
          SUMMARY of the game so far (rolling, per-agent)
          RELEVANT PAST EVENTS (RAG retrieval, quoted verbatim)
          RECENT EVENTS (last K visible events, verbatim)
          YOUR TASK (phase-specific instruction + schema)
```

Budgeted to fit small local contexts (target: playable at 8k context): facts and task
are fixed-cost; summary is capped; retrieval count and verbatim window shrink first.

## 6. RAG memory (per agent)

Games can run 10+ day/night cycles × up to 14 speakers — far past small-model context.
Memory is **per-agent** (each knows only what it saw) with three tiers:

1. **Facts sheet** — ground truth, updated by the engine, never compressed (§3.2).
2. **Rolling summary** — at each phase boundary, the agent's session appends a compact
   summary of that phase *from its own perspective* ("Day 3: Riya accused me; I voted
   Marcus; vote failed 4–4"). Old phase summaries get re-compacted when the summary
   exceeds its token budget. Summarization uses the same model as the agent (or a
   configurable cheap "utility model" — lobby option).
3. **Vector retrieval** — every visible event is chunked (speech = one chunk) and
   embedded into the agent's private store. At prompt time, the current task ("who do
   I vote for?") retrieves top-k relevant past chunks (e.g., every past statement by
   the current suspect) quoted verbatim.

**Embeddings**: default is a bundled small local model via ONNX (`fonnx`,
bge-small-class, ~30 MB, CPU-fast) so RAG works offline with zero setup; configurable
to any OpenAI-compatible `/v1/embeddings` endpoint (LM Studio and Ollama both serve
embedding models). Brute-force cosine over a few thousand vectors per agent is
microseconds — no vector DB (ARCHITECTURE.md §5).

## 7. TTS: Kokoro + Piper

```
TtsEngine
├── listVoices() → List<VoiceInfo>
├── synthesize(text, voice) → audio (WAV/PCM)
└── engine implementations ↓
```

| Engine | Integration | Voices |
|---|---|---|
| **Piper** | Bundled/locatable native binary run via `Process` (stdin text → stdout WAV). Voice = downloadable `.onnx` model files; app offers a voice-download manager for the popular set | Many, per-language, very fast on CPU |
| **Kokoro** | Two paths: (a) **Kokoro-FastAPI server** via OpenAI-compatible `/v1/audio/speech` — works today with zero bundling; (b) *stretch*: embedded kokoro-onnx via `fonnx` for zero-setup local Kokoro | ~50 high-quality voices |
| **OpenAI-compatible speech** *(free by-product of (a))* | Any `/v1/audio/speech` endpoint | Whatever the server offers |

- **Per-player voice assignment** in the lobby (dropdown per seat + "randomize all",
  no duplicate voices unless the user forces it). The Narrator gets its own voice.
- **Playback pipeline**: synthesis runs one speech ahead of playback (text appears
  immediately; audio starts when ready). Queue is strictly ordered — no overlapping
  speakers. Controls: skip current speech, mute TTS entirely ("fast mode"), per-voice
  speed.
- Caching: synthesized audio for a game is cached on disk keyed by (engine, voice,
  text hash) — replays and re-listens are free.

## 8. Cost & latency controls

- Per-seat model choice already lets users mix one strong model with cheap ones.
- Hard caps: max output tokens per speech; discussion rounds configurable; optional
  "utility model" handles summarization/embedding-adjacent work.
- Live token/latency meter per provider in a collapsible status panel; per-game token
  usage report in the post-game screen (per seat, so users see which model cost what).
- All caps degrade gracefully: over-budget prompt → shrink retrieval → shrink verbatim
  window → summarize harder. Never silently drop the facts sheet.
