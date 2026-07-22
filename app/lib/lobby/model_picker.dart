import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';
import '../settings/settings.dart';

/// Opens a searchable dialog instead of a 300-item dropdown. The list is
/// whatever `/v1/models` returned for the connection, so single-model
/// backends (plain koboldcpp, llama.cpp) constrain themselves.
class ModelPickerField extends ConsumerWidget {
  const ModelPickerField({
    required this.connectionId,
    required this.model,
    required this.onPicked,
    super.key,
  });

  final String? connectionId;
  final String? model;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = connectionId != null;
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await showDialog<String>(
                context: context,
                builder: (_) => ModelPickerDialog(connectionId: connectionId!),
              );
              if (picked != null) onPicked(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Model',
          isDense: true,
          enabled: enabled,
          suffixIcon: const Icon(Icons.search, size: 18),
        ),
        isEmpty: model == null,
        child: model == null
            ? null
            : Text(model!, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class ModelPickerDialog extends ConsumerStatefulWidget {
  const ModelPickerDialog({required this.connectionId, super.key});

  final String connectionId;

  @override
  ConsumerState<ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends ConsumerState<ModelPickerDialog> {
  final _query = TextEditingController();
  var _fetching = false;
  String? _fetchError;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final models =
        ref.watch(connectionModelsProvider(widget.connectionId)).value ??
        const <String>[];
    final needle = _query.text.trim().toLowerCase();
    final hits = [
      for (final m in models)
        if (needle.isEmpty || m.toLowerCase().contains(needle)) m,
    ];
    return AlertDialog(
      title: const Text('Pick a model'),
      content: SizedBox(
        width: 440,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(
                hintText: models.isEmpty
                    ? 'Search models…'
                    : 'Search ${models.length} models…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: models.isEmpty
                  ? _emptyState(context)
                  : hits.isEmpty
                  ? const Center(child: Text('No model matches.'))
                  : ListView.builder(
                      itemCount: hits.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        title: Text(
                          hits[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(hits[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('No model list cached for this connection yet.'),
        const SizedBox(height: 12),
        if (_fetching)
          const CircularProgressIndicator()
        else
          FilledButton.tonal(
            onPressed: _fetch,
            child: const Text('Fetch models'),
          ),
        if (_fetchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _fetchError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );

  Future<void> _fetch() async {
    setState(() {
      _fetching = true;
      _fetchError = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      final rows = await db.watchConnections().first;
      final connection = rows.firstWhere((c) => c.id == widget.connectionId);
      await refreshConnectionModels(
        db: db,
        factory: ref.read(clientFactoryProvider),
        connection: connection,
        apiKey: await ref.read(apiKeyStoreProvider).read(widget.connectionId),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _fetchError = '$error');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }
}
