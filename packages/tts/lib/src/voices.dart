import 'dart:io';

/// A playable voice: a validated model bundle plus a speaker id (Kokoro
/// bundles carry many speakers; Piper voices carry one).
class Voice {
  const Voice({required this.bundle, this.speakerId = 0, String? label})
    : _label = label;

  final VoiceBundle bundle;
  final int speakerId;
  final String? _label;

  String get label => _label ?? '${bundle.kind.name} #$speakerId';

  String get cacheKey => '${bundle.dir.path}#$speakerId';
}

enum VoiceBundleKind { piper, kokoro }

class VoiceBundle {
  const VoiceBundle({required this.kind, required this.dir});

  final VoiceBundleKind kind;
  final Directory dir;
}

/// Validation before any native load: sherpa hard-crashes on the legacy
/// npz-format Kokoro files some Front Porch AI installs keep in
/// Application Support — only the sherpa-v1_0 bundle layout is accepted.
String? validatePiperDir(Directory dir) {
  if (!dir.existsSync()) return 'missing directory ${dir.path}';
  final hasModel = dir.listSync().whereType<File>().any(
    (f) => f.path.endsWith('.onnx'),
  );
  if (!hasModel) return 'no .onnx model in ${dir.path}';
  if (!File('${dir.path}/tokens.txt').existsSync()) return 'missing tokens.txt';
  if (!Directory('${dir.path}/espeak-ng-data').existsSync()) {
    return 'missing espeak-ng-data/';
  }
  return null;
}

String? validateKokoroDir(Directory dir) {
  if (!dir.existsSync()) return 'missing directory ${dir.path}';
  final entries = dir.listSync().whereType<File>();
  if (entries.any((f) => f.path.endsWith('.npz'))) {
    return 'legacy npz-format Kokoro files — sherpa needs the '
        'sherpa-v1_0 bundle (model.onnx + voices.bin), not these';
  }
  for (final required in ['model.onnx', 'voices.bin', 'tokens.txt']) {
    if (!File('${dir.path}/$required').existsSync()) {
      return 'missing $required';
    }
  }
  if (!Directory('${dir.path}/espeak-ng-data').existsSync()) {
    return 'missing espeak-ng-data/';
  }
  return null;
}

VoiceBundle? detectPiperBundle({List<String>? candidates}) => _detect(
  VoiceBundleKind.piper,
  validatePiperDir,
  candidates ?? _piperDirs(),
);

VoiceBundle? detectKokoroBundle({List<String>? candidates}) => _detect(
  VoiceBundleKind.kokoro,
  validateKokoroDir,
  candidates ?? _kokoroDirs(),
);

VoiceBundle? _detect(
  VoiceBundleKind kind,
  String? Function(Directory) validate,
  List<String> candidates,
) {
  for (final path in candidates) {
    final dir = Directory(path);
    if (validate(dir) == null) return VoiceBundle(kind: kind, dir: dir);
  }
  return null;
}

String get _home => Platform.environment['HOME'] ?? '';

List<String> _piperDirs() => [
  '${Directory.current.path}/voices/vits-piper-en_US-lessac-medium',
  '${Directory.current.path}/../spikes/models/vits-piper-en_US-lessac-medium',
  '$_home/dev/Mafia/spikes/models/vits-piper-en_US-lessac-medium',
];

List<String> _kokoroDirs() => [
  '${Directory.current.path}/voices/kokoro-v1.0',
  '${Directory.current.path}/../spikes/models/kokoro-v1.0',
  '$_home/dev/Mafia/spikes/models/kokoro-v1.0',
  // FPA's sherpa bundle — NOT its legacy Application Support npz files.
  '$_home/Documents/FrontPorchAI/system/kokoro_models/sherpa-v1_0',
];

/// Round-robin seat casting over the available speakers; the narrator
/// gets a voice distinct from seat 0's where possible.
({Voice narrator, Map<int, Voice> bySeat}) assignVoices({
  required int seats,
  required List<Voice> available,
}) {
  assert(available.isNotEmpty);
  final bySeat = {
    for (var s = 0; s < seats; s++) s: available[s % available.length],
  };
  final narrator = available.length > 1
      ? available[available.length - 1]
      : available.first;
  return (narrator: narrator, bySeat: bySeat);
}

/// Kokoro v1.0 ships 53 speakers; a curated spread keeps neighboring
/// seats audibly distinct.
List<Voice> kokoroSpeakers(VoiceBundle bundle, {int count = 12}) => [
  for (var i = 0; i < count; i++)
    Voice(
      bundle: bundle,
      speakerId: (i * 4) % 53,
      label: 'Kokoro ${(i * 4) % 53}',
    ),
];
