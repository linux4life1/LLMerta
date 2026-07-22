// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fpaBackgroundsDir)
const fpaBackgroundsDirProvider = FpaBackgroundsDirProvider._();

final class FpaBackgroundsDirProvider
    extends $FunctionalProvider<Directory?, Directory?, Directory?>
    with $Provider<Directory?> {
  const FpaBackgroundsDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fpaBackgroundsDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fpaBackgroundsDirHash();

  @$internal
  @override
  $ProviderElement<Directory?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Directory? create(Ref ref) {
    return fpaBackgroundsDir(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Directory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Directory?>(value),
    );
  }
}

String _$fpaBackgroundsDirHash() => r'536c1815a18ad923db04d0676b414338737887a9';

@ProviderFor(fpaBackgrounds)
const fpaBackgroundsProvider = FpaBackgroundsProvider._();

final class FpaBackgroundsProvider
    extends
        $FunctionalProvider<List<FileScene>, List<FileScene>, List<FileScene>>
    with $Provider<List<FileScene>> {
  const FpaBackgroundsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fpaBackgroundsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fpaBackgroundsHash();

  @$internal
  @override
  $ProviderElement<List<FileScene>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FileScene> create(Ref ref) {
    return fpaBackgrounds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FileScene> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FileScene>>(value),
    );
  }
}

String _$fpaBackgroundsHash() => r'104d787a05f085056bd97fa6e9d1d688666cea8c';

/// Seam for tests: the real picker is a platform channel.

@ProviderFor(sceneFilePicker)
const sceneFilePickerProvider = SceneFilePickerProvider._();

/// Seam for tests: the real picker is a platform channel.

final class SceneFilePickerProvider
    extends
        $FunctionalProvider<
          Future<String?> Function(),
          Future<String?> Function(),
          Future<String?> Function()
        >
    with $Provider<Future<String?> Function()> {
  /// Seam for tests: the real picker is a platform channel.
  const SceneFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sceneFilePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sceneFilePickerHash();

  @$internal
  @override
  $ProviderElement<Future<String?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<String?> Function() create(Ref ref) {
    return sceneFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<String?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<String?> Function()>(value),
    );
  }
}

String _$sceneFilePickerHash() => r'c2e0ff1ad3d3d57fc4345883a3a5114be4a681f0';
