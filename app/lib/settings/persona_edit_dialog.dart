import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persistence/persistence.dart';

import '../services/services.dart';

class PersonaEditDialog extends ConsumerStatefulWidget {
  const PersonaEditDialog({this.existing, super.key});

  final CustomPersona? existing;

  @override
  ConsumerState<PersonaEditDialog> createState() => _PersonaEditDialogState();
}

class _PersonaEditDialogState extends ConsumerState<PersonaEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _archetype = TextEditingController(
    text: widget.existing?.archetype,
  );
  late final _style = TextEditingController(text: widget.existing?.style);
  late final _quirk = TextEditingController(text: widget.existing?.quirk);
  late final _voiceSample = TextEditingController(
    text: widget.existing?.voiceSample,
  );

  @override
  void dispose() {
    for (final c in [_name, _archetype, _style, _quirk, _voiceSample]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;
    return AlertDialog(
      title: Text(widget.existing == null ? 'New persona' : 'Edit persona'),
      content: Form(
        key: _form,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: widget.existing == null,
                // Name is the identity grudge memory follows across games.
                enabled: widget.existing == null,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: required,
              ),
              TextFormField(
                controller: _archetype,
                decoration: const InputDecoration(
                  labelText: 'Archetype (e.g. retired judge)',
                ),
                validator: required,
              ),
              TextFormField(
                controller: _style,
                decoration: const InputDecoration(labelText: 'Speech style'),
                validator: required,
              ),
              TextFormField(
                controller: _quirk,
                decoration: const InputDecoration(labelText: 'Quirk'),
                validator: required,
              ),
              TextFormField(
                controller: _voiceSample,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Voice sample (optional)',
                  helperText: 'A line of dialogue in their own words',
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
    final sample = _voiceSample.text.trim();
    await ref
        .read(appDatabaseProvider)
        .upsertPersona(
          CustomPersonasCompanion.insert(
            name: _name.text.trim(),
            archetype: _archetype.text.trim(),
            style: _style.text.trim(),
            quirk: _quirk.text.trim(),
            avatarPath: Value(widget.existing?.avatarPath),
            voiceSample: Value(sample.isEmpty ? null : sample),
            fpaCharacterId: Value(widget.existing?.fpaCharacterId),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }
}
