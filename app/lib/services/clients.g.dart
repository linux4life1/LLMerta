// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clientFactory)
const clientFactoryProvider = ClientFactoryProvider._();

final class ClientFactoryProvider
    extends $FunctionalProvider<ClientFactory, ClientFactory, ClientFactory>
    with $Provider<ClientFactory> {
  const ClientFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientFactoryHash();

  @$internal
  @override
  $ProviderElement<ClientFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClientFactory create(Ref ref) {
    return clientFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientFactory>(value),
    );
  }
}

String _$clientFactoryHash() => r'c94222ab137cb9d99f4c9a2067b9946133905a26';
