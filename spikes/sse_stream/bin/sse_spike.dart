// M0 spike 1: prove hand-rolled SSE over package:http against an
// OpenAI-compatible /v1/chat/completions stream (oMLX on this machine).
// Pass = tokens arrive incrementally (multiple chunks over time), keepalive
// comment lines are tolerated, and the stream terminates on [DONE].
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const defaultBase = 'http://127.0.0.1:8000/v1';
const defaultModel = 'GLM-4.7-Flash-MLX-8bit';

Future<int> main(List<String> args) async {
  final base = args.isNotEmpty ? args[0] : defaultBase;
  final model = args.length > 1 ? args[1] : defaultModel;
  final client = http.Client();
  final sw = Stopwatch()..start();
  int? firstTokenMs;
  var chunkCount = 0;
  var eventCount = 0;
  final eventTimes = <int>[];
  var keepaliveCount = 0;
  var sawDone = false;
  final text = StringBuffer();

  try {
    final req = http.Request('POST', Uri.parse('$base/chat/completions'))
      ..headers['content-type'] = 'application/json'
      ..headers['accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'max_tokens': 512,
        'messages': [
          {
            'role': 'user',
            'content': 'Reply with one short sentence about the game Mafia.',
          },
        ],
      });
    final res = await client.send(req).timeout(const Duration(seconds: 120));
    if (res.statusCode != 200) {
      stderr.writeln('FAIL: HTTP ${res.statusCode}');
      stderr.writeln(await res.stream.bytesToString());
      return 1;
    }

    // Hand-rolled SSE: split the byte stream into lines, group into events at
    // blank lines, concatenate multi-line `data:` fields per the SSE spec.
    final dataLines = <String>[];
    await for (final line
        in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (dataLines.isEmpty) continue;
        final data = dataLines.join('\n');
        dataLines.clear();
        if (data == '[DONE]') {
          sawDone = true;
          break;
        }
        eventCount++;
        eventTimes.add(sw.elapsedMilliseconds);
        final json = jsonDecode(data) as Map<String, dynamic>;
        // oMLX keepalive mode "chunk" sends chunk events with model=keepalive
        // and empty content instead of SSE comment lines.
        if (json['model'] == 'keepalive') {
          keepaliveCount++;
          continue;
        }
        final choices =
            (json['choices'] as List?)?.cast<Map<String, dynamic>>();
        final delta = choices?.firstOrNull?['delta'] as Map<String, dynamic>?;
        // Thinking models stream via reasoning_content before content.
        final reasoning = delta?['reasoning_content'] as String?;
        final content = delta?['content'] as String?;
        if (reasoning != null && reasoning.isNotEmpty) {
          firstTokenMs ??= sw.elapsedMilliseconds;
          chunkCount++;
        }
        if (content != null && content.isNotEmpty) {
          firstTokenMs ??= sw.elapsedMilliseconds;
          chunkCount++;
          text.write(content);
          stdout.write(content);
        }
      } else if (line.startsWith(':')) {
        keepaliveCount++; // SSE comment, used as keepalive by some servers
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      } // other SSE fields (event:, id:, retry:) are irrelevant here
    }
  } on TimeoutException {
    stderr.writeln('FAIL: timed out');
    return 1;
  } finally {
    client.close();
  }

  stdout.writeln();
  final total = sw.elapsedMilliseconds;
  stdout
    ..writeln('--- spike result ---')
    ..writeln('events: $eventCount, content chunks: $chunkCount, '
        'keepalives: $keepaliveCount, ttft: ${firstTokenMs}ms, '
        'total: ${total}ms, done: $sawDone')
    ..writeln('event arrival ms: ${eventTimes.take(30).toList()}'
        '${eventTimes.length > 30 ? ' …' : ''}')
    ..writeln('text: "$text"');
  final first = firstTokenMs;
  final incremental = chunkCount >= 3 && first != null && first < total;
  stdout.writeln(incremental && sawDone ? 'PASS' : 'FAIL');
  return incremental && sawDone ? 0 : 1;
}
