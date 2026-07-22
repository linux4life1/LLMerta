// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// FPA-precedent self-updater, single stable channel: GitHub Releases
/// check → streamed download → sidecar install on restart.

@ProviderFor(UpdateController)
const updateControllerProvider = UpdateControllerProvider._();

/// FPA-precedent self-updater, single stable channel: GitHub Releases
/// check → streamed download → sidecar install on restart.
final class UpdateControllerProvider
    extends $NotifierProvider<UpdateController, UpdateState> {
  /// FPA-precedent self-updater, single stable channel: GitHub Releases
  /// check → streamed download → sidecar install on restart.
  const UpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateControllerHash();

  @$internal
  @override
  UpdateController create() => UpdateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateState>(value),
    );
  }
}

String _$updateControllerHash() => r'b1f33d406589b87179a8702e7025249f2b54bf48';

/// FPA-precedent self-updater, single stable channel: GitHub Releases
/// check → streamed download → sidecar install on restart.

abstract class _$UpdateController extends $Notifier<UpdateState> {
  UpdateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<UpdateState, UpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateState, UpdateState>,
              UpdateState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
