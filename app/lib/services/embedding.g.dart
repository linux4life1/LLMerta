// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(embeddingModelDir)
const embeddingModelDirProvider = EmbeddingModelDirProvider._();

final class EmbeddingModelDirProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory?>,
          Directory?,
          FutureOr<Directory?>
        >
    with $FutureModifier<Directory?>, $FutureProvider<Directory?> {
  const EmbeddingModelDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'embeddingModelDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$embeddingModelDirHash();

  @$internal
  @override
  $FutureProviderElement<Directory?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory?> create(Ref ref) {
    return embeddingModelDir(ref);
  }
}

String _$embeddingModelDirHash() => r'ef39fd2b5dc4fb72a3857c0ebedce2fd869005f1';

@ProviderFor(gameEmbedder)
const gameEmbedderProvider = GameEmbedderProvider._();

final class GameEmbedderProvider
    extends $FunctionalProvider<Embedder, Embedder, Embedder>
    with $Provider<Embedder> {
  const GameEmbedderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameEmbedderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameEmbedderHash();

  @$internal
  @override
  $ProviderElement<Embedder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Embedder create(Ref ref) {
    return gameEmbedder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Embedder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Embedder>(value),
    );
  }
}

String _$gameEmbedderHash() => r'c7c50fba6f8a8d684b2a12bdc3ea58bf87bec3ab';
