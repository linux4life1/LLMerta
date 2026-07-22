import 'package:game_core/game_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lobby_draft.g.dart';

@riverpod
class LobbyDraft extends _$LobbyDraft {
  @override
  GameConfig build() => const GameConfig(seats: 10);

  void replace(GameConfig config) => state = config;
}
