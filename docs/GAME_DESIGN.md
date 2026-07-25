# Game Design

This document defines the rules the engine implements. Anything marked **(config)** is a
setting the user can change in the lobby; the listed value is the default.

## 1. Overview

Mafia is a hidden-role social deduction game played in alternating **Night** and **Day**
phases. An informed minority (the Mafia) eliminates one player per night; the uninformed
majority (the Town) tries to identify and vote out the Mafia during the day. The game is
built for **7–14 total players**: 1 human + 6–13 LLM agents.

## 2. Roles

| Role | Alignment | Ability |
|---|---|---|
| **Mafia** | Mafia | Know each other. Each night, privately discuss and collectively choose one victim. |
| **Doctor** | Town | Each night, chooses one player to protect. A protected player survives that night's kill attempt(s). |
| **Sheriff** (a.k.a. Detective) | Town | Each night, investigates one player and learns their alignment: *Mafia* or *Not Mafia*. |
| **Assassin** | Town *(default — see [OPEN_QUESTIONS #1](OPEN_QUESTIONS.md))* | Holds a single bullet for the entire game. On any night, may choose to kill one player. Once used, the ability is gone — the Assassin plays on as an ordinary townsperson. |
| **Villager** | Town | No night ability. Discusses, deduces, votes. |

Role rules and defaults:

- **Doctor** may protect themself **(config: on)**, but not the same target two nights in
  a row **(config: on)**.
- **Sheriff** results are binary (*Mafia* / *Not Mafia*). The Assassin investigates as
  *Not Mafia*.
- **Assassin**'s shot resolves the same night as a Mafia kill; both can die in one night.
  The Doctor's protection blocks the Assassin's bullet too (the bullet is still spent).
- If the Mafia target and Assassin target are the same person and the Doctor protects
  them, nobody dies that night.

## 3. Role distribution by player count

Roughly 25–30% of seats are Mafia. The special town roles (Doctor, Sheriff, Assassin)
are always present. **(config: each special role can be toggled off; Mafia count can be
overridden ±1.)**

| Total players | Mafia | Doctor | Sheriff | Assassin | Villagers |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 7  | 2 | 1 | 1 | 1 | 2 |
| 8  | 2 | 1 | 1 | 1 | 3 |
| 9  | 2 | 1 | 1 | 1 | 4 |
| 10 | 3 | 1 | 1 | 1 | 4 |
| 11 | 3 | 1 | 1 | 1 | 5 |
| 12 | 3 | 1 | 1 | 1 | 6 |
| 13 | 4 | 1 | 1 | 1 | 6 |
| 14 | 4 | 1 | 1 | 1 | 7 |

The human is dealt a role at random **(config: a "choose my role" debug option exists
but is off by default — see [OPEN_QUESTIONS #2](OPEN_QUESTIONS.md))**.

## 4. Game flow

The engine is a state machine. Every transition emits events with an explicit
**visibility scope** (see §6) — this is what makes spoiler-proofing and per-agent
context isolation possible.

### 4.1 Setup

1. User picks player count, per-seat model/persona/voice, and rule config in the lobby.
2. Seats are arranged around a virtual table; roles dealt with a seeded RNG
   (seed recorded for replay).
3. Each player privately receives their **role card**. Mafia members additionally learn
   who their teammates are.

### 4.2 Night 0 (first night — no kill) **(config: on)**

- Mafia hold a short private chat to acquaint and plan (no kill on Night 0).
- Sheriff gets a free investigation **(config: off)**.
- Purpose: gives the Mafia agents shared strategy before Day 1 so early-game play
  isn't random.
- Day 1 is a full day like any other — discussion, nominations, and a vote; it simply
  opens with no deaths to report.

### 4.3 Day phase

1. **Dawn announcement** — the Narrator reports who died in the night (or that nobody
   did). Dead players' roles are revealed **(config: reveal-on-death on; "closed roles"
   variant hides them)**.
2. **Discussion** — each living player speaks once, in seat order, starting from a
   rotating position (so the same player isn't always first). **(config: 1 round;
   up to 2)**. Speeches are bounded (target ≤ 120 words — enforced in the agent prompt
   and by UI guidance for the human). After each circle, **crossfire** runs
   **(config: default 1 pass)**: each living player may challenge one other player
   with a full argument (same ~120-word budget as discussion); the target gets an
   **immediate full rebuttal** before the next challenger. That break-out is how
   mid-table arguments happen instead of pure monologues.
3. **Nomination** — each living player, in seat order, may nominate one player for
   elimination (or pass). A nomination is a public act: the nominator states their
   case aloud to the table (recorded as the nomination's statement, spoken by TTS,
   and paced like any speech). The **two most-nominated** players go on trial (a tie for a trial slot goes
   to whoever reached that nomination count first); a single nominee stands trial
   alone. If nobody is nominated, the day ends.
4. **Defense** — each nominee gives a short defense statement.
5. **Vote** — all living players (nominees included **(config)**) vote simultaneously
   for one nominee or abstain. **A nominee may never vote for themself** (the ballot
   simply doesn't offer it). Votes are public once all are cast **(config: public)**.
6. **Verdict** — the nominee with the most votes is eliminated if the count is a
   strict plurality. **Tie → nobody is eliminated** **(config: alternatives — runoff
   vote, or random among tied)**.
7. **Last words** — an eliminated player gives a brief final statement.

### 4.4 Night phase

All night actions are collected privately and resolved simultaneously:

1. **Mafia chat** — living Mafia exchange 1–2 short private messages each, then each
   votes a kill target. Plurality wins; the senior member (first living Mafia in
   seat order) breaks ties.
2. **Doctor** picks a protection target.
3. **Sheriff** picks an investigation target; receives the result immediately.
4. **Assassin** (if bullet unspent) may pick a target or hold.
5. **Resolution** — protection is applied, deaths are computed, and the engine
   advances to the next Day.

If the human holds a night role, the UI prompts them; AI actions are gathered
concurrently. A per-action timeout with a sensible default (Mafia: random-among-suspects
fallback; Doctor: self; Sheriff: random unvisited; Assassin: hold) guarantees the game
never stalls on a misbehaving model.

### 4.5 Win conditions (checked after every death, day or night)

- **Town wins** when all Mafia are eliminated.
- **Mafia wins** when living Mafia ≥ living non-Mafia ("parity" — at that point the
  Mafia controls every vote).
- Assassin is Town-aligned by default, so no separate win condition. (If changed to a
  third party, this section gains a survival condition — tracked in OPEN_QUESTIONS.)

### 4.6 Post-game

Full reveal: every player's role, the complete event log including Mafia night chat,
each AI's private reasoning (optional toggle — great for understanding how the models
played), and a game summary. Exportable as Markdown/JSON.

**Table talk (2026-07-22)**: after the reveal, an open conversation phase — the AIs
and the human rehash the game with full hindsight (confessions, told-you-sos,
grudge foreshadowing). Nothing is secret anymore, so agents speak with omniscient
context. Implemented in `llm` as `postGameTableTalk` (CLI: `--wrapup <rounds>`);
the Reveal screen hosts it as a chat panel in M3.

## 5. The human player

- Speaks during discussion via text input (STT is a possible later addition — see
  OPEN_QUESTIONS #5). A countdown-free flow: the game waits for the human, with an
  optional "skip / say nothing" button.
- Nominates, votes, and performs night actions through dedicated UI, never free text —
  no parsing ambiguity for actions that change game state.
- May take notes in a built-in notepad panel (private, persisted with the save).

## 6. Information visibility model (spoiler-proofing)

Every event in the game carries exactly one scope:

| Scope | Visible to | Examples |
|---|---|---|
| `public` | All players + UI | Speeches, votes, deaths, narrator announcements |
| `mafia` | Living Mafia members | Mafia night chat, kill decision, teammate identities |
| `private(player)` | Exactly one player | Role card, Sheriff results, Doctor/Assassin choices, own scratchpad |
| `omniscient` | Nobody during play; post-game reveal + saved replays only | Role assignments, resolution internals |

Hard rules derived from this model:

- The renderer receives **only** events visible to the human's seat. A non-Mafia human
  cannot have Mafia identities in the UI process's render state, in logs, or in any
  on-screen debug surface. There is nothing to "accidentally" reveal.
- Each AI agent's prompt is built **only** from events visible to its seat (see
  LLM_INTEGRATION.md §5).
- Dev/debug omniscient view exists but requires an explicit "spoil this game" toggle
  that watermarks the session as spoiled in the save file.

## 7. Difficulty presets (v1)

A game-level lobby setting — **Casual / Standard / Cutthroat** — that swaps the
strategy-guidance block in every AI agent's system prompt **and** applies a small
house-rules bundle. Difficulty never grants hidden information; the visibility
model is identical at every level. Players can still override any house rule in
the lobby after picking a preset.

| Preset | Evil play | Town play | House rules |
|---|---|---|---|
| **Casual** | Mafia deflect simply, avoid long cons, pick targets on obvious grudges | Direct gut reads; power roles claim readily under pressure | 2 discussion rounds, runoff ties, `mafiaCountDelta: -1`, Night-0 sheriff peek |
| **Standard** | Mafia coordinate targets, manage suspicion across days | Town cross-references votes and statements before deciding | 2 discussion rounds, runoff ties |
| **Cutthroat** | Mafia run multi-day frame jobs and will bus a teammate to buy credibility | Town rigorously tracks voting patterns, claim timing, and inconsistencies | 2 discussion rounds, tie = nobody eliminated |

Each preset has its own balance benchmark in headless testing (ROADMAP.md M6).

**Assassin feedback**: after a spent bullet resolves, the Assassin privately
learns whether the shot landed (or was Doctor-blocked) and whether the target
was Mafia. That feedback is `private(assassin)` only.

## 8. Design notes on AI play quality

Known failure modes of LLMs in social deduction, and how the design counters them:

1. **Accidental confession** (Mafia agent blurts out its role): decisions and public
   speech are generated in separate steps. The agent first privately decides
   *what it wants to accomplish* (structured output), then writes a speech to serve
   that goal, with the role card framed as "information you must conceal."
2. **Bland, repetitive speeches**: every agent gets a distinct persona (name, occupation
   flavor, personality, speech style, quirk) sampled from a persona library, plus its
   own model choice — model diversity itself produces play-style diversity.
3. **Forgetting mid-game facts** ("wasn't Player 3 already dead?"): the facts sheet +
   RAG memory (LLM_INTEGRATION.md §6) pins ground truth — alive/dead list, own role,
   investigation results — into every prompt verbatim, never summarized.
4. **Herd voting**: nomination and voting prompts require a one-line private
   justification (structured, hidden) before the vote, and discussion order rotates
   so the same agent doesn't anchor every day.
5. **Stalling / malformed output**: every AI decision has a schema, a retry, and a
   deterministic fallback (§4.4) so one bad model can't freeze the game.
