import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';

import 'fpa_install.dart';

/// Schema version for the pending JSON FPA will consume.
const porchMemoriesSchemaVersion = 1;

/// Max diary cards per FPA character per game (frame + spikes).
const porchMemoriesMaxCards = 8;

/// Seat map + human identity for a finished game export.
class PorchCast {
  const PorchCast({
    required this.humanSeat,
    required this.names,
    required this.humanPersonaId,
    required this.humanPersonaName,
    required this.fpaCharacterIds,
    this.townName,
    this.difficulty,
  });

  final int humanSeat;
  final List<String> names;

  /// FPA `personas.id`. Null → no export.
  final String? humanPersonaId;
  final String humanPersonaName;

  /// Seat → FPA `stableGroupId`. Missing/null seats are skipped.
  final Map<int, String?> fpaCharacterIds;
  final String? townName;
  final String? difficulty;
}

enum PorchMemoryKind {
  playedTogether,
  sharedVictory,
  sharedLoss,
  mafiaPartner,
  busedByUser,
  votedOutByUser,
  defendedByUser,
  nominatedByUser,
  challengedByUser,
  killedByMafiaWithUser,
  assassinatedByUser,
  savedByUser,
  userVotedMyNightKill,
}

enum PorchMemoryCategory { aboutUser, aboutUs, moment }

enum PorchEmotionIntensity { mild, moderate, strong }

class PorchMemoryCard {
  const PorchMemoryCard({
    required this.id,
    required this.kind,
    required this.category,
    required this.content,
    required this.emotionLabel,
    required this.emotionIntensity,
    required this.salience,
    this.dayHint,
  });

  final String id;
  final PorchMemoryKind kind;
  final PorchMemoryCategory category;
  final String content;
  final String emotionLabel;
  final PorchEmotionIntensity emotionIntensity;
  final double salience;
  final int? dayHint;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'category': switch (category) {
      PorchMemoryCategory.aboutUser => 'about_user',
      PorchMemoryCategory.aboutUs => 'about_us',
      PorchMemoryCategory.moment => 'moment',
    },
    'content': content,
    'emotionLabel': emotionLabel,
    'emotionIntensity': emotionIntensity.name,
    'salience': salience,
    if (dayHint != null) 'dayHint': dayHint,
    'source': {'kind': kind.name},
  };

  static PorchMemoryCard fromJson(Map<String, Object?> json) => PorchMemoryCard(
    id: json['id']! as String,
    kind: PorchMemoryKind.values.byName(json['kind']! as String),
    category: switch (json['category'] as String?) {
      'about_us' => PorchMemoryCategory.aboutUs,
      'moment' => PorchMemoryCategory.moment,
      _ => PorchMemoryCategory.aboutUser,
    },
    content: json['content']! as String,
    emotionLabel: json['emotionLabel']! as String,
    emotionIntensity: PorchEmotionIntensity.values.byName(
      json['emotionIntensity']! as String,
    ),
    salience: (json['salience'] as num).toDouble(),
    dayHint: json['dayHint'] as int?,
  );
}

class PorchGameExport {
  const PorchGameExport({
    required this.gameId,
    required this.finishedAt,
    required this.userPersonaId,
    required this.userPersonaName,
    required this.characterId,
    required this.characterName,
    required this.cards,
    this.townName,
    this.difficulty,
  });

  final String gameId;
  final DateTime finishedAt;
  final String userPersonaId;
  final String userPersonaName;
  final String characterId;
  final String characterName;
  final List<PorchMemoryCard> cards;
  final String? townName;
  final String? difficulty;

  Map<String, Object?> toJson() => {
    'schemaVersion': porchMemoriesSchemaVersion,
    'gameId': gameId,
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    if (townName != null) 'townName': townName,
    if (difficulty != null) 'difficulty': difficulty,
    'userPersonaId': userPersonaId,
    'userPersonaName': userPersonaName,
    'characterId': characterId,
    'characterName': characterName,
    'cards': [for (final c in cards) c.toJson()],
  };

  static PorchGameExport fromJson(Map<String, Object?> json) => PorchGameExport(
    gameId: json['gameId']! as String,
    finishedAt: DateTime.parse(json['finishedAt']! as String),
    townName: json['townName'] as String?,
    difficulty: json['difficulty'] as String?,
    userPersonaId: json['userPersonaId']! as String,
    userPersonaName: json['userPersonaName']! as String,
    characterId: json['characterId']! as String,
    characterName: json['characterName']! as String,
    cards: [
      for (final c in json['cards']! as List)
        PorchMemoryCard.fromJson((c as Map).cast<String, Object?>()),
    ],
  );
}

/// Pending mailbox under the **bound** Front Porch AI install.
/// FPA deletes each bundle file after a successful import; LLMerta only appends.
/// Root comes from [resolveFpaInstall] (Stable or Rawhide Beta — never both).
Directory? detectPorchMemoriesDir({String? homeOverride}) {
  final install = resolveFpaInstall(homeOverride: homeOverride);
  return install?.porchMemoriesDir;
}

/// True only when the human is an FPA user persona and at least one AI seat
/// is an FPA-linked character — otherwise there is nothing real to export.
bool porchCastEligible(PorchCast cast) {
  final userId = cast.humanPersonaId;
  if (userId == null || userId.isEmpty) return false;
  return cast.fpaCharacterIds.values.any(
    (id) => id != null && id.isNotEmpty,
  );
}

/// One **bundle file per finished game** (many games → many files in the
/// mailbox). FPA owns deletion after import. Returns total cards written, or
/// null if [exports] is empty (never creates garbage files/dirs).
///
/// Same [gameId] re-write is idempotent (overwrite). Distinct gameIds never
/// clobber each other.
int? writePorchBundle(Directory dir, List<PorchGameExport> exports) {
  if (exports.isEmpty) return null;
  final first = exports.first;
  for (final e in exports) {
    if (e.gameId != first.gameId || e.userPersonaId != first.userPersonaId) {
      throw ArgumentError(
        'writePorchBundle expects one gameId + userPersonaId per call',
      );
    }
  }
  dir.createSync(recursive: true);
  final file = File(
    '${dir.path}/${_safeFileToken(first.gameId)}.json',
  );
  final totalCards = [
    for (final e in exports) e.cards.length,
  ].fold<int>(0, (a, b) => a + b);
  final bundle = <String, Object?>{
    'schemaVersion': porchMemoriesSchemaVersion,
    'gameId': first.gameId,
    'finishedAt': first.finishedAt.toUtc().toIso8601String(),
    if (first.townName != null) 'townName': first.townName,
    if (first.difficulty != null) 'difficulty': first.difficulty,
    'userPersonaId': first.userPersonaId,
    'userPersonaName': first.userPersonaName,
    'characters': [
      for (final e in exports)
        {
          'characterId': e.characterId,
          'characterName': e.characterName,
          'cards': [for (final c in e.cards) c.toJson()],
        },
    ],
  };
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(bundle),
  );
  return totalCards;
}

String _safeFileToken(String raw) =>
    raw.replaceAll(RegExp(r'[^\w.\-]+'), '_');

/// Deterministic multi-card diary seeds for FPA Journal (post-reveal only).
/// Returns empty when cast is ineligible (no FPA persona and/or no FPA seats).
List<PorchGameExport> extractPorchMemories({
  required String gameId,
  required List<GameEvent> events,
  required PorchCast cast,
  DateTime? finishedAt,
  int maxCards = porchMemoriesMaxCards,
}) {
  if (!porchCastEligible(cast)) return const [];
  final userId = cast.humanPersonaId!;
  final roles = events.whereType<RolesDealt>().firstOrNull?.roles;
  if (roles == null) return const [];
  if (events.whereType<GameEnded>().isEmpty) return const [];

  final when = finishedAt ?? DateTime.now().toUtc();
  final human = cast.humanSeat;
  final you = cast.humanPersonaName.trim().isEmpty
      ? cast.names[human]
      : cast.humanPersonaName.trim();
  final humanRole = roles[human];
  final humanMafia = humanRole?.faction == Faction.mafia;
  final winner = events.whereType<GameEnded>().last.winner;
  final town = cast.townName;

  final exports = <PorchGameExport>[];
  for (var seat = 0; seat < cast.names.length; seat++) {
    if (seat == human) continue;
    final characterId = cast.fpaCharacterIds[seat];
    if (characterId == null || characterId.isEmpty) continue;
    final role = roles[seat];
    if (role == null) continue;

    final cards = _cardsForSeat(
      gameId: gameId,
      seat: seat,
      human: human,
      you: you,
      role: role,
      humanRole: humanRole,
      humanMafia: humanMafia,
      winner: winner,
      town: town,
      events: events,
      maxCards: maxCards,
    );
    if (cards.isEmpty) continue;
    exports.add(
      PorchGameExport(
        gameId: gameId,
        finishedAt: when,
        townName: town,
        difficulty: cast.difficulty,
        userPersonaId: userId,
        userPersonaName: you,
        characterId: characterId,
        characterName: cast.names[seat],
        cards: cards,
      ),
    );
  }
  return exports;
}

List<PorchMemoryCard> _cardsForSeat({
  required String gameId,
  required int seat,
  required int human,
  required String you,
  required Role role,
  required Role? humanRole,
  required bool humanMafia,
  required Faction? winner,
  required String? town,
  required List<GameEvent> events,
  required int maxCards,
}) {
  final bothMafia =
      role.faction == Faction.mafia && humanRole?.faction == Faction.mafia;
  final sameFaction =
      humanRole != null && role.faction == humanRole.faction;

  final candidates = <PorchMemoryCard>[
    _card(
      gameId,
      seat,
      PorchMemoryKind.playedTogether,
      PorchMemoryCategory.aboutUs,
      town == null || town.isEmpty
          ? '$you and I played a game of Mafia together.'
          : '$you and I played a game of Mafia together in $town.',
      'fond',
      PorchEmotionIntensity.moderate,
      0.35,
    ),
  ];

  if (sameFaction && winner != null) {
    if (winner == role.faction) {
      candidates.add(
        _card(
          gameId,
          seat,
          PorchMemoryKind.sharedVictory,
          PorchMemoryCategory.aboutUs,
          '$you and I won that Mafia game on the same side.',
          'proud',
          PorchEmotionIntensity.moderate,
          0.55,
        ),
      );
    } else {
      candidates.add(
        _card(
          gameId,
          seat,
          PorchMemoryKind.sharedLoss,
          PorchMemoryCategory.aboutUs,
          '$you and I lost that Mafia game together.',
          'disappointed',
          PorchEmotionIntensity.mild,
          0.45,
        ),
      );
    }
  }

  if (bothMafia) {
    candidates.add(
      _card(
        gameId,
        seat,
        PorchMemoryKind.mafiaPartner,
        PorchMemoryCategory.aboutUser,
        '$you was a mafia teammate of mine that night.',
        'trust',
        PorchEmotionIntensity.moderate,
        0.6,
      ),
    );
  }

  Map<int, int?>? lastVotes;
  var day = 0;
  for (final event in events) {
    switch (event) {
      case DayBegan(day: final d):
        day = d;
      case VotesRevealed(:final votes):
        lastVotes = votes;
      case Verdict(:final eliminated) when eliminated == seat:
        final votes = lastVotes ?? const {};
        final against = [
          for (final MapEntry(:key, :value) in votes.entries)
            if (value == seat) key,
        ];
        final humanVotedMe = votes[human] == seat;
        if (humanVotedMe) {
          if (bothMafia) {
            candidates.add(
              _card(
                gameId,
                seat,
                PorchMemoryKind.busedByUser,
                PorchMemoryCategory.aboutUser,
                '$you bussed me in our game of Mafia to save themselves.',
                'betrayed',
                PorchEmotionIntensity.strong,
                0.95,
                dayHint: day,
              ),
            );
          } else {
            candidates.add(
              _card(
                gameId,
                seat,
                PorchMemoryKind.votedOutByUser,
                PorchMemoryCategory.aboutUser,
                '$you voted to eliminate me in our game of Mafia.',
                'hurt',
                PorchEmotionIntensity.moderate,
                0.8,
                dayHint: day,
              ),
            );
          }
        } else if (against.length >= 2) {
          // Table piled on; human did not join the knife.
          candidates.add(
            _card(
              gameId,
              seat,
              PorchMemoryKind.defendedByUser,
              PorchMemoryCategory.aboutUser,
              '$you defended me when everyone else teamed up on me.',
              'grateful',
              PorchEmotionIntensity.strong,
              0.85,
              dayHint: day,
            ),
          );
        }
      case NominationCast(:final by, :final target)
          when by == human && target == seat:
        candidates.add(
          _card(
            gameId,
            seat,
            PorchMemoryKind.nominatedByUser,
            PorchMemoryCategory.aboutUser,
            '$you put me up on the stand in our game of Mafia.',
            'called-out',
            PorchEmotionIntensity.moderate,
            0.7,
            dayHint: day,
          ),
        );
      case ArgumentOpened(:final by, :final to)
          when by == human && to == seat:
        candidates.add(
          _card(
            gameId,
            seat,
            PorchMemoryKind.challengedByUser,
            PorchMemoryCategory.aboutUser,
            '$you challenged me mid-discussion during Mafia.',
            'pressured',
            PorchEmotionIntensity.mild,
            0.5,
            dayHint: day,
          ),
        );
      case DawnAnnounced(:final deaths) when deaths.contains(seat):
        if (humanMafia && role.faction != Faction.mafia) {
          candidates.add(
            _card(
              gameId,
              seat,
              PorchMemoryKind.killedByMafiaWithUser,
              PorchMemoryCategory.aboutUser,
              "$you's mafia side put me in the ground that game.",
              'fear',
              PorchEmotionIntensity.strong,
              0.9,
              dayHint: day,
            ),
          );
        }
      case AssassinDecided(:final assassin, :final target)
          when assassin == human && target == seat:
        candidates.add(
          _card(
            gameId,
            seat,
            PorchMemoryKind.assassinatedByUser,
            PorchMemoryCategory.aboutUser,
            "$you fired the assassin's bullet at me.",
            'shock',
            PorchEmotionIntensity.strong,
            0.92,
            dayHint: day,
          ),
        );
      case DoctorProtected(:final doctor, :final target)
          when doctor == human && target == seat:
        candidates.add(
          _card(
            gameId,
            seat,
            PorchMemoryKind.savedByUser,
            PorchMemoryCategory.aboutUser,
            '$you kept me alive as the doctor that night.',
            'safe',
            PorchEmotionIntensity.strong,
            0.88,
            dayHint: day,
          ),
        );
      case MafiaKillVoteCast(:final by, :final target)
          when bothMafia && by == human && target == seat:
        candidates.add(
          _card(
            gameId,
            seat,
            PorchMemoryKind.userVotedMyNightKill,
            PorchMemoryCategory.aboutUser,
            '$you marked me for the mafia kill — unforgettable.',
            'wary',
            PorchEmotionIntensity.moderate,
            0.75,
            dayHint: day,
          ),
        );
      default:
        break;
    }
  }

  // One card per kind (first / highest salience wins after sort).
  final byKind = <PorchMemoryKind, PorchMemoryCard>{};
  for (final c in candidates) {
    final prev = byKind[c.kind];
    if (prev == null || c.salience > prev.salience) byKind[c.kind] = c;
  }
  final ranked = byKind.values.toList()
    ..sort((a, b) => b.salience.compareTo(a.salience));
  // Always keep the frame if anything else exists.
  final frame = byKind[PorchMemoryKind.playedTogether];
  final spikes = [
    for (final c in ranked)
      if (c.kind != PorchMemoryKind.playedTogether) c,
  ];
  if (spikes.isEmpty) {
    // Shared game alone is still worth a single fond card.
    return frame == null ? const [] : [frame];
  }
  final kept = <PorchMemoryCard>[
    if (frame != null) frame,
    ...spikes.take(maxCards - (frame == null ? 0 : 1)),
  ];
  kept.sort((a, b) => b.salience.compareTo(a.salience));
  return kept;
}

PorchMemoryCard _card(
  String gameId,
  int seat,
  PorchMemoryKind kind,
  PorchMemoryCategory category,
  String content,
  String emotion,
  PorchEmotionIntensity intensity,
  double salience, {
  int? dayHint,
}) => PorchMemoryCard(
  id: '$gameId:$seat:${kind.name}',
  kind: kind,
  category: category,
  content: content,
  emotionLabel: emotion,
  emotionIntensity: intensity,
  salience: salience,
  dayHint: dayHint,
);
