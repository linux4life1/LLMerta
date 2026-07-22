import 'package:drift/drift.dart';

part 'database.g.dart';

enum ProviderKind { openaiCompat, anthropic, gemini }

/// API keys never live here — they go to the platform keychain, keyed by
/// the connection id (ARCHITECTURE.md §5).
class Connections extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get kind => textEnum<ProviderKind>()();
  TextColumn get baseUrl => text()();
  TextColumn get defaultModel => text().nullable()();
  DateTimeColumn get modelsFetchedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedModels extends Table {
  TextColumn get connectionId =>
      text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get modelId => text()();

  @override
  Set<Column<Object>> get primaryKey => {connectionId, modelId};
}

/// Imported / user-created personas only; the house library ships in code
/// (llm package). Name is the stable identity grudge memory keys on.
class CustomPersonas extends Table {
  TextColumn get name => text()();
  TextColumn get archetype => text()();
  TextColumn get style => text()();
  TextColumn get quirk => text()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get voiceSample => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class Prefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Connections, CachedModels, CustomPersonas, Prefs])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Stream<List<Connection>> watchConnections() => (select(
    connections,
  )..orderBy([(t) => OrderingTerm.asc(t.label)])).watch();

  Future<void> upsertConnection(ConnectionsCompanion connection) =>
      into(connections).insertOnConflictUpdate(connection);

  Future<void> deleteConnection(String id) =>
      (delete(connections)..where((t) => t.id.equals(id))).go();

  Future<List<String>> modelsFor(String connectionId) async {
    final rows =
        await (select(cachedModels)
              ..where((t) => t.connectionId.equals(connectionId))
              ..orderBy([(t) => OrderingTerm.asc(t.modelId)]))
            .get();
    return [for (final r in rows) r.modelId];
  }

  Stream<List<String>> watchModels(String connectionId) =>
      (select(cachedModels)
            ..where((t) => t.connectionId.equals(connectionId))
            ..orderBy([(t) => OrderingTerm.asc(t.modelId)]))
          .watch()
          .map((rows) => [for (final r in rows) r.modelId]);

  Future<void> replaceModels(
    String connectionId,
    List<String> models,
  ) => transaction(() async {
    await (delete(
      cachedModels,
    )..where((t) => t.connectionId.equals(connectionId))).go();
    await batch(
      (b) => b.insertAll(cachedModels, [
        for (final m in models)
          CachedModelsCompanion.insert(connectionId: connectionId, modelId: m),
      ]),
    );
    await (update(connections)..where((t) => t.id.equals(connectionId))).write(
      ConnectionsCompanion(modelsFetchedAt: Value(DateTime.now())),
    );
  });

  Stream<List<CustomPersona>> watchPersonas() => (select(
    customPersonas,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<void> upsertPersona(CustomPersonasCompanion persona) =>
      into(customPersonas).insertOnConflictUpdate(persona);

  Future<void> deletePersona(String name) =>
      (delete(customPersonas)..where((t) => t.name.equals(name))).go();

  Future<String?> pref(String key) async {
    final row = await (select(
      prefs,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setPref(String key, String value) => into(
    prefs,
  ).insertOnConflictUpdate(PrefsCompanion.insert(key: key, value: value));
}
