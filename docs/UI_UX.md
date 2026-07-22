# UI / UX

## 1. Screen inventory

| Screen | Purpose |
|---|---|
| **Home** | New game, Continue, Replays, Settings, How to Play |
| **Settings → Connections** | Manage provider connections (base URL, key, test, model cache refresh) |
| **Settings → TTS** | Configure Piper binary/voices, Kokoro endpoint, narrator voice, playback defaults |
| **Settings → Personas** | Browse/edit/create the persona library |
| **Lobby (Game Setup)** | Player count slider (7–14), difficulty preset (Casual / Standard / Cutthroat), rule config, town-name re-roll, and the **seat grid**: one card per AI seat with persona, connection+model dropdown, sampling, voice; bulk actions. **The human seat is never a house persona by default**: name yourself, build a persona, or import one of your own v2 cards — grudge memory then tracks *you* across games |
| **Game Table** | The main in-game screen (below) |
| **Post-Game Reveal** | Full reveal: roles, timeline, Mafia chat, AI private reasoning, token usage; export |
| **Replays** | Load a finished/saved game; step through events |

## 2. Game Table layout

The centerpiece. Elliptical "table" with player cards arranged around it:

- **Player card**: avatar, persona name, seat number, status (alive / dead with role
  reveal if config allows / on-trial), speaking indicator (animated ring + waveform
  while TTS plays), vote badge during votes, "that's you" marker on the human.
- **Imported v2 cards double as avatars**: a card PNG imported as a persona
  (llm `Persona.avatarPath`) is also the seat portrait — one Front Porch AI
  card supplies face and character both.
- **Center stage**: current phase banner (Day 3 — Discussion), the Narrator's latest
  announcement, and the active speaker's speech as large readable text, synchronized
  with TTS playback.
- **Transcript panel** (collapsible side drawer): scrollback of all *human-visible*
  events, filterable by day/phase/player. This is also where the human reads at their
  own pace with TTS off.
- **Human dock** (bottom): context-sensitive — text box during discussion ("You're up"
  state), nominate/vote buttons with portraits during votes, night-action target
  picker when applicable, "waiting" state showing whose turn it is otherwise.
- **Notes panel**: private notepad, persisted with the save.
- **Status strip**: provider health, token meter, TTS queue, settings shortcut, save &
  exit.

### Mafia-specific UI (only when the human is Mafia)

- Teammates visibly badged on their cards (only for the human-as-Mafia).
- Night: a private chat panel with the AI teammates + kill-target selector.

### Night overlay (human has no night action)

Dimmed "town sleeps" scene with subtle progress ("The town sleeps… someone is
stirring") — no information about *which* roles are acting (fixed-order, fixed-duration
messaging so timing leaks nothing).

## 3. Immersion & spoiler rules (UI contract)

1. UI state is built exclusively from `events.visibleTo(humanSeat)` — hidden info is
   absent from the render layer by construction (ARCHITECTURE.md §3).
2. No timing/layout tells: night resolution shows fixed-order, fixed-pace messaging
   regardless of what actually happened; AI "thinking" indicators are shown for all
   seats uniformly during nights.
3. Dead human becomes a spectator but **still sees only public info** until game end
   **(config: "ghost mode — reveal all on my death" off by default)**.
4. Day/night visual themes (warm day palette ↔ dark night palette), ambient audio
   beds **(config)**, death/vote stingers. Skippable everywhere — respect impatient
   players.
5. Post-game reveal is the payoff screen: role reveal animation, full timeline
   including everything hidden, AI reasoning peek, stats (votes cast, accuracy of the
   town, MVP heuristics).

## 4. Locked UX decisions (2026-07-22, from UX Draft v1 review)

1. **One unified layout.** The elliptical table is the only table layout, scaling from
   7 to 14 seats by resizing seat cards and widening the ellipse. No alternate layout
   modes tied to player count.
2. **Transcript drawer** defaults to collapsed at every window size; one click opens it.
3. **Voting is two-step** for the human: select, then Lock. AI votes lock as they
   arrive; all votes reveal simultaneously once the last one locks.
4. **The Narrator is a voice, not a body**: text line + TTS voice; no seat, no avatar.
5. **Human speech length** is soft guidance ("aim for under 120 words"), no hard cap.
6. **Town name is generated randomly per game** from a curated pool (re-roll in the
   lobby). It anchors narrator copy, persona flavor, and save names.
7. **Ambient audio** (day/night beds) ships on by default with one-click mute; TTS
   volume is independent.

## 5. Accessibility & quality of life

- All TTS content always available as text; TTS fully optional.
- Keyboard navigation for every game action; font scaling; reduced-motion mode;
  color-blind-safe status indicators (never color alone).
- Window resize down to laptop-small without breaking the table layout (cards collapse
  to a compact list under a width threshold).
- Autosave every phase boundary; crash-safe resume (event sourcing makes this cheap).
- First-run experience: guided "setup check" (pick/verify a connection, fetch models,
  optional TTS check) + a 2-minute interactive rules primer for players new to Mafia.
