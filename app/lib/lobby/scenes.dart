import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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
  BuiltInSceneId.midnightStudy: (
    [Color(0xFF241A33), Color(0xFF0E0A14), Color(0xFF3A2A18)],
    Alignment.topLeft,
  ),
  BuiltInSceneId.villaCortile: (
    [Color(0xFF5C3A2E), Color(0xFF2E1F2E), Color(0xFF141019)],
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

Directory? detectFpaBackgroundsDir({String? homeOverride}) {
  final home = homeOverride ?? Platform.environment['HOME'];
  if (home == null || home.isEmpty) return null;
  final dir = Directory(
    '$home${Platform.pathSeparator}Documents'
    '${Platform.pathSeparator}FrontPorchAI'
    '${Platform.pathSeparator}custom_backgrounds',
  );
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
