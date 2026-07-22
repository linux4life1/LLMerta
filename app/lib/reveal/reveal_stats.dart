import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

import '../game_table/game_table.dart';

class RevealStats {
  const RevealStats({
    required this.days,
    required this.deaths,
    required this.votesCast,
    required this.votesOnMafia,
    required this.townAccuracy,
    required this.mvp,
  });

  final int days;
  final int deaths;
  final Map<int, int> votesCast;
  final Map<int, int> votesOnMafia;

  /// Share of town ballots that landed on an actual mafioso.
  final double townAccuracy;

  /// Town seat with the sharpest ballot record, if anyone voted at all.
  final int? mvp;
}

RevealStats computeRevealStats(List<GameEvent> events) {
  final roles = events.whereType<RolesDealt>().firstOrNull?.roles ?? {};
  final mafia = {
    for (final MapEntry(:key, :value) in roles.entries)
      if (value.faction == Faction.mafia) key,
  };
  var days = 0;
  var deaths = 0;
  final votesCast = <int, int>{};
  final votesOnMafia = <int, int>{};
  for (final event in events) {
    switch (event) {
      case DayBegan(:final day):
        days = day;
      case DawnAnnounced(deaths: final killed):
        deaths += killed.length;
      case Verdict(:final eliminated) when eliminated != null:
        deaths += 1;
      case VotesRevealed(:final votes):
        for (final MapEntry(key: voter, value: target) in votes.entries) {
          if (target == null) continue;
          votesCast[voter] = (votesCast[voter] ?? 0) + 1;
          if (mafia.contains(target)) {
            votesOnMafia[voter] = (votesOnMafia[voter] ?? 0) + 1;
          }
        }
      default:
        break;
    }
  }
  var townBallots = 0;
  var townHits = 0;
  int? mvp;
  var mvpScore = -1;
  for (final MapEntry(key: voter, value: cast) in votesCast.entries) {
    if (mafia.contains(voter)) continue;
    final hits = votesOnMafia[voter] ?? 0;
    townBallots += cast;
    townHits += hits;
    if (hits > mvpScore) {
      mvpScore = hits;
      mvp = voter;
    }
  }
  return RevealStats(
    days: days,
    deaths: deaths,
    votesCast: votesCast,
    votesOnMafia: votesOnMafia,
    townAccuracy: townBallots == 0 ? 0 : townHits / townBallots,
    mvp: mvpScore > 0 ? mvp : null,
  );
}

class StatsSection extends StatelessWidget {
  const StatsSection({required this.stats, required this.names, super.key});

  final RevealStats stats;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('The numbers'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${stats.days} days · ${stats.deaths} dead · '
              'town accuracy ${(stats.townAccuracy * 100).round()}%'
              '${stats.mvp == null ? '' : ' · MVP: ${names[stats.mvp!]}'}',
              style: style,
            ),
          ),
        ),
        for (final MapEntry(key: seat, value: cast) in stats.votesCast.entries)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${names[seat]}: $cast ballots, '
              '${stats.votesOnMafia[seat] ?? 0} on mafia',
              style: style,
            ),
          ),
      ],
    );
  }
}

class ReasoningSection extends ConsumerWidget {
  const ReasoningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final reasoning = ref
        .read(gameSessionControllerProvider.notifier)
        .revealReasoning;
    if (reasoning.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Reasoning peek — how the minds played it'),
      children: [
        for (final MapEntry(key: seat, value: entries) in reasoning.entries)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('${session.names[seat]} (${entries.length} thoughts)'),
            children: [
              for (final (task, reason) in entries)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '[$task] $reason',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class CostSection extends ConsumerWidget {
  const CostSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backends = ref
        .read(gameSessionControllerProvider.notifier)
        .agentBackends;
    if (backends.isEmpty) return const SizedBox.shrink();
    // Clients are shared per connection; report each once.
    final seen = <Object>{};
    final rows = <String>[];
    for (final (client, model) in backends.values) {
      if (!seen.add(client)) continue;
      final usage = client.usage;
      rows.add(
        '$model: ${usage.calls} calls, '
        '${usage.promptTokens} prompt + ${usage.completionTokens} '
        'completion tokens',
      );
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Token bill'),
      children: [
        for (final row in rows)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(row, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
