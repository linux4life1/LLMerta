import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:test/test.dart';

const names = ['Alma', 'Boris', 'Clara', 'Dmitri', 'Edda', 'Felix', 'Greta'];

const roles = {
  0: Role.mafioso,
  1: Role.doctor,
  2: Role.villager,
  3: Role.assassin,
  4: Role.mafioso,
  5: Role.sheriff,
  6: Role.villager,
};

/// A finished game where Edda buses her teammate Alma, the mafia kill
/// Clara at night, and Dmitri shoots Felix.
final busGame = <GameEvent>[
  const GameStarted(seats: 7),
  const RolesDealt(roles),
  const VotesRevealed({1: 0, 2: 0, 4: 0, 5: null, 0: 1}),
  const Verdict(eliminated: 0, revealedRole: Role.mafioso),
  const AssassinDecided(assassin: 3, target: 5),
  const DawnAnnounced(deaths: [2, 5], revealedRoles: {}),
  const GameEnded(winner: Faction.town),
];

void main() {
  personaLibraryTests();
  test('records the bus: teammate voting for your elimination', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    final alma = book.memoriesOf('Alma').single;
    expect(alma, contains('You were Alma, the mafioso'));
    expect(alma, contains('your side lost'));
    expect(alma, contains('Boris, Clara, Edda voted to eliminate you'));
    expect(alma, contains('teammate Edda bused you'));
  });

  test('night victims remember who the mafia were', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    expect(
      book.memoriesOf('Clara').single,
      contains('The mafia (Alma, Edda) killed you in the night'),
    );
  });

  test('assassin targets remember the shooter', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    expect(
      book.memoriesOf('Felix').single,
      contains('Dmitri fired the assassin\'s bullet at you'),
    );
  });

  test('every persona learns the full roster (post-game reveal)', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    for (final name in names) {
      expect(book.memoriesOf(name).single, contains('Roles were:'));
      expect(book.memoriesOf(name).single, contains('Edda=mafioso'));
    }
  });

  test('JSON round-trip preserves memories', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    final restored = GrudgeBook.fromJson(book.toJson());
    expect(restored.memoriesOf('Alma'), book.memoriesOf('Alma'));
  });

  test('keeps only the last three games per persona', () {
    final book = GrudgeBook();
    for (var i = 0; i < 5; i++) {
      book.recordGame(busGame, names);
    }
    expect(book.memoriesOf('Alma'), hasLength(GrudgeBook.keepGames));
  });

  test('prompt block frames memories as past-game public knowledge', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    final block = book.promptBlockFor('Alma')!;
    expect(block, contains('MEMORIES OF PAST GAMES'));
    expect(block, contains('fresh secrets'));
    expect(block, contains('grudges'));
    expect(book.promptBlockFor('Zorblax'), isNull);
  });

  test('memories reach the system prompt only for their seat', () {
    final book = GrudgeBook()..recordGame(busGame, names);
    final builder = AgentPromptBuilder(
      names: names,
      pastMemories: {0: book.promptBlockFor('Alma')!},
    );
    final ctx0 = DecisionContext(
      seat: 0,
      role: Role.villager,
      day: 1,
      visibleEvents: const [GameStarted(seats: 7)],
      livingSeats: const [0, 1, 2, 3, 4, 5, 6],
    );
    expect(builder.system(ctx0), contains('bused you'));
    final ctx1 = DecisionContext(
      seat: 1,
      role: Role.villager,
      day: 1,
      visibleEvents: const [GameStarted(seats: 7)],
      livingSeats: const [0, 1, 2, 3, 4, 5, 6],
    );
    expect(builder.system(ctx1), isNot(contains('MEMORIES')));
  });
}

void personaLibraryTests() {
  test('persona library has 30 unique names for stable grudge identity', () {
    final all = personaLibrary.map((p) => p.name).toList();
    expect(all, hasLength(30));
    expect(all.toSet(), hasLength(30));
    expect(all.take(7), names);
  });
}
