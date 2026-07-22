import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';

import '../game_table/game_table.dart';
import 'lobby_setup.dart';
import 'scene_picker.dart';
import 'seat_grid.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LobbyScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(lobbySetupControllerProvider);
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Setup — ${setup.townName}'),
        actions: [
          IconButton(
            tooltip: 'Re-roll town name',
            icon: const Icon(Icons.casino_outlined),
            onPressed: controller.rerollTownName,
          ),
        ],
      ),
      body: Row(
        children: [
          const SizedBox(width: 360, child: _ConfigPanel()),
          const VerticalDivider(width: 1),
          const Expanded(child: SeatGridPanel()),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: Text(
                setup.ready
                    ? 'The table is set.'
                    : 'Name yourself and fully cast every AI seat to deal.',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: setup.ready
                  ? () => Navigator.of(context).push(GameTableScreen.route())
                  : null,
              icon: const Icon(Icons.style),
              label: const Text('Deal the cards'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigPanel extends ConsumerWidget {
  const _ConfigPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(lobbySetupControllerProvider);
    final controller = ref.read(lobbySetupControllerProvider.notifier);
    final config = setup.config;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Difficulty', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<Difficulty>(
          segments: const [
            ButtonSegment(value: Difficulty.casual, label: Text('Casual')),
            ButtonSegment(value: Difficulty.standard, label: Text('Standard')),
            ButtonSegment(
              value: Difficulty.cutthroat,
              label: Text('Cutthroat'),
            ),
          ],
          selected: {setup.difficulty},
          onSelectionChanged: (s) => controller.setDifficulty(s.single),
        ),
        const SizedBox(height: 16),
        Text(
          '${config.seats} seats at the table',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: config.seats.toDouble(),
          min: minSeats.toDouble(),
          max: maxSeats.toDouble(),
          divisions: maxSeats - minSeats,
          label: '${config.seats}',
          onChanged: (v) => controller.setSeatCount(v.round()),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Grudge memory'),
          subtitle: const Text('Personas remember finished games'),
          value: setup.grudgeMode,
          onChanged: controller.setGrudgeMode,
        ),
        const SizedBox(height: 8),
        const ScenePicker(),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('House rules'),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Night 0 mafia meetup'),
              value: config.night0,
              onChanged: (v) =>
                  controller.updateConfig(config.copyWith(night0: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sheriff peeks on Night 0'),
              value: config.night0SheriffPeek,
              onChanged: (v) => controller.updateConfig(
                config.copyWith(night0SheriffPeek: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reveal roles on death'),
              value: config.revealRolesOnDeath,
              onChanged: (v) => controller.updateConfig(
                config.copyWith(revealRolesOnDeath: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nominees may vote'),
              value: config.nomineesVote,
              onChanged: (v) =>
                  controller.updateConfig(config.copyWith(nomineesVote: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Doctor may self-protect'),
              value: config.doctorMayProtectSelf,
              onChanged: (v) => controller.updateConfig(
                config.copyWith(doctorMayProtectSelf: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Doctor cannot repeat a target'),
              value: config.doctorNoRepeatTarget,
              onChanged: (v) => controller.updateConfig(
                config.copyWith(doctorNoRepeatTarget: v),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Doctor in play'),
              value: config.includeDoctor,
              onChanged: (v) =>
                  controller.updateConfig(config.copyWith(includeDoctor: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sheriff in play'),
              value: config.includeSheriff,
              onChanged: (v) =>
                  controller.updateConfig(config.copyWith(includeSheriff: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Assassin in play'),
              value: config.includeAssassin,
              onChanged: (v) =>
                  controller.updateConfig(config.copyWith(includeAssassin: v)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Discussion rounds'),
              trailing: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                ],
                selected: {config.discussionRounds},
                onSelectionChanged: (s) => controller.updateConfig(
                  config.copyWith(discussionRounds: s.single),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tied verdict'),
              trailing: DropdownButton<TieRule>(
                value: config.tieRule,
                items: const [
                  DropdownMenuItem(
                    value: TieRule.noElimination,
                    child: Text('Nobody eliminated'),
                  ),
                  DropdownMenuItem(
                    value: TieRule.runoff,
                    child: Text('Runoff vote'),
                  ),
                  DropdownMenuItem(
                    value: TieRule.randomAmongTied,
                    child: Text('Random among tied'),
                  ),
                ],
                onChanged: (rule) => rule == null
                    ? null
                    : controller.updateConfig(config.copyWith(tieRule: rule)),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mafia count'),
              trailing: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: -1, label: Text('−1')),
                  ButtonSegment(value: 0, label: Text('Std')),
                  ButtonSegment(value: 1, label: Text('+1')),
                ],
                selected: {config.mafiaCountDelta},
                onSelectionChanged: (s) => controller.updateConfig(
                  config.copyWith(mafiaCountDelta: s.single),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
