import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistence/persistence.dart';

import '../services/services.dart';
import 'persona_edit_dialog.dart';
import 'persona_pool.dart';
import 'persona_providers.dart';

class PersonasSection extends ConsumerWidget {
  const PersonasSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imported = ref.watch(personaRowsProvider).value ?? const [];
    final house = ref.watch(personaPoolProvider);
    final fpaDir = ref.watch(fpaCharacterDirProvider);
    final importState = ref.watch(personaImporterProvider);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Personas', style: text.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (fpaDir != null)
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(personaImporterProvider.notifier)
                    .importDirectory(fpaDir),
                icon: const Icon(Icons.download),
                label: const Text('Import from Front Porch AI'),
              ),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(personaImporterProvider.notifier).importPickedFile(),
              icon: const Icon(Icons.file_open_outlined),
              label: const Text('Import card…'),
            ),
            OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const PersonaEditDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New persona'),
            ),
          ],
        ),
        if (importState != null) ...[
          const SizedBox(height: 8),
          switch (importState) {
            AsyncValue(isLoading: true) => const LinearProgressIndicator(),
            AsyncValue(:final value?) => Text('Imported $value personas.'),
            AsyncValue(:final error) => Text(
              'Import failed: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          },
        ],
        if (imported.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Imported & custom', style: text.titleSmall),
          for (final persona in imported)
            _ImportedPersonaTile(persona: persona),
        ],
        const SizedBox(height: 16),
        Text('House library (${house.length})', style: text.titleSmall),
        for (final persona in house)
          ListTile(
            leading: _Avatar(name: persona.name),
            title: Text(persona.name),
            subtitle: Text(persona.archetype),
            trailing: const Chip(label: Text('House')),
          ),
      ],
    );
  }
}

class _ImportedPersonaTile extends ConsumerWidget {
  const _ImportedPersonaTile({required this.persona});

  final CustomPersona persona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: _Avatar(name: persona.name, avatarPath: persona.avatarPath),
      title: Text(persona.name),
      subtitle: Text(persona.archetype),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PersonaEditDialog(existing: persona),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                ref.read(appDatabaseProvider).deletePersona(persona.name),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarPath});

  final String name;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final path = avatarPath;
    if (path != null && File(path).existsSync()) {
      return CircleAvatar(backgroundImage: FileImage(File(path)));
    }
    return CircleAvatar(child: Text(name.isEmpty ? '?' : name[0]));
  }
}
