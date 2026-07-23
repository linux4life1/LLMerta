import 'package:llm/llm.dart';
import 'package:test/test.dart';

void main() {
  const names = ['Alma', 'Boris', 'Clara', 'Dmitri'];

  group('extractJsonObject', () {
    test('plain object', () {
      expect(extractJsonObject('{"vote": 2}'), {'vote': 2});
    });

    test('code-fenced object with prose around it', () {
      expect(
        extractJsonObject(
          'Sure! Here is my decision:\n```json\n{"vote": 2}\n```\nGood luck!',
        ),
        {'vote': 2},
      );
    });

    test('reasoning preamble with braces inside strings', () {
      expect(
        extractJsonObject(
          'thinking... {"reason": "he said \\"{hi}\\"", "kill": 1}',
        ),
        {'reason': 'he said "{hi}"', 'kill': 1},
      );
    });

    test('nested objects', () {
      expect(extractJsonObject('{"a": {"b": 1}, "vote": 3}')['vote'], 3);
    });

    test('picks the first of several objects', () {
      expect(extractJsonObject('{"vote": 1} {"vote": 2}'), {'vote': 1});
    });
  });

  group(
    'extractJsonObject fuzz: malformed input never escapes ParseFailure',
    () {
      const garbage = [
        '',
        'I vote for Boris.',
        '{"vote": }',
        '{"vote": 2',
        '{vote: 2}',
        '[1, 2, 3]',
        '{{{{',
        '```json\n```',
        '{"a": "unterminated string}',
        'null',
        '{,}',
      ];
      for (final raw in garbage) {
        test('rejects ${raw.isEmpty ? '<empty>' : raw}', () {
          expect(() => extractJsonObject(raw), throwsA(isA<ParseFailure>()));
        });
      }
    },
  );

  group('parseSeatChoice', () {
    test('accepts a legal int', () {
      expect(
        parseSeatChoice(
          {'vote': 3},
          'vote',
          legal: [1, 2],
          names: names,
          allowNone: true,
        ),
        2,
      );
    });

    test('accepts numeric strings and "seat N"', () {
      for (final v in ['3', 'seat 3', 'Seat 3']) {
        expect(
          parseSeatChoice(
            {'vote': v},
            'vote',
            legal: [2],
            names: names,
            allowNone: false,
          ),
          2,
        );
      }
    });

    test('matches player names case-insensitively', () {
      expect(
        parseSeatChoice(
          {'kill': 'boris'},
          'kill',
          legal: [1],
          names: names,
          allowNone: false,
        ),
        1,
      );
      expect(
        parseSeatChoice(
          {'kill': 'I choose Clara (seat 3)'},
          'kill',
          legal: [2],
          names: names,
          allowNone: false,
        ),
        2,
      );
    });

    test('null and pass words mean no choice when allowed', () {
      for (final v in [null, 'pass', 'abstain', 'HOLD', 'none', '']) {
        expect(
          parseSeatChoice(
            {'vote': v},
            'vote',
            legal: [1, 2],
            names: names,
            allowNone: true,
          ),
          isNull,
        );
      }
    });

    test('no choice rejected when a target is required', () {
      expect(
        () => parseSeatChoice(
          {'protect': null},
          'protect',
          legal: [1],
          names: names,
          allowNone: false,
        ),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('illegal seat rejected', () {
      expect(
        () => parseSeatChoice(
          {'vote': 4},
          'vote',
          legal: [1, 2],
          names: names,
          allowNone: true,
        ),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('unrecognized name and wrong type rejected', () {
      for (final v in ['Zorblax', true]) {
        expect(
          () => parseSeatChoice(
            {'vote': v},
            'vote',
            legal: [1, 2],
            names: names,
            allowNone: true,
          ),
          throwsA(isA<ParseFailure>()),
        );
      }
    });

    test('double coerces to int', () {
      expect(
        parseSeatChoice(
          {'vote': 3.0},
          'vote',
          legal: [2],
          names: names,
          allowNone: false,
        ),
        2,
      );
    });
  });
}
