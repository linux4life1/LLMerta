import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

const names = ['Joseph', 'Alma', 'Edda', 'Boris', 'Clara', 'Dmitri', 'Felix'];

/// Human Joseph (0) + Alma (1) are mafia; Edda buses via vote with Joseph.
final busAndDefendGame = <GameEvent>[
  const GameStarted(seats: 7),
  const RolesDealt({
    0: Role.mafioso,
    1: Role.mafioso,
    2: Role.doctor,
    3: Role.villager,
    4: Role.sheriff,
    5: Role.assassin,
    6: Role.villager,
  }),
  const DayBegan(1),
  const NominationCast(by: 0, target: 3, statement: 'Boris is sus'),
  const ArgumentOpened(by: 0, to: 2, text: 'Explain yourself'),
  const VotesRevealed({0: 1, 2: 1, 3: 1, 4: 1, 5: null, 6: 1, 1: 3}),
  const Verdict(eliminated: 1, revealedRole: Role.mafioso),
  const AssassinDecided(assassin: 5, target: 6),
  const DoctorProtected(doctor: 2, target: 4),
  const DawnAnnounced(deaths: [6], revealedRoles: {}),
  const GameEnded(winner: Faction.town),
];

PorchCast cast({
  String? humanId = 'persona-joseph',
  Map<int, String?>? ids,
}) => PorchCast(
  humanSeat: 0,
  names: names,
  humanPersonaId: humanId,
  humanPersonaName: 'Joseph',
  fpaCharacterIds:
      ids ??
      const {
        1: 'alma_card',
        2: 'edda_card',
        // Boris house — no FPA id
        3: null,
      },
  townName: 'Brasshollow',
  difficulty: 'standard',
);

void main() {
  test('no export without human persona id', () {
    final out = extractPorchMemories(
      gameId: 'g1',
      events: busAndDefendGame,
      cast: cast(humanId: null),
    );
    expect(out, isEmpty);
  });

  test('no export without finished game / roles', () {
    expect(
      extractPorchMemories(
        gameId: 'g1',
        events: const [GameStarted(seats: 7)],
        cast: cast(),
      ),
      isEmpty,
    );
  });

  test('skips seats without fpaCharacterId', () {
    final out = extractPorchMemories(
      gameId: 'g1',
      events: busAndDefendGame,
      cast: cast(),
    );
    final ids = [for (final e in out) e.characterId];
    expect(ids, containsAll(['alma_card', 'edda_card']));
    expect(ids, isNot(contains(null)));
    expect(out.any((e) => e.characterName == 'Boris'), isFalse);
  });

  test('bus yields strong betrayal + fond frame for Alma', () {
    final out = extractPorchMemories(
      gameId: 'g1',
      events: busAndDefendGame,
      cast: cast(),
    );
    final alma = out.singleWhere((e) => e.characterId == 'alma_card');
    expect(alma.userPersonaId, 'persona-joseph');
    expect(alma.userPersonaName, 'Joseph');
    expect(alma.townName, 'Brasshollow');
    final kinds = {for (final c in alma.cards) c.kind};
    expect(kinds, contains(PorchMemoryKind.playedTogether));
    expect(kinds, contains(PorchMemoryKind.busedByUser));
    expect(kinds, contains(PorchMemoryKind.mafiaPartner));
    final bus = alma.cards.singleWhere(
      (c) => c.kind == PorchMemoryKind.busedByUser,
    );
    expect(bus.content, contains('Joseph bussed me'));
    expect(bus.content, contains('Mafia partner'));
    expect(bus.emotionIntensity, PorchEmotionIntensity.strong);
    expect(bus.category, PorchMemoryCategory.aboutUser);
    final frame = alma.cards.singleWhere(
      (c) => c.kind == PorchMemoryKind.playedTogether,
    );
    expect(frame.content, contains('Mafia'));
    expect(frame.content, contains('Brasshollow'));
  });

  test('nomination and challenge cards for targets', () {
    final out = extractPorchMemories(
      gameId: 'g1',
      events: busAndDefendGame,
      cast: cast(
        ids: const {
          2: 'edda_card',
          3: 'boris_card',
        },
      ),
    );
    final boris = out.singleWhere((e) => e.characterId == 'boris_card');
    expect(
      boris.cards.any((c) => c.kind == PorchMemoryKind.nominatedByUser),
      isTrue,
    );
    final edda = out.singleWhere((e) => e.characterId == 'edda_card');
    expect(
      edda.cards.any((c) => c.kind == PorchMemoryKind.challengedByUser),
      isTrue,
    );
  });

  test('doctor save and assassin shot', () {
    final events = <GameEvent>[
      const GameStarted(seats: 7),
      const RolesDealt({
        0: Role.doctor,
        1: Role.villager,
        2: Role.mafioso,
        3: Role.mafioso,
        4: Role.sheriff,
        5: Role.assassin,
        6: Role.villager,
      }),
      const DayBegan(1),
      const DoctorProtected(doctor: 0, target: 1),
      const AssassinDecided(assassin: 0, target: 2), // human not assassin
      const DawnAnnounced(deaths: [], revealedRoles: {}),
      const GameEnded(winner: Faction.town),
    ];
    // Human doctor saves Alma; separate game human assassin shoots Edda.
    final saveOut = extractPorchMemories(
      gameId: 'save',
      events: events,
      cast: cast(ids: const {1: 'alma_card'}),
    );
    expect(
      saveOut.single.cards.any((c) => c.kind == PorchMemoryKind.savedByUser),
      isTrue,
    );

    final shoot = <GameEvent>[
      const GameStarted(seats: 7),
      const RolesDealt({
        0: Role.assassin,
        1: Role.villager,
        2: Role.mafioso,
        3: Role.mafioso,
        4: Role.sheriff,
        5: Role.doctor,
        6: Role.villager,
      }),
      const AssassinDecided(assassin: 0, target: 1),
      const GameEnded(winner: Faction.mafia),
    ];
    final shootOut = extractPorchMemories(
      gameId: 'shoot',
      events: shoot,
      cast: cast(ids: const {1: 'alma_card'}),
    );
    expect(
      shootOut.single.cards.any(
        (c) => c.kind == PorchMemoryKind.assassinatedByUser,
      ),
      isTrue,
    );
  });

  test('defended when table piles on and human abstains', () {
    final events = <GameEvent>[
      const GameStarted(seats: 7),
      const RolesDealt({
        0: Role.villager,
        1: Role.villager,
        2: Role.mafioso,
        3: Role.mafioso,
        4: Role.sheriff,
        5: Role.doctor,
        6: Role.assassin,
      }),
      const DayBegan(1),
      const VotesRevealed({0: null, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 1: 2}),
      const Verdict(eliminated: 1, revealedRole: Role.villager),
      const GameEnded(winner: Faction.mafia),
    ];
    final out = extractPorchMemories(
      gameId: 'def',
      events: events,
      cast: cast(ids: const {1: 'alma_card'}),
    );
    final kinds = {for (final c in out.single.cards) c.kind};
    expect(kinds, contains(PorchMemoryKind.defendedByUser));
    expect(kinds, contains(PorchMemoryKind.playedTogether));
  });

  test('caps cards and keeps mixed valence', () {
    final out = extractPorchMemories(
      gameId: 'g1',
      events: busAndDefendGame,
      cast: cast(ids: const {1: 'alma_card'}),
      maxCards: 3,
    );
    expect(out.single.cards, hasLength(lessThanOrEqualTo(3)));
    final kinds = {for (final c in out.single.cards) c.kind};
    expect(kinds, contains(PorchMemoryKind.playedTogether));
  });

  test('porchCastEligible requires FPA persona and FPA characters', () {
    expect(porchCastEligible(cast()), isTrue);
    expect(porchCastEligible(cast(humanId: null)), isFalse);
    expect(porchCastEligible(cast(humanId: '')), isFalse);
    expect(
      porchCastEligible(cast(ids: const {1: null, 2: null, 3: null})),
      isFalse,
    );
    expect(porchCastEligible(cast(ids: const {})), isFalse);
  });

  test('no extract / no write for house-only or free-typed human', () {
    expect(
      extractPorchMemories(
        gameId: 'g1',
        events: busAndDefendGame,
        cast: cast(humanId: null),
      ),
      isEmpty,
    );
    expect(
      extractPorchMemories(
        gameId: 'g1',
        events: busAndDefendGame,
        cast: cast(ids: const {1: null, 2: null}),
      ),
      isEmpty,
    );
    final dir = Directory.systemTemp.createTempSync('porch-empty');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(writePorchBundle(dir, const []), isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('JSON round-trip and multi-game bundles accumulate', () {
    final out = extractPorchMemories(
      gameId: 'g1',
      events: busAndDefendGame,
      cast: cast(),
      finishedAt: DateTime.utc(2026, 7, 25),
    );
    final encoded = out.first.toJson();
    final restored = PorchGameExport.fromJson(encoded);
    expect(restored.gameId, 'g1');
    expect(restored.cards.length, out.first.cards.length);
    expect(restored.cards.first.content, out.first.cards.first.content);

    final dir = Directory.systemTemp.createTempSync('porch');
    addTearDown(() => dir.deleteSync(recursive: true));
    final n1 = writePorchBundle(dir, out);
    expect(n1, greaterThan(0));
    final game2 = extractPorchMemories(
      gameId: 'g2',
      events: busAndDefendGame,
      cast: cast(),
      finishedAt: DateTime.utc(2026, 7, 26),
    );
    final n2 = writePorchBundle(dir, game2);
    expect(n2, greaterThan(0));
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    expect(files.map((f) => f.uri.pathSegments.last), ['g1.json', 'g2.json']);
    final parsed =
        jsonDecode(files.first.readAsStringSync()) as Map<String, dynamic>;
    expect(parsed['schemaVersion'], porchMemoriesSchemaVersion);
    expect(parsed['userPersonaId'], 'persona-joseph');
    expect(parsed['gameId'], 'g1');
    expect(parsed['characters'], isA<List>());
    expect((parsed['characters'] as List), isNotEmpty);
    // Same gameId re-write is idempotent — still one file for g1.
    writePorchBundle(dir, out);
    expect(
      dir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last),
      unorderedEquals(['g1.json', 'g2.json']),
    );
  });

  test('detectPorchMemoriesDir finds FPA KoboldManager tree', () {
    final home = Directory.systemTemp.createTempSync('fakehome');
    addTearDown(() => home.deleteSync(recursive: true));
    expect(detectPorchMemoriesDir(homeOverride: home.path), isNull);
    Directory(
      '${home.path}/Documents/FrontPorchAI/KoboldManager',
    ).createSync(recursive: true);
    final dir = detectPorchMemoriesDir(homeOverride: home.path)!;
    expect(dir.path, endsWith('llmerta_porch_memories'));
  });

  test('card import stamps fpaCharacterId from filename', () {
    final dir = Directory.systemTemp.createTempSync('cards');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/Seraphina_v2.json').writeAsStringSync(
      jsonEncode({
        'name': 'Seraphina Nightwhisper',
        'description': 'herbalist',
      }),
    );
    final p = personaFromCardFile(File('${dir.path}/Seraphina_v2.json'))!;
    expect(p.fpaCharacterId, 'Seraphina_v2');
  });
}
