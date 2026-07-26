# Porch memories (LLMerta → Front Porch AI)

**Status:** LLMerta producer shipped. FPA consumer not yet.

After a finished game, LLMerta can write **multi-card, emotion-stamped diary
seeds** about what the human’s FPA **user persona** did to each FPA-origin
character at the table. FPA will plant these into The Journal later.

## Flow

1. Deal with an FPA **user persona** (human seat) and AI seats cast from
   **imported FPA cards** (each has `fpaCharacterId` = card basename /
   `stableGroupId`).
2. Lobby toggle **Front Porch memories** on (default on).
3. Game ends → LLMerta extracts cards from the full event log (post-reveal).
4. Writes **one bundle file per finished game** under the local FPA install:

```text
~/Documents/FrontPorchAI/KoboldManager/llmerta_porch_memories/
  {gameId}.json          ← game 1 (all FPA characters at that table)
  {otherGameId}.json     ← game 2, etc. — files accumulate
```

5. FPA (future): import pending bundles, plant Journal cards for matching
   `(characterId, userPersonaId)`, then **delete each bundle** after a
   successful import. LLMerta never deletes mailbox files.

**No garbage:** if the human is not an FPA persona, or the table has no
FPA-linked characters, LLMerta writes **nothing** (no empty files, no dir).

LLMerta never opens FPA’s `JournalMemories` table. No reverse direction.

## Identity (no name resolution)

| Role | Key |
|---|---|
| Human | FPA `personas.id` stored on cast at Deal (`personaId`) |
| Character | `fpaCharacterId` on `CustomPersonas` / cast JSON |

House library seats and free-typed humans produce **no** export.

## Card catalog (deterministic)

Per FPA character seat, up to 8 cards including:

- `playedTogether` (fond frame)
- `sharedVictory` / `sharedLoss`
- `mafiaPartner`, `busedByUser`, `votedOutByUser`, `defendedByUser`
- `nominatedByUser`, `challengedByUser`
- `killedByMafiaWithUser`, `assassinatedByUser`, `savedByUser`
- `userVotedMyNightKill` (mafia-only, post-reveal)

Each card has `category` (`about_user` / `about_us` / `moment`),
`emotionLabel`, `emotionIntensity`, and stable `id`.

## Schema (`schemaVersion: 1`) — one bundle per game

```json
{
  "schemaVersion": 1,
  "gameId": "game-…",
  "finishedAt": "2026-07-25T…Z",
  "townName": "Brasshollow",
  "difficulty": "standard",
  "userPersonaId": "…",
  "userPersonaName": "Joseph",
  "characters": [
    {
      "characterId": "alma_card",
      "characterName": "Alma",
      "cards": [ { "id", "kind", "category", "content", "emotionLabel", "emotionIntensity", "salience", … } ]
    }
  ]
}
```

Card field details: `PorchMemoryCard.toJson()` in
`packages/llm/lib/src/porch_memories.dart`.

## Gates (all required)

| Gate | Otherwise |
|---|---|
| Lobby **Front Porch memories** on | skip |
| Human seat has FPA `personaId` (not “Just yourself”) | skip |
| ≥1 AI seat with `fpaCharacterId` (imported FPA card) | skip |
| Finished log (`RolesDealt` + `GameEnded`) | skip |
| FPA KoboldManager tree present on disk | skip |

Missing FPA install → silent skip (game still completes). Multiple finished
games always leave **separate** `{gameId}.json` files until FPA imports them.
