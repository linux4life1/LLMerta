# CLAUDE.md

## Project

Mafia: LLM Tabletop Game — single-player Mafia (7–14 seats) where every non-human
seat is an LLM agent. Flutter desktop app for Windows/macOS/Linux.

The design docs in `docs/` are authoritative. Read `docs/GAME_DESIGN.md` before
touching rules/engine code and `docs/ARCHITECTURE.md` before adding packages or
dependencies. Monorepo layout per ARCHITECTURE.md §2: `app/` (Flutter) +
`packages/{game_core,llm,memory,tts,persistence}` (pure Dart, no Flutter deps).

## Hard rules

1. **≤600 lines per Dart file.** Split before you approach the limit. Generated files
   (`*.g.dart`, `*.freezed.dart`) are exempt. Enforced by CI script.
2. **Riverpod is the only state management.** See below.
3. **Barrel imports only** across package/feature boundaries. See below.
4. **Minimal boilerplate, minimal comments.** Comments exist only to state a
   non-obvious constraint or invariant. No narration, no section banners, no
   doc-comments that restate the identifier. Prefer codegen (`riverpod_generator`,
   `freezed`, `drift`) over hand-written boilerplate.
5. **DRY.** Before writing a helper, widget, or mapper, search for an existing one.
   Shared logic lives in the lowest package that all consumers can depend on. Three
   similar blocks = extract.
6. **Coverage ≥90%** overall (line), enforced in CI. Generated files excluded.
   `game_core` targets ~100%.
7. **Visibility invariant** (spoiler-proofing): UI render state and agent prompts are
   built exclusively from `events.visibleTo(seat)`. Never hand the full event log to
   a widget or an agent session. The CI leak test is a required check — do not weaken
   it to make a feature pass.

## Riverpod

- `flutter_riverpod` + `riverpod_annotation` codegen (`@riverpod`) for all providers.
- Widgets are `ConsumerWidget` / `ConsumerStatefulWidget`. `ref.watch` in `build`,
  `ref.read` in callbacks. Never store `ref` outside widget/provider lifecycles.
- No `setState` for shared or business state (ephemeral view-local state —
  animations, text controllers, focus — is fine). No ChangeNotifier, no singletons,
  no service locators, no other state packages.
- Async state is `AsyncValue<T>`; handle loading/error states in the UI, don't
  unwrap blindly.
- State classes are immutable (`freezed` when unions/`copyWith` are needed).
- Pure Dart packages (`game_core`, `llm`, `memory`, `tts`, `persistence`) must not
  depend on Riverpod. Providers live in `app/`, wrapping package APIs.

## Imports & structure

- Every package exposes its public API through one barrel: `lib/<package>.dart`.
  Implementation lives under `lib/src/`. Consumers import the barrel, never `src/`
  paths.
- In `app/`, each feature folder (`lobby/`, `game_table/`, `settings/`, …) has a
  barrel; cross-feature imports go through it. Within a feature, relative imports
  are fine.
- No `part` / `part of` except for codegen outputs.
- No circular dependencies between packages or features; the dependency direction is
  `app → packages → game_core`.

## Testing

- **≥90% line coverage** across the repo, gated in CI (`flutter test --coverage` +
  lcov threshold check). Don't chase the number with vacuous tests; cover behavior.
- **Widget tests** for every screen and interactive component, including all states
  of the human dock (speak / nominate / vote / night action / waiting).
- **Golden tests** for visual states: player card variants (alive, dead, on-trial,
  speaking, Mafia-badged), phase banners, day/night themes, game table at minimum
  and default window sizes. Goldens run on Linux CI only (tag: `golden`); update
  with `flutter test --update-goldens --tags golden`.
- **Unit tests**: full rules matrix in `game_core` (night resolution, votes/ties,
  role distribution, win detection, timeouts/fallbacks).
- **Fuzz tests** for the LLM output parser: malformed JSON must degrade to fallback,
  never throw into the engine.
- **Leak test**: simulated games assert no out-of-scope hidden info appears in any
  agent prompt or human-visible render state.
- Engine tests use seeded RNG and scripted `PlayerController`s — no network, no LLM
  calls in CI.

## Style

- `dart format` clean; `flutter analyze` zero warnings. Lints: `flutter_lints` base
  plus stricter rules in the root `analysis_options.yaml` once scaffolded.
- Naming and idiom follow the surrounding code; match existing patterns before
  inventing new ones.
- No secrets in code, config, fixtures, or logs. API keys only via
  `flutter_secure_storage`.

## Git

- Develop on feature branches; keep CI green before merging.
- Commit messages: imperative summary line, body explains why when non-obvious.
- Never commit generated coverage output, build artifacts, or `.env`-style files.
