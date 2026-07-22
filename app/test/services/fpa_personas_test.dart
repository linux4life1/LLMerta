import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  String tempDbPath() {
    final dir = Directory.systemTemp.createTempSync('fpa-personas');
    addTearDown(() => dir.deleteSync(recursive: true));
    return '${dir.path}/front_porch.db';
  }

  test('reads active-first personas and skips deleted rows', () {
    final path = tempDbPath();
    final db = sqlite3.open(path);
    db.execute('''
      CREATE TABLE personas (
        id TEXT PRIMARY KEY, title TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL DEFAULT 'User', persona TEXT NOT NULL DEFAULT '',
        avatar_path TEXT NULL, is_active INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0, deleted_at INTEGER NULL);
    ''');
    db
      ..execute(
        "INSERT INTO personas (id, title, name) VALUES ('a', 'Crime', 'Linus')",
      )
      ..execute(
        'INSERT INTO personas (id, title, name, is_active, avatar_path) '
        "VALUES ('b', 'Tech-Bro', 'Linus', 1, '/tmp/x.png')",
      )
      ..execute(
        'INSERT INTO personas (id, title, name, deleted_at) '
        "VALUES ('c', 'Gone', 'Linus', 5)",
      )
      ..dispose();

    final personas = readFpaPersonas(path);
    expect(personas.map((p) => p.title), ['Tech-Bro', 'Crime']);
    expect(personas.first.avatarPath, '/tmp/x.png');
    expect(personas.first.label, 'Linus — Tech-Bro');
    expect(const FpPersona(id: 'x', name: 'Solo', title: '').label, 'Solo');
  });

  test('provider yields nothing for a missing or foreign database', () {
    final missing = ProviderContainer(
      overrides: [fpaPersonaDbPathProvider.overrideWith((_) => null)],
    );
    addTearDown(missing.dispose);
    expect(missing.read(fpaPersonasProvider), isEmpty);

    final garbagePath = tempDbPath();
    File(garbagePath).writeAsStringSync('not a database at all');
    final garbage = ProviderContainer(
      overrides: [fpaPersonaDbPathProvider.overrideWith((_) => garbagePath)],
    );
    addTearDown(garbage.dispose);
    expect(garbage.read(fpaPersonasProvider), isEmpty);
  });

  test('default path requires the FPA install to exist', () {
    expect(defaultFpaPersonaDb(homeOverride: '/nonexistent-home'), isNull);
    expect(defaultFpaPersonaDb(homeOverride: ''), isNull);
  });
}
