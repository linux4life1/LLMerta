// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_draft.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LobbyDraft)
const lobbyDraftProvider = LobbyDraftProvider._();

final class LobbyDraftProvider
    extends $NotifierProvider<LobbyDraft, GameConfig> {
  const LobbyDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lobbyDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lobbyDraftHash();

  @$internal
  @override
  LobbyDraft create() => LobbyDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameConfig>(value),
    );
  }
}

String _$lobbyDraftHash() => r'defaae2cb192a223afbccbcb69321a56efb0082f';

abstract class _$LobbyDraft extends $Notifier<GameConfig> {
  GameConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<GameConfig, GameConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameConfig, GameConfig>,
              GameConfig,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
