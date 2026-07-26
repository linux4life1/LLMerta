// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameSessionController)
const gameSessionControllerProvider = GameSessionControllerProvider._();

final class GameSessionControllerProvider
    extends $NotifierProvider<GameSessionController, GameSession> {
  const GameSessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameSessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameSessionControllerHash();

  @$internal
  @override
  GameSessionController create() => GameSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameSession>(value),
    );
  }
}

String _$gameSessionControllerHash() =>
    r'3fcdfc0ea6abfaaed82a7414f5ab3348afdc5428';

abstract class _$GameSessionController extends $Notifier<GameSession> {
  GameSession build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<GameSession, GameSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameSession, GameSession>,
              GameSession,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
