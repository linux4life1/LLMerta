import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

Map<int, PlayerController> _bots(int seats) => {
  for (var s = 0; s < seats; s++) s: RandomLegalController(s),
};

Future<GameResult> _run(
  Map<int, PlayerController> controllers, {
  int seats = 9,
  int seed = 1234,
}) => GameEngine(
  config: GameConfig(seats: seats),
  controllers: controllers,
  rngSeed: seed,
).run();

List<String> _encoded(Iterable<GameEvent> events) => [
  for (final e in events) jsonEncode(eventToJson(e)),
];

void main() {
  test('every event type survives a JSON round-trip', () async {
    final result = await _run(_bots(9));
    final seen = <Type>{};
    for (final event in result.events) {
      seen.add(event.runtimeType);
      final json = jsonDecode(jsonEncode(eventToJson(event)));
      final back = eventFromJson((json as Map).cast<String, Object?>());
      expect(
        jsonEncode(eventToJson(back)),
        jsonEncode(eventToJson(event)),
        reason: '$event',
      );
      expect(back.scope.runtimeType, event.scope.runtimeType);
    }
    // A full random game must exercise most of the event vocabulary.
    expect(seen.length, greaterThanOrEqualTo(15), reason: '$seen');
  });

  test('unknown event type throws a FormatException', () {
    expect(
      () => eventFromJson(const {'t': 'timeTravel'}),
      throwsFormatException,
    );
  });

  test('config round-trips including non-defaults', () {
    const config = GameConfig(
      seats: 12,
      doctorMayProtectSelf: false,
      night0SheriffPeek: true,
      discussionRounds: 2,
      tieRule: TieRule.randomAmongTied,
      includeAssassin: false,
      mafiaCountDelta: 1,
      maxDays: 9,
    );
    final back = configFromJson(
      (jsonDecode(jsonEncode(configToJson(config))) as Map)
          .cast<String, Object?>(),
    );
    expect(jsonEncode(configToJson(back)), jsonEncode(configToJson(config)));
  });

  test('full-log replay reproduces the game event for event', () async {
    final original = await _run(_bots(9));
    final resumed = await _run(
      replayControllers(recorded: original.events, live: _bots(9)),
    );
    expect(_encoded(resumed.events), _encoded(original.events));
    expect(resumed.winner, original.winner);
    expect(resumed.days, original.days);
  });

  test('prefix replay preserves the saved arc, then plays on live', () async {
    final original = await _run(_bots(9));
    // Cut at the second day boundary — a phase-boundary autosave point.
    final dayStarts = <int>[];
    for (var i = 0; i < original.events.length; i++) {
      if (original.events[i] is DayBegan) dayStarts.add(i);
    }
    // Needs at least two days to make the cut meaningful.
    expect(dayStarts.length, greaterThanOrEqualTo(2));
    final prefix = original.events.sublist(0, dayStarts[1]);

    final resumed = await _run(
      replayControllers(recorded: prefix, live: _bots(9)),
    );
    expect(
      _encoded(resumed.events.take(prefix.length)),
      _encoded(prefix),
      reason: 'the replayed prefix must be identical to the save',
    );
    expect(resumed.events.whereType<GameEnded>(), hasLength(1));
  });
}
