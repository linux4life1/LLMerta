import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'llmerta.db')),
      );
    }),
  );
  ref.onDispose(db.close);
  return db;
}
