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

/// Voices live only in the app's own support folder — downloaded by the
/// app, never scavenged from other apps or dev checkouts.

@ProviderFor(voicesDir)
const voicesDirProvider = VoicesDirProvider._();

/// Voices live only in the app's own support folder — downloaded by the
/// app, never scavenged from other apps or dev checkouts.

final class VoicesDirProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// Voices live only in the app's own support folder — downloaded by the
  /// app, never scavenged from other apps or dev checkouts.
  const VoicesDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voicesDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voicesDirHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return voicesDir(ref);
  }
}

String _$voicesDirHash() => r'f17ab2cc0d90d91379368878ff03ab0a0dd89c7f';

@ProviderFor(kokoroBundle)
const kokoroBundleProvider = KokoroBundleProvider._();

final class KokoroBundleProvider
    extends
        $FunctionalProvider<
          AsyncValue<VoiceBundle?>,
          VoiceBundle?,
          FutureOr<VoiceBundle?>
        >
    with $FutureModifier<VoiceBundle?>, $FutureProvider<VoiceBundle?> {
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
  $FutureProviderElement<VoiceBundle?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VoiceBundle?> create(Ref ref) {
    return kokoroBundle(ref);
  }
}

String _$kokoroBundleHash() => r'df311a8aa3e758123a1598988cfc15e0c28c0341';

@ProviderFor(piperBundle)
const piperBundleProvider = PiperBundleProvider._();

final class PiperBundleProvider
    extends
        $FunctionalProvider<
          AsyncValue<VoiceBundle?>,
          VoiceBundle?,
          FutureOr<VoiceBundle?>
        >
    with $FutureModifier<VoiceBundle?>, $FutureProvider<VoiceBundle?> {
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
  $FutureProviderElement<VoiceBundle?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VoiceBundle?> create(Ref ref) {
    return piperBundle(ref);
  }
}

String _$piperBundleHash() => r'7427740eb15bbabe6cf79b4adf489c8075dbe6d7';

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

String _$ttsStackHash() => r'b17f6eec76aad3d2e4de81c51ba156470e7dd1dc';

/// What the queue is voicing right now: (text, startedAt, audioLength).
/// The center stage reveals words across the duration so text tracks the
/// spoken line.

@ProviderFor(NowSpeaking)
const nowSpeakingProvider = NowSpeakingProvider._();

/// What the queue is voicing right now: (text, startedAt, audioLength).
/// The center stage reveals words across the duration so text tracks the
/// spoken line.
final class NowSpeakingProvider
    extends $NotifierProvider<NowSpeaking, (String, DateTime, Duration)?> {
  /// What the queue is voicing right now: (text, startedAt, audioLength).
  /// The center stage reveals words across the duration so text tracks the
  /// spoken line.
  const NowSpeakingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowSpeakingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowSpeakingHash();

  @$internal
  @override
  NowSpeaking create() => NowSpeaking();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue((String, DateTime, Duration)? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<(String, DateTime, Duration)?>(
        value,
      ),
    );
  }
}

String _$nowSpeakingHash() => r'91982f220cffc9dfaa51aabe84960dbcf060cd0d';

/// What the queue is voicing right now: (text, startedAt, audioLength).
/// The center stage reveals words across the duration so text tracks the
/// spoken line.

abstract class _$NowSpeaking extends $Notifier<(String, DateTime, Duration)?> {
  (String, DateTime, Duration)? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              (String, DateTime, Duration)?,
              (String, DateTime, Duration)?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                (String, DateTime, Duration)?,
                (String, DateTime, Duration)?
              >,
              (String, DateTime, Duration)?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

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

String _$ttsDirectorHash() => r'7cec94386cf1998ee32b1fbf42c6f6f60a0d4127';

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
