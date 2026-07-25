import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:game_core/game_core.dart';
import 'package:llm/llm.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/services.dart';
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
    FpPersona? humanPersona,
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

/// Local servers that reload between models pay per switch; adjacent
/// same-model seats keep swaps to a couple per round (BALANCE.md).
@riverpod
String? swapHint(Ref ref) {
  final setup = ref.watch(lobbySetupControllerProvider);
  final connections = ref.watch(connectionRowsProvider).value ?? const [];
  final localIds = {
    for (final c in connections)
      if (c.baseUrl.contains('127.0.0.1') || c.baseUrl.contains('localhost'))
        c.id: c.label,
  };
  final byConnection = <String, Set<String>>{};
  for (final seat in setup.aiSeats) {
    final casting = setup.seats[seat];
    if (casting.connectionId case final String id
        when localIds.containsKey(id)) {
      if (casting.model case final String model) {
        byConnection.putIfAbsent(id, () => {}).add(model);
      }
    }
  }
  for (final MapEntry(key: id, value: models) in byConnection.entries) {
    if (models.length > 1) {
      return '${localIds[id]} hosts ${models.length} different models — '
          'if it reloads per model, seat same-model neighbors together '
          'to keep swaps down.';
    }
  }
  return null;
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

@riverpod
class LobbySetupController extends _$LobbySetupController {
  final _rng = Random();

  @override
  LobbySetup build() {
    const difficulty = Difficulty.standard;
    return LobbySetup(
      config: difficulty.applyRules(const GameConfig(seats: 10)),
      townName: pickTownName(Random()),
      seats: List.filled(10, const SeatCasting()),
      difficulty: difficulty,
    );
  }

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

  void setDifficulty(Difficulty difficulty) => state = state.copyWith(
    difficulty: difficulty,
    config: difficulty.applyRules(state.config),
  );

  void rerollTownName() => state = state.copyWith(
    townName: pickTownName(_rng, avoid: state.townName),
  );

  void setScene(Scene scene) => state = state.copyWith(scene: scene);

  void setGrudgeMode(bool enabled) =>
      state = state.copyWith(grudgeMode: enabled);

  void setHumanName(String name) => state = state.copyWith(humanName: name);

  /// You play as yourself or as one of your own Front Porch personas
  /// (UI_UX.md §1) — never a house character. Picking one prefills the
  /// name; it stays editable.
  void setHumanPersona(FpPersona? persona) => state = state.copyWith(
    humanPersona: persona,
    humanName: persona?.name ?? state.humanName,
  );

  /// A fixed human chair made them every model's first-read kill target
  /// (field report: dead by night 2, every game). Drawn fresh each deal;
  /// the displaced AI casting swaps into the vacated slot.
  void randomizeHumanSeat([Random? rng]) {
    final target = (rng ?? _rng).nextInt(state.seats.length);
    if (target == state.humanSeat) return;
    final seats = [...state.seats];
    final displaced = seats[target];
    seats[target] = seats[state.humanSeat];
    seats[state.humanSeat] = displaced;
    state = state.copyWith(humanSeat: target, seats: seats);
  }

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
