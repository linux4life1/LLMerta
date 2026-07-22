import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_selector/file_selector.dart';
import 'package:llm/llm.dart';
import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/services.dart';

part 'persona_providers.g.dart';

@riverpod
Stream<List<CustomPersona>> personaRows(Ref ref) =>
    ref.watch(appDatabaseProvider).watchPersonas();

@Riverpod(keepAlive: true)
Directory? fpaCharacterDir(Ref ref) => detectFpaCharacterDir();

/// Seam for tests: the real picker is a platform channel.
@Riverpod(keepAlive: true)
Future<String?> Function() cardFilePicker(Ref ref) => _pickCardFile;

Future<String?> _pickCardFile() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Character card', extensions: ['png', 'json']),
    ],
  );
  return file?.path;
}

@riverpod
class PersonaImporter extends _$PersonaImporter {
  @override
  AsyncValue<int>? build() => null;

  Future<void> importDirectory(Directory dir) => _guard(() async {
    final personas = personasFromCardDir(dir);
    await _save(personas);
    return personas.length;
  });

  /// Returns the imported persona's name so callers (e.g. the lobby's
  /// human-identity card) can select it immediately.
  Future<String?> importPickedFile() async {
    String? imported;
    await _guard(() async {
      final path = await ref.read(cardFilePickerProvider)();
      if (path == null) return null;
      final persona = personaFromCardFile(File(path));
      if (persona == null) {
        throw const FormatException('Not a v1/v2 character card');
      }
      await _save([persona]);
      imported = persona.name;
      return 1;
    });
    return imported;
  }

  Future<void> _guard(Future<int?> Function() import) async {
    state = const AsyncValue.loading();
    try {
      final count = await import();
      state = count == null ? null : AsyncValue.data(count);
    } on Exception catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> _save(List<Persona> personas) async {
    final db = ref.read(appDatabaseProvider);
    for (final persona in personas) {
      await db.upsertPersona(
        CustomPersonasCompanion.insert(
          name: persona.name,
          archetype: persona.archetype,
          style: persona.style,
          quirk: persona.quirk,
          avatarPath: Value(persona.avatarPath),
          voiceSample: Value(persona.voiceSample),
        ),
      );
    }
  }
}
