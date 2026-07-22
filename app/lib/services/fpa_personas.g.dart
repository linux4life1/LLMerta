// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fpa_personas.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fpaPersonaDbPath)
const fpaPersonaDbPathProvider = FpaPersonaDbPathProvider._();

final class FpaPersonaDbPathProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  const FpaPersonaDbPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fpaPersonaDbPathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fpaPersonaDbPathHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return fpaPersonaDbPath(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$fpaPersonaDbPathHash() => r'8ec206be176db03165f5fd060b71e00c7199b56f';

@ProviderFor(fpaPersonas)
const fpaPersonasProvider = FpaPersonasProvider._();

final class FpaPersonasProvider
    extends
        $FunctionalProvider<List<FpPersona>, List<FpPersona>, List<FpPersona>>
    with $Provider<List<FpPersona>> {
  const FpaPersonasProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fpaPersonasProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fpaPersonasHash();

  @$internal
  @override
  $ProviderElement<List<FpPersona>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FpPersona> create(Ref ref) {
    return fpaPersonas(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FpPersona> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FpPersona>>(value),
    );
  }
}

String _$fpaPersonasHash() => r'1b89f0c5b6cce6c060b5d75100acdfa3d4a150c0';
