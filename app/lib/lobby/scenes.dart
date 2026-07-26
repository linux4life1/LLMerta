import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:llm/llm.dart' show resolveFpaInstall;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scenes.g.dart';

/// The table backdrop (UI_UX.md §2 scene system). Built-ins are painted
/// gradients so the app ships asset-free; imported scenes are user images.
sealed class Scene {
  const Scene();

  String get label;
}

enum BuiltInSceneId {
  midnightStudy('Midnight Study'),
  villaCortile('Villa Cortile'),
  neonDistrict('Neon District'),
  harborFog('Harbor Fog'),
  classicFelt('Classic Felt');

  const BuiltInSceneId(this.label);

  final String label;
}

class BuiltInScene extends Scene {
  const BuiltInScene(this.id);

  final BuiltInSceneId id;

  @override
  String get label => id.label;

  @override
  bool operator ==(Object other) => other is BuiltInScene && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class FileScene extends Scene {
  const FileScene(this.path);

  final String path;

  @override
  String get label => path.split(Platform.pathSeparator).last;

  @override
  bool operator ==(Object other) => other is FileScene && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

final builtInScenes = [
  for (final id in BuiltInSceneId.values) BuiltInScene(id),
];

const _sceneGradients = {
  // Warm-porch: candlelit wood, not purple (maintainer call 2026-07-22).
  BuiltInSceneId.midnightStudy: (
    [Color(0xFF33271A), Color(0xFF171310), Color(0xFF3A2A18)],
    Alignment.topLeft,
  ),
  BuiltInSceneId.villaCortile: (
    [Color(0xFF5C3A2E), Color(0xFF33241E), Color(0xFF191310)],
    Alignment.topCenter,
  ),
  BuiltInSceneId.neonDistrict: (
    [Color(0xFF10203A), Color(0xFF1A0F2E), Color(0xFF3A1030)],
    Alignment.topRight,
  ),
  BuiltInSceneId.harborFog: (
    [Color(0xFF2A3438), Color(0xFF1A2226), Color(0xFF0E1214)],
    Alignment.topCenter,
  ),
  BuiltInSceneId.classicFelt: (
    [Color(0xFF1E4D33), Color(0xFF123322), Color(0xFF0A1F15)],
    Alignment.center,
  ),
};

BoxDecoration sceneDecoration(Scene scene) => switch (scene) {
  BuiltInScene(:final id) => BoxDecoration(
    gradient: LinearGradient(
      begin: _sceneGradients[id]!.$2,
      end: Alignment.bottomCenter,
      colors: _sceneGradients[id]!.$1,
    ),
  ),
  FileScene(:final path) => BoxDecoration(
    color: const Color(0xFF0E0A14),
    image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
  ),
};

Map<String, Object?> sceneToJson(Scene scene) => switch (scene) {
  BuiltInScene(:final id) => {'builtIn': id.name},
  FileScene(:final path) => {'file': path},
};

Scene sceneFromJson(Map<String, Object?> json) => switch (json) {
  {'builtIn': final String name} => BuiltInScene(
    BuiltInSceneId.values.byName(name),
  ),
  {'file': final String path} => FileScene(path),
  _ => const BuiltInScene(BuiltInSceneId.midnightStudy),
};

/// Bound FPA install's custom backgrounds (Stable or Rawhide Beta).
Directory? detectFpaBackgroundsDir({String? homeOverride}) {
  final install = resolveFpaInstall(homeOverride: homeOverride);
  if (install == null) return null;
  final dir = install.customBackgroundsDir;
  return dir.existsSync() ? dir : null;
}

@Riverpod(keepAlive: true)
Directory? fpaBackgroundsDir(Ref ref) => detectFpaBackgroundsDir();

const _imageExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

@riverpod
List<FileScene> fpaBackgrounds(Ref ref) {
  final dir = ref.watch(fpaBackgroundsDirProvider);
  if (dir == null) return const [];
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                _imageExtensions.any((e) => f.path.toLowerCase().endsWith(e)),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [for (final f in files) FileScene(f.path)];
}

/// Seam for tests: the real picker is a platform channel.
@Riverpod(keepAlive: true)
Future<String?> Function() sceneFilePicker(Ref ref) => _pickSceneFile;

Future<String?> _pickSceneFile() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Scene image',
        extensions: ['png', 'jpg', 'jpeg', 'webp'],
      ),
    ],
  );
  return file?.path;
}
