import 'dart:io';

import 'package:llm/llm.dart' show resolveFpaInstall;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite3/sqlite3.dart';

part 'fpa_personas.g.dart';

/// A persona the user built for themself in Front Porch AI — the human
/// seat's identity source (UI_UX.md §1). Only name/title/avatar are read;
/// the persona description text never enters this process.
class FpPersona {
  const FpPersona({
    required this.id,
    required this.name,
    required this.title,
    this.avatarPath,
  });

  final String id;
  final String name;
  final String title;
  final String? avatarPath;

  String get label => title.isEmpty ? name : '$name — $title';

  @override
  bool operator ==(Object other) => other is FpPersona && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Persona DB for the **bound** FPA install ([resolveFpaInstall]) — Stable or
/// Rawhide Beta, never a merge of both.
String? defaultFpaPersonaDb({String? homeOverride}) {
  final install = resolveFpaInstall(homeOverride: homeOverride);
  if (install == null) return null;
  final db = install.personaDb;
  return db.existsSync() ? db.path : null;
}

List<FpPersona> readFpaPersonas(String dbPath) {
  final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  try {
    final rows = db.select(
      'SELECT id, name, title, avatar_path FROM personas '
      'WHERE deleted_at IS NULL ORDER BY is_active DESC, title',
    );
    return [
      for (final row in rows)
        FpPersona(
          id: row['id'] as String,
          name: row['name'] as String,
          title: row['title'] as String? ?? '',
          avatarPath: row['avatar_path'] as String?,
        ),
    ];
  } finally {
    db.dispose();
  }
}

@Riverpod(keepAlive: true)
String? fpaPersonaDbPath(Ref ref) => defaultFpaPersonaDb();

@Riverpod(keepAlive: true)
List<FpPersona> fpaPersonas(Ref ref) {
  final path = ref.watch(fpaPersonaDbPathProvider);
  if (path == null) return const [];
  try {
    return readFpaPersonas(path);
  } catch (_) {
    // Foreign database: any schema surprise means "no personas".
    return const [];
  }
}
