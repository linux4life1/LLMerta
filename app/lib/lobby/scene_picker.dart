import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lobby_setup.dart';
import 'scenes.dart';

/// Filenames are not labels: strip extensions, de-snake, and fall back to
/// a numbered label when the name is digit soup (timestamped exports).
String prettySceneLabel(Scene scene, {String fallback = 'Imported scene'}) {
  if (scene is! FileScene) return scene.label;
  var name = scene.path.split(Platform.pathSeparator).last;
  name = name.replaceAll(
    RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false),
    '',
  );
  name = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  final digits = name.replaceAll(RegExp(r'[^0-9]'), '').length;
  if (name.isEmpty || digits > name.length ~/ 2) return fallback;
  return name;
}

class ScenePicker extends ConsumerWidget {
  const ScenePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      lobbySetupControllerProvider.select((s) => s.scene),
    );
    final fpaScenes = ref.watch(fpaBackgroundsProvider);
    final imported = switch (selected) {
      final FileScene f when !fpaScenes.contains(f) => f,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scene', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final scene in builtInScenes)
                _SceneThumb(scene: scene, selected: selected == scene),
              if (imported != null)
                _SceneThumb(scene: imported, selected: true),
              const _ImportSceneTile(),
            ],
          ),
        ),
        if (fpaScenes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'From Front Porch AI',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (i, scene) in fpaScenes.indexed)
                  _SceneThumb(
                    scene: scene,
                    selected: selected == scene,
                    labelOverride: prettySceneLabel(
                      scene,
                      fallback: 'Porch scene ${i + 1}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SceneThumb extends ConsumerWidget {
  const _SceneThumb({
    required this.scene,
    required this.selected,
    this.labelOverride,
  });

  final Scene scene;
  final bool selected;
  final String? labelOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () =>
            ref.read(lobbySetupControllerProvider.notifier).setScene(scene),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 56,
              decoration: sceneDecoration(scene).copyWith(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outline,
                  width: selected ? 2 : 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 92,
              child: Text(
                labelOverride ?? prettySceneLabel(scene),
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportSceneTile extends ConsumerWidget {
  const _ImportSceneTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final path = await ref.read(sceneFilePickerProvider)();
        if (path != null) {
          ref
              .read(lobbySetupControllerProvider.notifier)
              .setScene(FileScene(path));
        }
      },
      child: Column(
        children: [
          Container(
            width: 92,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: scheme.outline, width: 0.5),
            ),
            child: const Icon(Icons.add_photo_alternate_outlined),
          ),
          const SizedBox(height: 4),
          Text('Import…', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
