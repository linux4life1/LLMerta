# LLMerta

*LLM + omertà — the code of silence. (Formerly "Mafia: LLM Tabletop Game".)*

Licensed under the [GNU AGPL v3](LICENSE), like its sister project Front Porch AI.

A fully cross-platform (Windows / macOS / Linux) single-player implementation of the
social deduction game **Mafia**, where every seat except yours is filled by an LLM.

Mafia normally needs 8+ humans. Here, one human plays alongside 6–13 AI players
(7–14 total seats), each AI powered by an independently selectable model — local
(KoboldCpp, LM Studio, Ollama, MLX servers) or hosted (OpenAI, Anthropic, Google,
OpenRouter, and other major providers). Each AI player has its own isolated context,
its own persona, its own memory (RAG-backed so games can run past any model's context
window), and its own TTS voice (Kokoro or Piper).

> **Status: planning / design phase.** No code yet. This repository currently contains
> the design documents that define what we're building and how.

## Design documents

| Document | Contents |
|---|---|
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | Rules, roles, role distribution for 7–14 players, day/night flow, win conditions, information-visibility model |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Tech stack decision (Flutter), module layout, game engine design, persistence, save/replay |
| [docs/LLM_INTEGRATION.md](docs/LLM_INTEGRATION.md) | Provider abstraction, model discovery, per-player agent sessions, context isolation, structured decisions, RAG memory, TTS |
| [docs/UI_UX.md](docs/UI_UX.md) | Screen inventory, game-table layout, immersion / spoiler-prevention rules, accessibility |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Milestones M0–M7 with acceptance criteria |
| [docs/OPEN_QUESTIONS.md](docs/OPEN_QUESTIONS.md) | Decisions that need your sign-off before or during implementation |

## Core requirements (from project brief)

1. **Cross-platform desktop**: Windows, macOS, Linux from one codebase.
2. **7–14 players**, exactly one human; all other seats are LLM agents.
3. **Roles**: Mafia (team), Doctor, Sheriff/Detective, Assassin (one strike per game), Villagers.
4. **Local + hosted LLMs**: KoboldCpp, LM Studio, Ollama, MLX-based servers, plus all
   major API providers.
5. **Per-player model dropdown**, populated by polling each provider's model-list endpoint.
6. **Strict context isolation** — no AI player ever sees another player's private context.
7. **RAG memory per player** — games are long and multi-turn; agents must remain coherent
   beyond their model's context limit.
8. **TTS**: Kokoro and Piper, with per-player voice assignment.
9. **Spoiler-proof UI**: the human only ever sees information their role entitles them to.
   Full reveal only after the game ends.
10. **Full UI** — this is a game, not a terminal toy. Flutter is the chosen framework
    (see ARCHITECTURE.md for the comparison).
