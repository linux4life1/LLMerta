import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistence/persistence.dart';

import '../services/services.dart';
import 'connection_providers.dart';
import 'connections_section.dart';

const _defaultBaseUrls = {
  ProviderKind.openaiCompat: 'http://127.0.0.1:8000/v1',
  ProviderKind.anthropic: 'https://api.anthropic.com',
  ProviderKind.gemini: 'https://generativelanguage.googleapis.com',
};

/// Add flow: scan results first (zero typing), hosted presets second
/// (key-only), the full form only under "Custom server". Editing an
/// existing connection goes straight to the form.
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
  final _hostedKey = TextEditingController();
  late ProviderKind _kind = widget.existing?.kind ?? ProviderKind.openaiCompat;
  var _baseUrlTouched = false;
  HostedPreset? _hostedPreset;
  late var _showCustom = widget.existing != null;

  @override
  void dispose() {
    _label.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _hostedKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add a connection' : 'Edit connection',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.existing == null) ...[
                _sectionLabel(context, 'On this machine'),
                const _LocalScanList(),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Hosted'),
                const SizedBox(height: 8),
                _hostedChips(),
                if (_hostedPreset != null) _hostedKeyRow(),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _showCustom = !_showCustom),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'Custom server…',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Icon(
                          _showCustom ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_showCustom) _customForm(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_showCustom)
          FilledButton(onPressed: _saveCustom, child: const Text('Save')),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 1.4,
      color: Theme.of(context).colorScheme.primary,
    ),
  );

  Widget _hostedChips() => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final preset in hostedPresets)
        ChoiceChip(
          label: Text(preset.name),
          tooltip: preset.blurb,
          selected: _hostedPreset == preset,
          onSelected: (_) => setState(() => _hostedPreset = preset),
        ),
    ],
  );

  Widget _hostedKeyRow() {
    final preset = _hostedPreset!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _hostedKey,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '${preset.name} API key',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _addHosted(preset),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "URL's already set · key goes to your OS keychain · "
            'models fetch automatically',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _customForm() => Form(
    key: _form,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _label,
          decoration: const InputDecoration(labelText: 'Label'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
        ),
        DropdownButtonFormField<ProviderKind>(
          initialValue: _kind,
          decoration: const InputDecoration(labelText: 'Provider type'),
          items: [
            for (final kind in ProviderKind.values)
              DropdownMenuItem(value: kind, child: Text(kindLabels[kind]!)),
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
          validator: (v) => Uri.tryParse((v ?? '').trim())?.isAbsolute ?? false
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
  );

  Future<String> _insertConnection({
    required String label,
    required ProviderKind kind,
    required String baseUrl,
  }) async {
    final id =
        widget.existing?.id ?? 'conn-${DateTime.now().microsecondsSinceEpoch}';
    await ref
        .read(appDatabaseProvider)
        .upsertConnection(
          ConnectionsCompanion(
            id: Value(id),
            label: Value(label),
            kind: Value(kind),
            baseUrl: Value(baseUrl),
            defaultModel: Value(widget.existing?.defaultModel),
            modelsFetchedAt: Value(widget.existing?.modelsFetchedAt),
          ),
        );
    return id;
  }

  /// Fire-and-forget model fetch with everything captured before the
  /// dialog pops — no ref use after dispose.
  void _fetchModelsDetached(String id, String? apiKey) {
    final db = ref.read(appDatabaseProvider);
    final factory = ref.read(clientFactoryProvider);
    final keyStore = ref.read(apiKeyStoreProvider);
    unawaited(() async {
      try {
        final rows = await db.watchConnections().first;
        final connection = rows.firstWhere((c) => c.id == id);
        final key = apiKey?.isNotEmpty ?? false
            ? apiKey
            : await keyStore.read(id);
        await refreshConnectionModels(
          db: db,
          factory: factory,
          connection: connection,
          apiKey: key,
        );
      } on Exception {
        // The Test button in Settings remains the retry path.
      }
    }());
  }

  Future<void> _addHosted(HostedPreset preset) async {
    final key = _hostedKey.text.trim();
    if (key.isEmpty) return;
    final id = await _insertConnection(
      label: preset.name,
      kind: preset.kind,
      baseUrl: preset.baseUrl,
    );
    await ref.read(apiKeyStoreProvider).write(id, key);
    _fetchModelsDetached(id, key);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveCustom() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final id = await _insertConnection(
      label: _label.text.trim(),
      kind: _kind,
      baseUrl: _baseUrl.text.trim(),
    );
    final apiKey = _apiKey.text.trim();
    if (apiKey.isNotEmpty) {
      await ref.read(apiKeyStoreProvider).write(id, apiKey);
    }
    _fetchModelsDetached(id, apiKey.isEmpty ? null : apiKey);
    if (mounted) Navigator.of(context).pop();
  }
}

class _LocalScanList extends ConsumerWidget {
  const _LocalScanList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(localScanProvider);
    final hits = scan.value ?? const <LocalScanHit>[];
    final found = {for (final h in hits) h.preset.name: h};
    return Column(
      children: [
        if (scan.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          )
        else
          for (final preset in localServerPresets)
            _ScanRow(preset: preset, hit: found[preset.name]),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => ref.read(localScanProvider.notifier).rescan(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Rescan'),
          ),
        ),
      ],
    );
  }
}

class _ScanRow extends ConsumerWidget {
  const _ScanRow({required this.preset, required this.hit});

  final LocalServerPreset preset;
  final LocalScanHit? hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final running = hit != null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        running ? Icons.circle : Icons.circle_outlined,
        size: 11,
        color: running ? scheme.primary : scheme.outline,
      ),
      title: Text(
        preset.name,
        style: TextStyle(color: running ? null : scheme.outline),
      ),
      subtitle: Text(
        running
            ? 'localhost:${preset.port} · ${hit!.models.length} '
                  'model${hit!.models.length == 1 ? '' : 's'}'
            : 'localhost:${preset.port} · not running',
      ),
      trailing: running
          ? FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _add(context, ref),
              child: const Text('Add'),
            )
          : null,
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final navigator = Navigator.of(context);
    final id = 'conn-${DateTime.now().microsecondsSinceEpoch}';
    await db.upsertConnection(
      ConnectionsCompanion(
        id: Value(id),
        label: Value(preset.name),
        kind: const Value(ProviderKind.openaiCompat),
        baseUrl: Value(preset.baseUrl),
      ),
    );
    await db.replaceModels(id, hit!.models);
    navigator.pop();
  }
}
