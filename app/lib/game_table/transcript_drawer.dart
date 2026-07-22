import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart' show renderEvent;

import 'game_session.dart';

/// Collapsible scrollback of human-visible events only (UI_UX.md §2).
class TranscriptDrawer extends ConsumerStatefulWidget {
  const TranscriptDrawer({super.key});

  @override
  ConsumerState<TranscriptDrawer> createState() => _TranscriptDrawerState();
}

class _TranscriptDrawerState extends ConsumerState<TranscriptDrawer> {
  int? _dayFilter;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionControllerProvider);
    final days = <int>{};
    var day = 0;
    final lines = <(int, String)>[];
    for (final event in session.visibleEvents) {
      if (event is DayBegan) day = event.day;
      if (event is NightBegan) day = event.day;
      final line = renderEvent(event, session.names);
      if (line != null) {
        days.add(day);
        lines.add((day, line));
      }
    }
    final filtered = [
      for (final (d, line) in lines)
        if (_dayFilter == null || d == _dayFilter) line,
    ];
    return Drawer(
      width: 380,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    'Transcript',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  DropdownButton<int?>(
                    value: _dayFilter,
                    hint: const Text('All days'),
                    items: [
                      const DropdownMenuItem(child: Text('All days')),
                      for (final d in days.toList()..sort())
                        DropdownMenuItem(
                          value: d,
                          child: Text(d == 0 ? 'Night 0' : 'Day $d'),
                        ),
                    ],
                    onChanged: (d) => setState(() => _dayFilter = d),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    filtered[filtered.length - 1 - index],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
