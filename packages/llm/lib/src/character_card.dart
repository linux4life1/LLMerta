import 'dart:convert';
import 'dart:io';

import 'personas.dart';

/// Imports v2 character cards (the Front Porch AI / SillyTavern ecosystem
/// format) as Mafia personas — same envelope and PNG embedding FPA's
/// v2_card_service and png_metadata_utils handle: JSON files, or PNGs with
/// a base64 `chara` tEXt chunk. Card prose is clamped hard: a persona is
/// table flavor, not a 2000-token biography.
/// Card basename without extension — matches FPA `stableGroupId`.
String? fpaCharacterIdFromPath(String? path) {
  if (path == null || path.isEmpty) return null;
  final slash = path.replaceAll('\\', '/');
  final base = slash.contains('/') ? slash.split('/').last : slash;
  if (base.isEmpty) return null;
  final dot = base.lastIndexOf('.');
  final id = dot > 0 ? base.substring(0, dot) : base;
  return id.isEmpty ? null : id;
}

Persona? personaFromCardJson(
  Map<String, dynamic> json, {
  String? avatarPath,
  String? fpaCharacterId,
}) {
  final data = json['spec'] == 'chara_card_v2'
      ? (json['data'] as Map<String, dynamic>? ?? const {})
      : json;
  final name = (data['name'] as String? ?? '').trim();
  if (name.isEmpty) return null;
  final description = _clamp(
    _stripCardMacros(data['description'] as String? ?? '', name),
    220,
  );
  final personality = _clamp(
    _stripCardMacros(data['personality'] as String? ?? '', name),
    160,
  );
  final scenario = _clamp(
    _stripCardMacros(data['scenario'] as String? ?? '', name),
    120,
  );
  final sampleSource = [
    data['mes_example'] as String? ?? '',
    data['first_mes'] as String? ?? '',
  ].firstWhere((t) => t.trim().isNotEmpty, orElse: () => '');
  final voice = _clamp(_stripCardMacros(sampleSource, name), 350);
  return Persona(
    name: _firstWord(name),
    avatarPath: avatarPath,
    fpaCharacterId:
        fpaCharacterId ?? fpaCharacterIdFromPath(avatarPath),
    archetype: description.isEmpty
        ? 'a mysterious newcomer in town'
        : description,
    style: personality.isEmpty ? 'true to their card' : personality,
    quirk: scenario.isEmpty
        ? 'carries a story nobody here knows yet'
        : scenario,
    voiceSample: voice.isEmpty ? null : voice,
  );
}

Persona? personaFromCardFile(File file) {
  try {
    final id = fpaCharacterIdFromPath(file.path);
    final path = file.path.toLowerCase();
    if (path.endsWith('.json')) {
      return personaFromCardJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        fpaCharacterId: id,
      );
    }
    if (path.endsWith('.png')) {
      final chara = extractPngTextChunk(file.readAsBytesSync(), 'chara');
      if (chara == null) return null;
      return personaFromCardJson(
        jsonDecode(utf8.decode(base64Decode(chara.trim())))
            as Map<String, dynamic>,
        avatarPath: file.path,
        fpaCharacterId: id,
      );
    }
  } on Object {
    return null;
  }
  return null;
}

/// Walks PNG tEXt chunks for [keyword] — the layout FPA's
/// png_metadata_utils reads; CRCs are not validated, matching FPA.
String? extractPngTextChunk(List<int> bytes, String keyword) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 8) return null;
  for (var i = 0; i < 8; i++) {
    if (bytes[i] != signature[i]) return null;
  }
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) return null;
    if (type == 'tEXt') {
      final data = bytes.sublist(dataStart, dataEnd);
      final sep = data.indexOf(0);
      if (sep > 0 && String.fromCharCodes(data.sublist(0, sep)) == keyword) {
        return String.fromCharCodes(data.sublist(sep + 1));
      }
    }
    offset = dataEnd + 4;
  }
  return null;
}

/// Locates a local Front Porch AI character library (the KoboldManager
/// Characters folder of PNG cards) so the lobby can offer one-click
/// import. Checks the platform Documents locations FPA uses.
Directory? detectFpaCharacterDir({String? homeOverride}) {
  final home =
      homeOverride ??
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '';
  if (home.isEmpty) return null;
  for (final candidate in [
    '$home/Documents/FrontPorchAI/KoboldManager/Characters',
    '$home/FrontPorchAI/KoboldManager/Characters',
  ]) {
    final dir = Directory(candidate);
    if (dir.existsSync()) return dir;
  }
  return null;
}

/// Loads every card in [dir] (.json / .png), sorted by filename.
List<Persona> personasFromCardDir(Directory dir) {
  final files = dir.listSync().whereType<File>().where((f) {
    final p = f.path.toLowerCase();
    return p.endsWith('.json') || p.endsWith('.png');
  }).toList()..sort((a, b) => a.path.compareTo(b.path));
  final seen = <String>{};
  return [
    for (final file in files)
      if (personaFromCardFile(file) case final Persona persona)
        if (seen.add(persona.name)) persona,
  ];
}

String _clamp(String text, int max) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.length <= max) return clean;
  final cut = clean.substring(0, max);
  final lastSpace = cut.lastIndexOf(' ');
  return '${cut.substring(0, lastSpace > max ~/ 2 ? lastSpace : max)}…';
}

/// Cards speak in {{char}}/{{user}} macros and often open with a
/// "{{char}}: ..." script line; normalize to plain prose.
String _stripCardMacros(String text, String name) => text
    .replaceAll('{{char}}', name)
    .replaceAll('{{user}}', 'someone')
    .replaceAll(RegExp('<START>', caseSensitive: false), ' ')
    .trim();

String _firstWord(String name) {
  final word = name
      .split(RegExp(r'\s+'))
      .first
      .replaceAll(RegExp(r'[^\p{L}\p{N}\-]', unicode: true), '');
  return word.length <= 20 ? word : word.substring(0, 20);
}
