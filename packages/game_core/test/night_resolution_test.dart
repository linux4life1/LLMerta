import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

void main() {
  test('unprotected mafia target dies', () {
    final r = resolveNight(
      mafiaTarget: 3,
      assassinTarget: null,
      protectedSeat: 5,
    );
    expect(r.killed, [3]);
    expect(r.saved, isEmpty);
  });

  test('doctor blocks the mafia kill', () {
    final r = resolveNight(
      mafiaTarget: 3,
      assassinTarget: null,
      protectedSeat: 3,
    );
    expect(r.killed, isEmpty);
    expect(r.saved, [3]);
  });

  test('doctor blocks the assassin bullet too', () {
    final r = resolveNight(
      mafiaTarget: null,
      assassinTarget: 4,
      protectedSeat: 4,
    );
    expect(r.killed, isEmpty);
    expect(r.saved, [4]);
  });

  test('mafia and assassin can both land in one night', () {
    final r = resolveNight(
      mafiaTarget: 2,
      assassinTarget: 6,
      protectedSeat: null,
    );
    expect(r.killed, [2, 6]);
  });

  test('same target from both killers dies once', () {
    final r = resolveNight(
      mafiaTarget: 2,
      assassinTarget: 2,
      protectedSeat: null,
    );
    expect(r.killed, [2]);
  });

  test('same target from both killers, protected: nobody dies', () {
    final r = resolveNight(mafiaTarget: 2, assassinTarget: 2, protectedSeat: 2);
    expect(r.killed, isEmpty);
    expect(r.saved, [2]);
  });

  test('protection splits when killers pick different targets', () {
    final r = resolveNight(mafiaTarget: 2, assassinTarget: 6, protectedSeat: 2);
    expect(r.killed, [6]);
    expect(r.saved, [2]);
  });

  test('quiet night: no actions, no deaths', () {
    final r = resolveNight(
      mafiaTarget: null,
      assassinTarget: null,
      protectedSeat: 1,
    );
    expect(r.killed, isEmpty);
    expect(r.saved, isEmpty);
  });
}
