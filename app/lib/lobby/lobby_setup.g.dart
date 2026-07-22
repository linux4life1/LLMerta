// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_setup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

/// The human may only be a custom/imported persona, never a house one
/// (UI_UX.md §1) — enforced here by construction.

@ProviderFor(humanPersonaNames)
const humanPersonaNamesProvider = HumanPersonaNamesProvider._();

/// The human may only be a custom/imported persona, never a house one
/// (UI_UX.md §1) — enforced here by construction.

final class HumanPersonaNamesProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// The human may only be a custom/imported persona, never a house one
  /// (UI_UX.md §1) — enforced here by construction.
  const HumanPersonaNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'humanPersonaNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$humanPersonaNamesHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return humanPersonaNames(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$humanPersonaNamesHash() => r'd008c2f1858eb87e0021780c7924e33e66783f61';

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
    r'46ce80356769e3cca6ecade4185bade966fc86bc';

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
