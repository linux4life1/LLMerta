// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_keys.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiKeyStore)
const apiKeyStoreProvider = ApiKeyStoreProvider._();

final class ApiKeyStoreProvider
    extends $FunctionalProvider<ApiKeyStore, ApiKeyStore, ApiKeyStore>
    with $Provider<ApiKeyStore> {
  const ApiKeyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeyStoreHash();

  @$internal
  @override
  $ProviderElement<ApiKeyStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiKeyStore create(Ref ref) {
    return apiKeyStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiKeyStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiKeyStore>(value),
    );
  }
}

String _$apiKeyStoreHash() => r'b8f2afb55c01666cd314edfaddcba67675fef20f';
