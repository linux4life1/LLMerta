import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart' show renderEvent;
import 'package:persistence/persistence.dart';

import '../game_table/game_table.dart';
import '../services/services.dart';

class ReplaysScreen extends ConsumerWidget {
  const ReplaysScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const ReplaysScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(savedGamesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Replays')),
      body: games.isEmpty
          ? const Center(
              child: Text('No games on the shelf yet — go play one.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final game in games)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        game.finished
                            ? Icons.theater_comedy
                            : Icons.hourglass_bottom,
                      ),
                      title: Text(game.townName),
                      subtitle: Text(
                        game.finished
                            ? 'Finished — ${switch (game.winner) {
                                'town' => 'the town prevailed',
                                'mafia' => 'the mafia won',
                                _ => 'a draw',
                              }}'
                            : 'In progress — resume from Home',
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete save',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            ref.read(appDatabaseProvider).deleteGame(game.id),
                      ),
                      onTap: game.finished
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReplayViewerScreen(game: game),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Step through a finished game as the human saw it (their visibility
/// slice; the full spoiler view lives in the Reveal).
class ReplayViewerScreen extends StatefulWidget {
  const ReplayViewerScreen({required this.game, super.key});

  final Game game;

  @override
  State<ReplayViewerScreen> createState() => _ReplayViewerScreenState();
}

class _ReplayViewerScreenState extends State<ReplayViewerScreen> {
  late final List<String> _names;
  late final List<String> _lines;
  late int _position;

  @override
  void initState() {
    super.initState();
    _names = (jsonDecode(widget.game.namesJson) as List).cast<String>();
    final events = [
      for (final e in jsonDecode(widget.game.eventsJson) as List)
        eventFromJson((e as Map).cast<String, Object?>()),
    ];
    final roles = events.whereType<RolesDealt>().firstOrNull?.roles ?? {};
    final humanIsMafia = roles[widget.game.humanSeat]?.faction == Faction.mafia;
    final visible = events.visibleTo(
      widget.game.humanSeat,
      isMafia: humanIsMafia,
    );
    _lines = [
      for (final event in visible)
        if (renderEvent(event, _names) case final String line) line,
    ];
    _position = _lines.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.game.townName} — replay')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _position,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _lines[index],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back one event',
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _position > 0
                      ? () => setState(() => _position--)
                      : null,
                ),
                Expanded(
                  child: Slider(
                    value: _position.toDouble(),
                    max: _lines.length.toDouble(),
                    divisions: _lines.isEmpty ? 1 : _lines.length,
                    label: '$_position / ${_lines.length}',
                    onChanged: (v) => setState(() => _position = v.round()),
                  ),
                ),
                IconButton(
                  tooltip: 'Forward one event',
                  icon: const Icon(Icons.skip_next),
                  onPressed: _position < _lines.length
                      ? () => setState(() => _position++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
