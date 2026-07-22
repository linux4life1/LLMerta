// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectionRows)
const connectionRowsProvider = ConnectionRowsProvider._();

final class ConnectionRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Connection>>,
          List<Connection>,
          Stream<List<Connection>>
        >
    with $FutureModifier<List<Connection>>, $StreamProvider<List<Connection>> {
  const ConnectionRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionRowsHash();

  @$internal
  @override
  $StreamProviderElement<List<Connection>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Connection>> create(Ref ref) {
    return connectionRows(ref);
  }
}

String _$connectionRowsHash() => r'18faad1415d67e5e164b99ecb92145f221ebf9bf';

@ProviderFor(connectionModels)
const connectionModelsProvider = ConnectionModelsFamily._();

final class ConnectionModelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  const ConnectionModelsProvider._({
    required ConnectionModelsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'connectionModelsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectionModelsHash();

  @override
  String toString() {
    return r'connectionModelsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return connectionModels(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionModelsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectionModelsHash() => r'80cd4f1b80d3e0b4c293afb70b59527a13c5e969';

final class ConnectionModelsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<String>>, String> {
  const ConnectionModelsFamily._()
    : super(
        retry: null,
        name: r'connectionModelsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConnectionModelsProvider call(String connectionId) =>
      ConnectionModelsProvider._(argument: connectionId, from: this);

  @override
  String toString() => r'connectionModelsProvider';
}

/// Test = fetch the live model list; success doubles as the cache refresh.

@ProviderFor(ConnectionTest)
const connectionTestProvider = ConnectionTestFamily._();

/// Test = fetch the live model list; success doubles as the cache refresh.
final class ConnectionTestProvider
    extends $NotifierProvider<ConnectionTest, AsyncValue<int>?> {
  /// Test = fetch the live model list; success doubles as the cache refresh.
  const ConnectionTestProvider._({
    required ConnectionTestFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'connectionTestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectionTestHash();

  @override
  String toString() {
    return r'connectionTestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConnectionTest create() => ConnectionTest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionTestProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectionTestHash() => r'2b78a36e895f8ecff8caf506246fd80680fe9e49';

/// Test = fetch the live model list; success doubles as the cache refresh.

final class ConnectionTestFamily extends $Family
    with
        $ClassFamilyOverride<
          ConnectionTest,
          AsyncValue<int>?,
          AsyncValue<int>?,
          AsyncValue<int>?,
          String
        > {
  const ConnectionTestFamily._()
    : super(
        retry: null,
        name: r'connectionTestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Test = fetch the live model list; success doubles as the cache refresh.

  ConnectionTestProvider call(String connectionId) =>
      ConnectionTestProvider._(argument: connectionId, from: this);

  @override
  String toString() => r'connectionTestProvider';
}

/// Test = fetch the live model list; success doubles as the cache refresh.

abstract class _$ConnectionTest extends $Notifier<AsyncValue<int>?> {
  late final _$args = ref.$arg as String;
  String get connectionId => _$args;

  AsyncValue<int>? build(String connectionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
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

@ProviderFor(LocalScan)
const localScanProvider = LocalScanProvider._();

final class LocalScanProvider
    extends $AsyncNotifierProvider<LocalScan, List<LocalScanHit>> {
  const LocalScanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localScanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localScanHash();

  @$internal
  @override
  LocalScan create() => LocalScan();
}

String _$localScanHash() => r'2ff2ca1b43e964cf4e2ef03af9db0a7a9cbfeecb';

abstract class _$LocalScan extends $AsyncNotifier<List<LocalScanHit>> {
  FutureOr<List<LocalScanHit>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<LocalScanHit>>, List<LocalScanHit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LocalScanHit>>, List<LocalScanHit>>,
              AsyncValue<List<LocalScanHit>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
