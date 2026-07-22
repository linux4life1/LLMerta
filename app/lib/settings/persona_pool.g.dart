// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persona_pool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(personaPool)
const personaPoolProvider = PersonaPoolProvider._();

final class PersonaPoolProvider
    extends $FunctionalProvider<List<Persona>, List<Persona>, List<Persona>>
    with $Provider<List<Persona>> {
  const PersonaPoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personaPoolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personaPoolHash();

  @$internal
  @override
  $ProviderElement<List<Persona>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Persona> create(Ref ref) {
    return personaPool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Persona> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Persona>>(value),
    );
  }
}

String _$personaPoolHash() => r'f6a372cde08e38af271f123d617078543b3fa586';
