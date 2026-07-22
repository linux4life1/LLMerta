import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../settings/settings.dart';
import 'scenes.dart';
import 'town_names.dart';

part 'lobby_setup.freezed.dart';
part 'lobby_setup.g.dart';

@freezed
abstract class SeatCasting with _$SeatCasting {
  const factory SeatCasting({
    String? personaName,
    String? connectionId,
    String? model,
    @Default(0.7) double temperature,
    String? voice,
  }) = _SeatCasting;
}

@freezed
abstract class LobbySetup with _$LobbySetup {
  const LobbySetup._();

  const factory LobbySetup({
    required GameConfig config,
    required String townName,
    required List<SeatCasting> seats,
    @Default(Difficulty.standard) Difficulty difficulty,
    @Default(BuiltInScene(BuiltInSceneId.midnightStudy)) Scene scene,
    @Default(0) int humanSeat,
    @Default('') String humanName,
    String? humanPersonaName,
    @Default(true) bool grudgeMode,
  }) = _LobbySetup;

  Iterable<int> get aiSeats =>
      [for (var s = 0; s < config.seats; s++) s].where((s) => s != humanSeat);

  /// Deal is allowed once the human is named and every AI seat is fully
  /// cast (persona + connection + model).
  bool get ready =>
      humanName.trim().isNotEmpty &&
      aiSeats.every((s) {
        final seat = seats[s];
        return seat.personaName != null &&
            seat.connectionId != null &&
            seat.model != null;
      });
}

/// AI seats cast from the whole pool: imports/customs first, then house.
@riverpod
List<String> castingPersonaNames(Ref ref) {
  final customs = ref.watch(personaRowsProvider).value ?? const [];
  return [
    for (final p in customs) p.name,
    for (final p in personaLibrary) p.name,
  ];
}

/// The human may only be a custom/imported persona, never a house one
/// (UI_UX.md §1) — enforced here by construction.
@riverpod
List<String> humanPersonaNames(Ref ref) {
  final customs = ref.watch(personaRowsProvider).value ?? const [];
  return [for (final p in customs) p.name];
}

@riverpod
class LobbySetupController extends _$LobbySetupController {
  final _rng = Random();

  @override
  LobbySetup build() => LobbySetup(
    config: const GameConfig(seats: 10),
    townName: pickTownName(Random()),
    seats: List.filled(10, const SeatCasting()),
  );

  void setSeatCount(int count) {
    final seats = [
      for (var s = 0; s < count; s++)
        s < state.seats.length ? state.seats[s] : const SeatCasting(),
    ];
    state = state.copyWith(
      config: state.config.copyWith(seats: count),
      seats: seats,
    );
  }

  void updateConfig(GameConfig config) {
    if (config.seats != state.config.seats) {
      state = state.copyWith(config: config);
      setSeatCount(config.seats);
    } else {
      state = state.copyWith(config: config);
    }
  }

  void setDifficulty(Difficulty difficulty) =>
      state = state.copyWith(difficulty: difficulty);

  void rerollTownName() => state = state.copyWith(
    townName: pickTownName(_rng, avoid: state.townName),
  );

  void setScene(Scene scene) => state = state.copyWith(scene: scene);

  void setGrudgeMode(bool enabled) =>
      state = state.copyWith(grudgeMode: enabled);

  void setHumanName(String name) => state = state.copyWith(humanName: name);

  /// The human is never a house persona (UI_UX.md §1): only customs and
  /// imports may be picked, which the UI enforces by construction.
  void setHumanPersona(String? personaName) =>
      state = state.copyWith(humanPersonaName: personaName);

  void castSeat(int seat, SeatCasting casting) {
    final seats = [...state.seats];
    seats[seat] = casting;
    state = state.copyWith(seats: seats);
  }

  void castAllSeats({required String connectionId, required String model}) {
    final seats = [
      for (var s = 0; s < state.seats.length; s++)
        s == state.humanSeat
            ? state.seats[s]
            : state.seats[s].copyWith(connectionId: connectionId, model: model),
    ];
    state = state.copyWith(seats: seats);
  }

  void shufflePersonas(List<String> pool, [Random? rng]) {
    final names = [...pool]..shuffle(rng ?? _rng);
    var next = 0;
    final seats = [
      for (var s = 0; s < state.seats.length; s++)
        s == state.humanSeat || next >= names.length
            ? state.seats[s]
            : state.seats[s].copyWith(personaName: names[next++]),
    ];
    state = state.copyWith(seats: seats);
  }
}
