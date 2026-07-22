import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';
import 'lobby_setup.dart';

class SeatGridPanel extends ConsumerWidget {
  const SeatGridPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(lobbySetupControllerProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _HumanIdentityCard(),
        const SizedBox(height: 8),
        const _BulkCastBar(),
        const SizedBox(height: 8),
        for (final seat in setup.aiSeats) _SeatCard(seat: seat),
      ],
    );
  }
}

class _HumanIdentityCard extends ConsumerWidget {
  const _HumanIdentityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(lobbySetupControllerProvider);
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    final personaNames = ref.watch(humanPersonaNamesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You — Seat ${setup.humanSeat + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    initialValue: setup.humanName,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      isDense: true,
                    ),
                    onChanged: controller.setHumanName,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    initialValue: setup.humanPersonaName,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Your persona (optional)',
                      isDense: true,
                      // House characters are for AI seats only.
                      helperText: 'Own creations and imports only',
                    ),
                    items: [
                      const DropdownMenuItem(child: Text('Just yourself')),
                      for (final name in personaNames)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: controller.setHumanPersona,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final name = await ref
                        .read(personaImporterProvider.notifier)
                        .importPickedFile();
                    if (name != null) controller.setHumanPersona(name);
                  },
                  icon: const Icon(Icons.file_open_outlined),
                  label: const Text('Import my card…'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkCastBar extends ConsumerStatefulWidget {
  const _BulkCastBar();

  @override
  ConsumerState<_BulkCastBar> createState() => _BulkCastBarState();
}

class _BulkCastBarState extends ConsumerState<_BulkCastBar> {
  String? _connectionId;
  String? _model;

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(connectionRowsProvider).value ?? const [];
    final models = _connectionId == null
        ? const <String>[]
        : ref.watch(connectionModelsProvider(_connectionId!)).value ??
              const <String>[];
    final pool = ref.watch(castingPersonaNamesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Cast the table',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: _connectionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Connection',
                  isDense: true,
                ),
                items: [
                  for (final c in connections)
                    DropdownMenuItem(value: c.id, child: Text(c.label)),
                ],
                onChanged: (id) => setState(() {
                  _connectionId = id;
                  _model = null;
                }),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_connectionId),
                initialValue: _model,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  isDense: true,
                ),
                items: [
                  for (final m in models)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (m) => setState(() => _model = m),
              ),
            ),
            FilledButton.tonal(
              onPressed: _connectionId != null && _model != null
                  ? () => ref
                        .read(lobbySetupControllerProvider.notifier)
                        .castAllSeats(
                          connectionId: _connectionId!,
                          model: _model!,
                        )
                  : null,
              child: const Text('Cast all seats'),
            ),
            OutlinedButton(
              onPressed: pool.isEmpty
                  ? null
                  : () => ref
                        .read(lobbySetupControllerProvider.notifier)
                        .shufflePersonas(pool),
              child: const Text('Shuffle personas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatCard extends ConsumerWidget {
  const _SeatCard({required this.seat});

  final int seat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casting = ref.watch(
      lobbySetupControllerProvider.select((s) => s.seats[seat]),
    );
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    final connections = ref.watch(connectionRowsProvider).value ?? const [];
    final models = casting.connectionId == null
        ? const <String>[]
        : ref.watch(connectionModelsProvider(casting.connectionId!)).value ??
              const <String>[];
    final pool = ref.watch(castingPersonaNamesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: 52, child: Text('Seat ${seat + 1}')),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: casting.personaName,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Persona',
                  isDense: true,
                ),
                items: [
                  for (final name in pool)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (name) => controller.castSeat(
                  seat,
                  casting.copyWith(personaName: name),
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                initialValue: casting.connectionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Connection',
                  isDense: true,
                ),
                items: [
                  for (final c in connections)
                    DropdownMenuItem(value: c.id, child: Text(c.label)),
                ],
                onChanged: (id) => controller.castSeat(
                  seat,
                  casting.copyWith(connectionId: id, model: null),
                ),
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: ValueKey(casting.connectionId),
                initialValue: casting.model,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  isDense: true,
                ),
                items: [
                  for (final m in models)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (m) =>
                    controller.castSeat(seat, casting.copyWith(model: m)),
              ),
            ),
            SizedBox(
              width: 170,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'T ${casting.temperature.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Expanded(
                    child: Slider(
                      value: casting.temperature,
                      max: 1.5,
                      divisions: 15,
                      onChanged: (t) => controller.castSeat(
                        seat,
                        casting.copyWith(temperature: t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
