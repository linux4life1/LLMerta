import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/lobby/lobby.dart';
import 'package:llmerta_app/settings/settings.dart';
import 'package:llmerta_app/theme/theme.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('lobby draft starts at the 10-seat default and accepts edits', () {
    final c = container();
    expect(c.read(lobbyDraftProvider).seats, 10);
    c
        .read(lobbyDraftProvider.notifier)
        .replace(const GameConfig(seats: 14, discussionRounds: 2));
    expect(c.read(lobbyDraftProvider).seats, 14);
    expect(c.read(lobbyDraftProvider).discussionRounds, 2);
  });

  test('persona pool exposes the llm house library', () {
    final c = container();
    expect(c.read(personaPoolProvider), same(personaLibrary));
    expect(c.read(personaPoolProvider).length, greaterThanOrEqualTo(30));
  });

  test('table mood defaults to night and flips per phase', () {
    final c = container();
    expect(c.read(tableMoodControllerProvider), TableMood.night);
    c.read(tableMoodControllerProvider.notifier).set(TableMood.day);
    expect(c.read(tableMoodControllerProvider), TableMood.day);
  });
}
