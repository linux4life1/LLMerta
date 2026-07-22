// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_setup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local servers that reload between models pay per switch; adjacent
/// same-model seats keep swaps to a couple per round (BALANCE.md).

@ProviderFor(swapHint)
const swapHintProvider = SwapHintProvider._();

/// Local servers that reload between models pay per switch; adjacent
/// same-model seats keep swaps to a couple per round (BALANCE.md).

final class SwapHintProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Local servers that reload between models pay per switch; adjacent
  /// same-model seats keep swaps to a couple per round (BALANCE.md).
  const SwapHintProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swapHintProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swapHintHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return swapHint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$swapHintHash() => r'eca11cacc899cc642b244d0d3ff1abc4e78ee385';

/// AI seats cast from the whole pool: imports/customs first, then house.

@ProviderFor(castingPersonaNames)
const castingPersonaNamesProvider = CastingPersonaNamesProvider._();

/// AI seats cast from the whole pool: imports/customs first, then house.

final class CastingPersonaNamesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// AI seats cast from the whole pool: imports/customs first, then house.
  const CastingPersonaNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'castingPersonaNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$castingPersonaNamesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return castingPersonaNames(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$castingPersonaNamesHash() =>
    r'af495ffb7e5c51eec0795077e3f96cf8ca0cfabf';

@ProviderFor(LobbySetupController)
const lobbySetupControllerProvider = LobbySetupControllerProvider._();

final class LobbySetupControllerProvider
    extends $NotifierProvider<LobbySetupController, LobbySetup> {
  const LobbySetupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lobbySetupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lobbySetupControllerHash();

  @$internal
  @override
  LobbySetupController create() => LobbySetupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LobbySetup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LobbySetup>(value),
    );
  }
}

String _$lobbySetupControllerHash() =>
    r'34afd6859428411e0ba0287c9e4e177fc986d697';

abstract class _$LobbySetupController extends $Notifier<LobbySetup> {
  LobbySetup build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LobbySetup, LobbySetup>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LobbySetup, LobbySetup>,
              LobbySetup,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
