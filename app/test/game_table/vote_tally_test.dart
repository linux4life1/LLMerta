import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/game_table/game_table.dart';

void main() {
  const names = ['Alma', 'Boris', 'Clara', 'Dmitri'];

  test('tally ranks targets by weight and counts abstentions', () {
    expect(
      voteTally({0: 2, 1: 2, 2: null, 3: 0}, names),
      'Clara 2  ·  Alma 1  ·  abstain 1',
    );
    expect(voteTally({0: 1}, names), 'Boris 1');
    expect(voteTally({0: null, 1: null}, names), 'abstain 2');
  });
}
