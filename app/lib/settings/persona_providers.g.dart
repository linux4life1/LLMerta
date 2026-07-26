// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persona_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(personaRows)
const personaRowsProvider = PersonaRowsProvider._();

final class PersonaRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomPersona>>,
          List<CustomPersona>,
          Stream<List<CustomPersona>>
        >
    with
        $FutureModifier<List<CustomPersona>>,
        $StreamProvider<List<CustomPersona>> {
  const PersonaRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personaRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personaRowsHash();

  @$internal
  @override
  $StreamProviderElement<List<CustomPersona>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CustomPersona>> create(Ref ref) {
    return personaRows(ref);
  }
}

String _$personaRowsHash() => r'b742b6971849dfbd5aa911aebf574d788a02a74f';

@ProviderFor(fpaCharacterDir)
const fpaCharacterDirProvider = FpaCharacterDirProvider._();

final class FpaCharacterDirProvider
    extends $FunctionalProvider<Directory?, Directory?, Directory?>
    with $Provider<Directory?> {
  const FpaCharacterDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fpaCharacterDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fpaCharacterDirHash();

  @$internal
  @override
  $ProviderElement<Directory?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Directory? create(Ref ref) {
    return fpaCharacterDir(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Directory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Directory?>(value),
    );
  }
}

String _$fpaCharacterDirHash() => r'2c515312d1788151badf144c8433bd81b302fe60';

/// Seam for tests: the real picker is a platform channel.

@ProviderFor(cardFilePicker)
const cardFilePickerProvider = CardFilePickerProvider._();

/// Seam for tests: the real picker is a platform channel.

final class CardFilePickerProvider
    extends
        $FunctionalProvider<
          Future<String?> Function(),
          Future<String?> Function(),
          Future<String?> Function()
        >
    with $Provider<Future<String?> Function()> {
  /// Seam for tests: the real picker is a platform channel.
  const CardFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardFilePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardFilePickerHash();

  @$internal
  @override
  $ProviderElement<Future<String?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<String?> Function() create(Ref ref) {
    return cardFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<String?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<String?> Function()>(value),
    );
  }
}

String _$cardFilePickerHash() => r'd6d9606456924e49ab0c31dd711e6f4aed0c5313';

@ProviderFor(PersonaImporter)
const personaImporterProvider = PersonaImporterProvider._();

final class PersonaImporterProvider
    extends $NotifierProvider<PersonaImporter, AsyncValue<int>?> {
  const PersonaImporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personaImporterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personaImporterHash();

  @$internal
  @override
  PersonaImporter create() => PersonaImporter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int>?>(value),
    );
  }
}

String _$personaImporterHash() => r'8cd46a796d0de0716d0e00e062e9774565103c60';

abstract class _$PersonaImporter extends $Notifier<AsyncValue<int>?> {
  AsyncValue<int>? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<int>?, AsyncValue<int>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>?, AsyncValue<int>?>,
              AsyncValue<int>?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
