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
    extends $FunctionalProvider<Directory?, Directory?, Directory?>
    with $Provider<Directory?> {
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
  $ProviderElement<Directory?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Directory? create(Ref ref) {
    return embeddingModelDir(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Directory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Directory?>(value),
    );
  }
}

String _$embeddingModelDirHash() => r'2e0385c26466565a2f708fb6ecd3eb044e8d2c2c';

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

String _$gameEmbedderHash() => r'146226de892c6de77f90c91d2f7096e372eba3c4';
