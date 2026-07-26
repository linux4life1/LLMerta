import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llm/llm.dart' show resolveFpaInstall;

import '../services/services.dart';
import '../settings/settings.dart';
import 'lobby_setup.dart';
import 'model_picker.dart';
import 'voice_picker.dart';

class SeatGridPanel extends ConsumerWidget {
  const SeatGridPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(lobbySetupControllerProvider);
    final connections = ref.watch(connectionRowsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HumanIdentityCard(),
        const SizedBox(height: 12),
        if (connections.isEmpty)
          const _NoConnectionsCard()
        else
          const _BulkCastBar(),
        const SizedBox(height: 12),
        _SeatTable(seats: setup.aiSeats.toList()),
      ],
    );
  }
}

class HumanIdentityCard extends ConsumerWidget {
  const HumanIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(lobbySetupControllerProvider);
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    final fpPersonas = ref.watch(fpaPersonasProvider);
    final persona = setup.humanPersona;
    final avatarPath = persona?.avatarPath;
    final hasAvatar = avatarPath != null && File(avatarPath).existsSync();
    final fpaLabel = resolveFpaInstall()?.helperLabel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: hasAvatar ? FileImage(File(avatarPath)) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      setup.humanName.isEmpty
                          ? '?'
                          : setup.humanName[0].toUpperCase(),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You — Seat ${setup.humanSeat + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<FpPersona?>(
                          initialValue: persona,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Play as',
                            isDense: true,
                            helperText: fpPersonas.isEmpty
                                ? (fpaLabel == null
                                      ? 'No Front Porch install found '
                                            '(Stable or Rawhide)'
                                      : 'No personas in $fpaLabel')
                                : fpaLabel ?? 'Your Front Porch AI personas',
                          ),
                          items: [
                            const DropdownMenuItem(
                              child: Text('Just yourself'),
                            ),
                            for (final p in fpPersonas)
                              DropdownMenuItem(value: p, child: Text(p.label)),
                          ],
                          onChanged: controller.setHumanPersona,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          key: ValueKey('human-name-${persona?.id}'),
                          initialValue: setup.humanName,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            isDense: true,
                          ),
                          onChanged: controller.setHumanName,
                        ),
                      ),
                    ],
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

class _NoConnectionsCard extends StatelessWidget {
  const _NoConnectionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.power_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No model connections yet',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Every AI seat speaks through one. Local servers are '
                    'found automatically; hosted ones just need a key.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const ConnectionEditDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add a connection'),
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
    final pool = ref.watch(castingPersonaNamesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cast the table',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'pick once, apply to every AI seat — then fine-tune below',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
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
                  child: ModelPickerField(
                    connectionId: _connectionId,
                    model: _model,
                    onPicked: (m) => setState(() => _model = m),
                  ),
                ),
                FilledButton(
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
          ],
        ),
      ),
    );
  }
}

class _SeatTable extends ConsumerWidget {
  const _SeatTable({required this.seats});

  final List<int> seats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hint = ref.watch(swapHintProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            for (final (i, seat) in seats.indexed) ...[
              if (i > 0) const Divider(height: 10),
              _SeatRow(seat: seat),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatRow extends ConsumerWidget {
  const _SeatRow({required this.seat});

  final int seat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casting = ref.watch(
      lobbySetupControllerProvider.select((s) => s.seats[seat]),
    );
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    final connections = ref.watch(connectionRowsProvider).value ?? const [];
    final pool = ref.watch(castingPersonaNamesProvider);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Text('${seat + 1}', style: text.titleMedium),
                Text(
                  'seat',
                  style: text.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
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
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
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
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: ModelPickerField(
              connectionId: casting.connectionId,
              model: casting.model,
              onPicked: (m) =>
                  controller.castSeat(seat, casting.copyWith(model: m)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 118,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temp ${casting.temperature.toStringAsFixed(1)}',
                  style: text.labelSmall,
                ),
                SizedBox(
                  height: 26,
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
          VoicePickerButton(seat: seat),
        ],
      ),
    );
  }
}
