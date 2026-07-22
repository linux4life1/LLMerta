import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';

import '../lobby/lobby.dart';

part 'session_state.freezed.dart';

enum GameStage { idle, casting, running, finished, error }

const grudgeBookPrefKey = 'grudgeBook';

/// Session snapshot for the UI. [visibleEvents] is the ONLY event surface
/// exposed while a game runs — filtered per event as they arrive; the full
/// log stays inside the controller until the post-game reveal.
@freezed
abstract class GameSession with _$GameSession {
  const factory GameSession({
    @Default(GameStage.idle) GameStage stage,
    @Default([]) List<GameEvent> visibleEvents,
    @Default(0) int humanSeat,
    @Default([]) List<String> names,
    @Default({}) Map<int, String> modelBadges,
    @Default({}) Map<int, Persona> personas,
    @Default(false) bool humanIsMafia,
    Scene? scene,
    String? townName,
    String? gameId,
    @Default('') String notes,
    Faction? winner,
    String? error,
  }) = _GameSession;
}
