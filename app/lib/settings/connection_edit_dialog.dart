import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistence/persistence.dart';

import '../services/services.dart';
import 'connections_section.dart';

const _defaultBaseUrls = {
  ProviderKind.openaiCompat: 'http://127.0.0.1:8000/v1',
  ProviderKind.anthropic: 'https://api.anthropic.com',
  ProviderKind.gemini: 'https://generativelanguage.googleapis.com',
};

class ConnectionEditDialog extends ConsumerStatefulWidget {
  const ConnectionEditDialog({this.existing, super.key});

  final Connection? existing;

  @override
  ConsumerState<ConnectionEditDialog> createState() =>
      _ConnectionEditDialogState();
}

class _ConnectionEditDialogState extends ConsumerState<ConnectionEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.existing?.label);
  late final _baseUrl = TextEditingController(
    text: widget.existing?.baseUrl ?? _defaultBaseUrls[_kind],
  );
  final _apiKey = TextEditingController();
  late ProviderKind _kind = widget.existing?.kind ?? ProviderKind.openaiCompat;
  var _baseUrlTouched = false;

  @override
  void dispose() {
    _label.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add connection' : 'Edit connection',
      ),
      content: Form(
        key: _form,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _label,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Label'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Give it a name' : null,
              ),
              DropdownButtonFormField<ProviderKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Provider type'),
                items: [
                  for (final kind in ProviderKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(kindLabels[kind]!),
                    ),
                ],
                onChanged: (kind) {
                  if (kind == null) return;
                  setState(() {
                    _kind = kind;
                    if (!_baseUrlTouched && widget.existing == null) {
                      _baseUrl.text = _defaultBaseUrls[kind]!;
                    }
                  });
                },
              ),
              TextFormField(
                controller: _baseUrl,
                decoration: const InputDecoration(labelText: 'Base URL'),
                onChanged: (_) => _baseUrlTouched = true,
                validator: (v) =>
                    Uri.tryParse((v ?? '').trim())?.isAbsolute ?? false
                    ? null
                    : 'Enter a full URL',
              ),
              TextFormField(
                controller: _apiKey,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API key',
                  helperText: widget.existing == null
                      ? 'Stored in your OS keychain, never in the database'
                      : 'Leave blank to keep the stored key',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final id =
        widget.existing?.id ?? 'conn-${DateTime.now().microsecondsSinceEpoch}';
    await ref
        .read(appDatabaseProvider)
        .upsertConnection(
          ConnectionsCompanion(
            id: Value(id),
            label: Value(_label.text.trim()),
            kind: Value(_kind),
            baseUrl: Value(_baseUrl.text.trim()),
            defaultModel: Value(widget.existing?.defaultModel),
            modelsFetchedAt: Value(widget.existing?.modelsFetchedAt),
          ),
        );
    final apiKey = _apiKey.text.trim();
    if (apiKey.isNotEmpty) {
      await ref.read(apiKeyStoreProvider).write(id, apiKey);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
