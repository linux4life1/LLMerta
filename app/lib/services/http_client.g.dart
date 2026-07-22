// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared plain HTTP client (local-server scans, update checks) — one
/// override point for tests.

@ProviderFor(scanHttpClient)
const scanHttpClientProvider = ScanHttpClientProvider._();

/// Shared plain HTTP client (local-server scans, update checks) — one
/// override point for tests.

final class ScanHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// Shared plain HTTP client (local-server scans, update checks) — one
  /// override point for tests.
  const ScanHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return scanHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$scanHttpClientHash() => r'93fde4aa5a8f89d7a5245ec16bbc54a7d49e20bf';
