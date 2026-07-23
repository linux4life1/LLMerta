import 'dart:convert';

class ParseFailure implements Exception {
  ParseFailure(this.message);

  final String message;

  @override
  String toString() => 'ParseFailure: $message';
}

/// Tolerant extractor for LLM decision output (LLM_INTEGRATION.md §4):
/// strips code fences and prose, finds the first balanced JSON object,
/// and coerces seat references. Throwing [ParseFailure] (after the
/// caller's retry) hands the engine its deterministic fallback — malformed
/// output must never crash the game.
Map<String, dynamic> extractJsonObject(String raw) {
  final text = raw.replaceAll(RegExp('```[a-zA-Z]*'), '').trim();
  final start = text.indexOf('{');
  if (start < 0) throw ParseFailure('no JSON object in output');
  var depth = 0;
  var inString = false;
  for (var i = start; i < text.length; i++) {
    final c = text[i];
    if (inString) {
      if (c == r'\') {
        i++;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }
    if (c == '"') inString = true;
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) {
        final candidate = text.substring(start, i + 1);
        try {
          final decoded = jsonDecode(candidate);
          if (decoded is Map<String, dynamic>) return decoded;
          throw ParseFailure('JSON is not an object');
        } on FormatException catch (e) {
          throw ParseFailure('invalid JSON: ${e.message}');
        }
      }
    }
  }
  throw ParseFailure('unbalanced JSON object');
}

/// Reads a seat choice from [json]. Accepts ints, numeric strings, seat
/// names (fuzzy, case-insensitive), and null/"pass"/"abstain"/"hold"/"none"
/// for no choice. Numbers are the PUBLIC 1-based seat numbers agents see
/// in every prompt; the returned value is the 0-based engine index and
/// must be in [legal] (or null when [allowNone]).
int? parseSeatChoice(
  Map<String, dynamic> json,
  String key, {
  required List<int> legal,
  required List<String> names,
  required bool allowNone,
}) {
  final value = json[key];
  int? seat;
  switch (value) {
    case null:
      seat = null;
    case final int i:
      seat = i - 1;
    case final num d:
      seat = d.toInt() - 1;
    case final String s:
      final t = s.trim().toLowerCase();
      if (t.isEmpty ||
          const {
            'pass',
            'abstain',
            'hold',
            'none',
            'null',
            'no one',
          }.contains(t)) {
        seat = null;
      } else {
        final numeric = int.tryParse(t.replaceFirst(RegExp(r'^seat\s*'), ''));
        seat = numeric == null ? _seatByName(t, names) : numeric - 1;
        if (seat == null) throw ParseFailure('unrecognized target "$s"');
      }
    default:
      throw ParseFailure('field "$key" has type ${value.runtimeType}');
  }
  if (seat == null) {
    if (allowNone) return null;
    throw ParseFailure('field "$key" requires a target');
  }
  // The retry message goes back to the model: speak its 1-based dialect.
  if (!legal.contains(seat)) {
    throw ParseFailure('seat ${seat + 1} is not a legal target');
  }
  return seat;
}

int? _seatByName(String needle, List<String> names) {
  for (var s = 0; s < names.length; s++) {
    if (names[s].toLowerCase() == needle) return s;
  }
  for (var s = 0; s < names.length; s++) {
    if (needle.contains(names[s].toLowerCase())) return s;
  }
  return null;
}
