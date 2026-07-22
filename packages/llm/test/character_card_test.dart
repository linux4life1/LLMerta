import 'dart:convert';
import 'dart:io';

import 'package:llm/llm.dart';
import 'package:test/test.dart';

final v2Card = {
  'spec': 'chara_card_v2',
  'spec_version': '2.0',
  'data': {
    'name': 'Seraphina Nightwhisper',
    'description':
        'A wandering herbalist who trades remedies for secrets. ${'x' * 400}',
    'personality': 'gentle, observant, quietly ruthless when crossed',
    'scenario': 'has just arrived in a town that distrusts outsiders',
    'mes_example':
        '<START>{{user}}: Who are you?\n{{char}}: *smiles faintly* '
        'Names are just another thing people trade, dear.',
    'first_mes': 'fallback only',
  },
};

List<int> pngWithChara(String base64Payload) {
  final data = <int>[...'chara'.codeUnits, 0, ...base64Payload.codeUnits];
  return [
    137, 80, 78, 71, 13, 10, 26, 10,
    // tEXt chunk
    (data.length >> 24) & 255, (data.length >> 16) & 255,
    (data.length >> 8) & 255, data.length & 255,
    ...'tEXt'.codeUnits, ...data, 0, 0, 0, 0,
    // IEND
    0, 0, 0, 0, ...'IEND'.codeUnits, 0, 0, 0, 0,
  ];
}

void main() {
  fpaDetectTests();
  test('v2 envelope maps to a persona with clamped prose', () {
    final p = personaFromCardJson(v2Card)!;
    expect(p.name, 'Seraphina');
    expect(p.archetype, startsWith('A wandering herbalist'));
    expect(p.archetype.length, lessThanOrEqualTo(221));
    expect(p.style, contains('quietly ruthless'));
    expect(p.quirk, contains('distrusts outsiders'));
    expect(p.voiceSample, contains('Names are just another thing'));
    expect(p.voiceSample, contains('Seraphina Nightwhisper:'));
    expect(p.voiceSample, isNot(contains('{{char}}')));
    expect(p.voiceSample, isNot(contains('<START>')));
  });

  test('voice sample reaches the persona prompt block', () {
    final p = personaFromCardJson(v2Card)!;
    expect(p.promptBlock, contains('how you actually talk'));
    expect(p.promptBlock, contains('Names are just another thing'));
    final plain = personaFromCardJson({
      'name': 'Rook',
      'description': 'locksmith',
    })!;
    expect(plain.promptBlock, isNot(contains('how you actually talk')));
  });

  test('v1 flat card falls back and empty name rejects', () {
    final p = personaFromCardJson({
      'name': 'Rook',
      'description': 'an ex-con locksmith',
      'personality': 'terse',
    })!;
    expect(p.name, 'Rook');
    expect(personaFromCardJson({'description': 'nameless'}), isNull);
  });

  test('extracts chara payload from a PNG tEXt chunk', () {
    final payload = base64Encode(utf8.encode(jsonEncode(v2Card)));
    final extracted = extractPngTextChunk(pngWithChara(payload), 'chara');
    expect(extracted, payload);
    expect(extractPngTextChunk([1, 2, 3], 'chara'), isNull);
  });

  test('directory loader reads json and png cards', () {
    final dir = Directory.systemTemp.createTempSync('cards');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a_card.json').writeAsStringSync(jsonEncode(v2Card));
    File('${dir.path}/b_card.png').writeAsBytesSync(
      pngWithChara(
        base64Encode(
          utf8.encode(jsonEncode({'name': 'Rook', 'description': 'locksmith'})),
        ),
      ),
    );
    File('${dir.path}/notes.txt').writeAsStringSync('ignored');
    final personas = personasFromCardDir(dir);
    expect(personas.map((p) => p.name), ['Seraphina', 'Rook']);
    expect(personas.first.avatarPath, isNull);
    expect(personas.last.avatarPath, endsWith('b_card.png'));
  });
}

void fpaDetectTests() {
  test('detects an FPA character library under Documents', () {
    final home = Directory.systemTemp.createTempSync('fakehome');
    addTearDown(() => home.deleteSync(recursive: true));
    expect(detectFpaCharacterDir(homeOverride: home.path), isNull);
    final chars = Directory(
      '${home.path}/Documents/FrontPorchAI/KoboldManager/Characters',
    )..createSync(recursive: true);
    expect(detectFpaCharacterDir(homeOverride: home.path)!.path, chars.path);
  });
}
