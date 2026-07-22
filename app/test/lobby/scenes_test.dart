import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/lobby/lobby.dart';

void main() {
  test('detectFpaBackgroundsDir finds the folder only when present', () async {
    final tmp = await Directory.systemTemp.createTemp('llmerta-home');
    addTearDown(() => tmp.delete(recursive: true));
    expect(detectFpaBackgroundsDir(homeOverride: tmp.path), isNull);

    final backgrounds = Directory(
      '${tmp.path}/Documents/FrontPorchAI/custom_backgrounds',
    )..createSync(recursive: true);
    expect(
      detectFpaBackgroundsDir(homeOverride: tmp.path)?.path,
      backgrounds.path,
    );
  });

  test('fpaBackgrounds lists only images, sorted', () async {
    final tmp = await Directory.systemTemp.createTemp('llmerta-bg');
    addTearDown(() => tmp.delete(recursive: true));
    File('${tmp.path}/b.jpg').writeAsBytesSync(const [1]);
    File('${tmp.path}/a.png').writeAsBytesSync(const [1]);
    File('${tmp.path}/notes.txt').writeAsStringSync('x');

    final c = ProviderContainer(
      overrides: [fpaBackgroundsDirProvider.overrideWith((_) => tmp)],
    );
    addTearDown(c.dispose);
    final scenes = c.read(fpaBackgroundsProvider);
    expect(scenes, hasLength(2));
    expect(scenes.first.path, endsWith('a.png'));
    expect(scenes.last.path, endsWith('b.jpg'));
  });

  test('scene decorations: gradients for built-ins, image for imports', () {
    for (final scene in builtInScenes) {
      expect(sceneDecoration(scene).gradient, isNotNull, reason: scene.label);
    }
    final imported = sceneDecoration(const FileScene('/tmp/dusk.png'));
    expect(imported.image, isNotNull);
  });

  test('scene identity and labels', () {
    expect(
      const BuiltInScene(BuiltInSceneId.harborFog),
      const BuiltInScene(BuiltInSceneId.harborFog),
    );
    expect(const FileScene('/a/b/dusk.png').label, 'dusk.png');
    expect(
      const BuiltInScene(BuiltInSceneId.classicFelt).label,
      'Classic Felt',
    );
  });
}
