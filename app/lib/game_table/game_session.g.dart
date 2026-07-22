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
    r'de53fb41f0d4e610768ff044be6699577fe80245';

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

@ProviderFor(sessionStage)
const sessionStageProvider = SessionStageProvider._();

final class SessionStageProvider
    extends $FunctionalProvider<GameStage, GameStage, GameStage>
    with $Provider<GameStage> {
  const SessionStageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionStageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionStageHash();

  @$internal
  @override
  $ProviderElement<GameStage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameStage create(Ref ref) {
    return sessionStage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameStage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameStage>(value),
    );
  }
}

String _$sessionStageHash() => r'4dcc6bd1263ce035a6f46039549419174fa233f8';

@ProviderFor(savedGames)
const savedGamesProvider = SavedGamesProvider._();

final class SavedGamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Game>>,
          List<Game>,
          Stream<List<Game>>
        >
    with $FutureModifier<List<Game>>, $StreamProvider<List<Game>> {
  const SavedGamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedGamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedGamesHash();

  @$internal
  @override
  $StreamProviderElement<List<Game>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Game>> create(Ref ref) {
    return savedGames(ref);
  }
}

String _$savedGamesHash() => r'4c42399ca0e9f1bcce0b502d9932828dbd398dcd';

@ProviderFor(humanRequest)
const humanRequestProvider = HumanRequestProvider._();

final class HumanRequestProvider
    extends
        $FunctionalProvider<
          AsyncValue<HumanRequest?>,
          HumanRequest?,
          Stream<HumanRequest?>
        >
    with $FutureModifier<HumanRequest?>, $StreamProvider<HumanRequest?> {
  const HumanRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'humanRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$humanRequestHash();

  @$internal
  @override
  $StreamProviderElement<HumanRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<HumanRequest?> create(Ref ref) {
    return humanRequest(ref);
  }
}

String _$humanRequestHash() => r'8de0eda886440d0b06f067154c9033f3631dffba';
