import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistence/persistence.dart';

import '../services/services.dart';
import 'connection_edit_dialog.dart';
import 'connection_providers.dart';

const kindLabels = {
  ProviderKind.openaiCompat: 'OpenAI-compatible',
  ProviderKind.anthropic: 'Anthropic',
  ProviderKind.gemini: 'Gemini',
};

class ConnectionsSection extends ConsumerWidget {
  const ConnectionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(connectionRowsProvider);
    return switch (connections) {
      AsyncValue(:final value?) when value.isEmpty => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No provider connections yet.'),
            const SizedBox(height: 4),
            Text(
              'Add your local server (oMLX, LM Studio, Ollama…) or a hosted API.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addConnection(context),
              icon: const Icon(Icons.add),
              label: const Text('Add connection'),
            ),
          ],
        ),
      ),
      AsyncValue(:final value?) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Provider connections',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _addConnection(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add connection'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final connection in value)
                    _ConnectionCard(connection: connection),
                ],
              ),
            ),
          ],
        ),
      ),
      AsyncValue(hasError: true) => const Center(
        child: Text('Could not load connections.'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  void _addConnection(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const ConnectionEditDialog(),
  );
}

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard({required this.connection});

  final Connection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models =
        ref.watch(connectionModelsProvider(connection.id)).value ?? const [];
    return Card(
      child: ListTile(
        title: Text(connection.label),
        subtitle: Text(
          '${kindLabels[connection.kind]} · ${connection.baseUrl}'
          '${models.isEmpty ? '' : ' · ${models.length} models cached'}',
        ),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TestButton(connectionId: connection.id),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ConnectionEditDialog(existing: connection),
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${connection.label}?'),
        content: const Text(
          'Removes the connection, its cached models, and its stored key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(appDatabaseProvider).deleteConnection(connection.id);
    await ref.read(apiKeyStoreProvider).delete(connection.id);
  }
}

class _TestButton extends ConsumerWidget {
  const _TestButton({required this.connectionId});

  final String connectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final test = ref.watch(connectionTestProvider(connectionId));
    void run() => ref.read(connectionTestProvider(connectionId).notifier).run();
    return switch (test) {
      null => OutlinedButton(onPressed: run, child: const Text('Test')),
      AsyncValue(isLoading: true) => const OutlinedButton(
        onPressed: null,
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      AsyncValue(:final value?) => OutlinedButton.icon(
        onPressed: run,
        icon: const Icon(Icons.check, size: 16),
        label: Text('$value models'),
      ),
      AsyncValue(:final error) => Tooltip(
        message: '$error',
        child: OutlinedButton.icon(
          onPressed: run,
          icon: const Icon(Icons.error_outline, size: 16),
          label: const Text('Failed'),
        ),
      ),
    };
  }
}
