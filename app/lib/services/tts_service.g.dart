// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tts_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TtsEnabled)
const ttsEnabledProvider = TtsEnabledProvider._();

final class TtsEnabledProvider extends $NotifierProvider<TtsEnabled, bool> {
  const TtsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ttsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ttsEnabledHash();

  @$internal
  @override
  TtsEnabled create() => TtsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$ttsEnabledHash() => r'15b7df8c8cb1245a53034687c011c869bc07a6a7';

abstract class _$TtsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(kokoroBundle)
const kokoroBundleProvider = KokoroBundleProvider._();

final class KokoroBundleProvider
    extends $FunctionalProvider<VoiceBundle?, VoiceBundle?, VoiceBundle?>
    with $Provider<VoiceBundle?> {
  const KokoroBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kokoroBundleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kokoroBundleHash();

  @$internal
  @override
  $ProviderElement<VoiceBundle?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoiceBundle? create(Ref ref) {
    return kokoroBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceBundle? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceBundle?>(value),
    );
  }
}

String _$kokoroBundleHash() => r'ad885d6def1cf7a2afa725dd35da338e89d279b7';

@ProviderFor(piperBundle)
const piperBundleProvider = PiperBundleProvider._();

final class PiperBundleProvider
    extends $FunctionalProvider<VoiceBundle?, VoiceBundle?, VoiceBundle?>
    with $Provider<VoiceBundle?> {
  const PiperBundleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'piperBundleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$piperBundleHash();

  @$internal
  @override
  $ProviderElement<VoiceBundle?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoiceBundle? create(Ref ref) {
    return piperBundle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceBundle? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceBundle?>(value),
    );
  }
}

String _$piperBundleHash() => r'7727eea1acbce7475d05ea5e9d860ff750957083';

@ProviderFor(voiceDownloader)
const voiceDownloaderProvider = VoiceDownloaderProvider._();

final class VoiceDownloaderProvider
    extends
        $FunctionalProvider<VoiceDownloader, VoiceDownloader, VoiceDownloader>
    with $Provider<VoiceDownloader> {
  const VoiceDownloaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceDownloaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceDownloaderHash();

  @$internal
  @override
  $ProviderElement<VoiceDownloader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoiceDownloader create(Ref ref) {
    return voiceDownloader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceDownloader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceDownloader>(value),
    );
  }
}

String _$voiceDownloaderHash() => r'e12a27793f1506461a6b749cc847ae2db3eb6bda';

/// Kokoro (many speakers) preferred, Piper as the single-voice fallback;
/// null when no valid bundle is on disk — the app stays fully silent-safe.

@ProviderFor(ttsStack)
const ttsStackProvider = TtsStackProvider._();

/// Kokoro (many speakers) preferred, Piper as the single-voice fallback;
/// null when no valid bundle is on disk — the app stays fully silent-safe.

final class TtsStackProvider
    extends $FunctionalProvider<TtsStack?, TtsStack?, TtsStack?>
    with $Provider<TtsStack?> {
  /// Kokoro (many speakers) preferred, Piper as the single-voice fallback;
  /// null when no valid bundle is on disk — the app stays fully silent-safe.
  const TtsStackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ttsStackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ttsStackHash();

  @$internal
  @override
  $ProviderElement<TtsStack?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TtsStack? create(Ref ref) {
    return ttsStack(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TtsStack? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TtsStack?>(value),
    );
  }
}

String _$ttsStackHash() => r'94678b76c3bd902b02d67a08ecfe885cad3459e0';

/// Bridges session events into the speech queue: seat voices for
/// speeches, the narrator voice for dawn/verdict/game-end lines.

@ProviderFor(TtsDirector)
const ttsDirectorProvider = TtsDirectorProvider._();

/// Bridges session events into the speech queue: seat voices for
/// speeches, the narrator voice for dawn/verdict/game-end lines.
final class TtsDirectorProvider extends $NotifierProvider<TtsDirector, int> {
  /// Bridges session events into the speech queue: seat voices for
  /// speeches, the narrator voice for dawn/verdict/game-end lines.
  const TtsDirectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ttsDirectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ttsDirectorHash();

  @$internal
  @override
  TtsDirector create() => TtsDirector();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$ttsDirectorHash() => r'0008a92c39954241764efcb0c338234a48d6d711';

/// Bridges session events into the speech queue: seat voices for
/// speeches, the narrator voice for dawn/verdict/game-end lines.

abstract class _$TtsDirector extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
