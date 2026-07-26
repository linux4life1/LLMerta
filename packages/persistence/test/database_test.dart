import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:persistence/persistence.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ConnectionsCompanion omlx({String label = 'oMLX'}) =>
      ConnectionsCompanion.insert(
        id: 'omlx',
        label: label,
        kind: ProviderKind.openaiCompat,
        baseUrl: 'http://127.0.0.1:8000/v1',
      );

  test('connection upsert, watch ordering, and delete', () async {
    await db.upsertConnection(omlx());
    await db.upsertConnection(
      ConnectionsCompanion.insert(
        id: 'or',
        label: 'OpenRouter',
        kind: ProviderKind.openaiCompat,
        baseUrl: 'https://openrouter.ai/api/v1',
      ),
    );
    var rows = await db.watchConnections().first;
    expect([for (final r in rows) r.label], ['OpenRouter', 'oMLX']);

    await db.upsertConnection(omlx(label: 'Local oMLX'));
    rows = await db.watchConnections().first;
    expect(rows, hasLength(2));
    expect(rows.first.label, 'Local oMLX');

    await db.deleteConnection('omlx');
    rows = await db.watchConnections().first;
    expect([for (final r in rows) r.id], ['or']);
  });

  test(
    'model cache replace stamps fetch time and cascades on delete',
    () async {
      await db.upsertConnection(omlx());
      await db.replaceModels('omlx', ['glm-5', 'qwen3.6-heretic']);
      expect(await db.modelsFor('omlx'), ['glm-5', 'qwen3.6-heretic']);

      await db.replaceModels('omlx', ['glm-5']);
      expect(await db.modelsFor('omlx'), ['glm-5']);
      expect(await db.watchModels('omlx').first, ['glm-5']);

      final conn = (await db.watchConnections().first).single;
      expect(conn.modelsFetchedAt, isNotNull);

      await db.deleteConnection('omlx');
      expect(await db.modelsFor('omlx'), isEmpty);
    },
  );

  test('custom personas upsert, watch, delete', () async {
    await db.upsertPersona(
      CustomPersonasCompanion.insert(
        name: 'Edda',
        archetype: 'retired judge',
        style: 'clipped, precise',
        quirk: 'quotes case law',
        avatarPath: const Value('/tmp/edda.png'),
        voiceSample: const Value('Objection noted.'),
        fpaCharacterId: const Value('edda_card'),
      ),
    );
    await db.upsertPersona(
      CustomPersonasCompanion.insert(
        name: 'Alma',
        archetype: 'baker',
        style: 'warm',
        quirk: 'bribes with pastries',
      ),
    );
    var personas = await db.watchPersonas().first;
    expect([for (final p in personas) p.name], ['Alma', 'Edda']);
    expect(personas.last.avatarPath, '/tmp/edda.png');
    expect(personas.last.fpaCharacterId, 'edda_card');
    expect(personas.first.fpaCharacterId, isNull);

    await db.upsertPersona(
      CustomPersonasCompanion.insert(
        name: 'Alma',
        archetype: 'master baker',
        style: 'warm',
        quirk: 'bribes with pastries',
      ),
    );
    personas = await db.watchPersonas().first;
    expect(personas, hasLength(2));
    expect(personas.first.archetype, 'master baker');

    await db.deletePersona('Alma');
    expect(await db.watchPersonas().first, hasLength(1));
  });

  test('game saves: upsert, ordering, lookup, delete', () async {
    GamesCompanion save(String id, {bool finished = false, int minute = 0}) =>
        GamesCompanion.insert(
          id: id,
          townName: 'Brasshollow',
          savedAt: DateTime(2026, 7, 22, 3, minute),
          finished: Value(finished),
          humanSeat: 0,
          rngSeed: 42,
          difficulty: 'standard',
          namesJson: '["A","B"]',
          badgesJson: '{"1":"glm-5"}',
          configJson: '{"seats":7}',
          eventsJson: '[]',
        );
    await db.upsertGame(save('g1', minute: 1));
    await db.upsertGame(save('g2', finished: true, minute: 2));

    var rows = await db.watchGames().first;
    expect([for (final g in rows) g.id], ['g2', 'g1']);
    expect(rows.first.finished, isTrue);

    await db.upsertGame(
      save('g1', minute: 3).copyWith(notes: const Value('watch Edda')),
    );
    rows = await db.watchGames().first;
    expect(rows.first.id, 'g1');
    expect(rows.first.notes, 'watch Edda');

    expect((await db.gameById('g2'))?.winner, isNull);
    expect(await db.gameById('ghost'), isNull);

    await db.deleteGame('g1');
    expect(await db.watchGames().first, hasLength(1));
  });

  test('prefs are a last-write-wins KV store', () async {
    expect(await db.pref('townName'), isNull);
    await db.setPref('townName', 'Brasshollow');
    await db.setPref('townName', 'Veilport');
    expect(await db.pref('townName'), 'Veilport');
  });
}
