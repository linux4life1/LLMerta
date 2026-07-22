import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llmerta_app/settings/settings.dart';

void main() {
  http.Client answering(Map<int, List<String>> byPort) =>
      MockClient((request) async {
        final port = request.url.port;
        final models = byPort[port];
        if (models == null) throw http.ClientException('refused');
        return http.Response(
          jsonEncode({
            'data': [
              for (final id in models) {'id': id},
            ],
          }),
          200,
        );
      });

  test('probe parses OpenAI-style model lists', () async {
    final client = answering({
      8000: ['glm-5', 'qwen-3.6'],
    });
    expect(await probeLocalServer(client, 'http://127.0.0.1:8000/v1'), [
      'glm-5',
      'qwen-3.6',
    ]);
  });

  test(
    'probe returns null for refused, non-200, and garbage answers',
    () async {
      expect(
        await probeLocalServer(
          answering(const <int, List<String>>{}),
          'http://127.0.0.1:8000/v1',
        ),
        isNull,
      );
      final teapot = MockClient((_) async => http.Response('nope', 418));
      expect(
        await probeLocalServer(teapot, 'http://127.0.0.1:8000/v1'),
        isNull,
      );
      final garbage = MockClient((_) async => http.Response('<html>', 200));
      expect(
        await probeLocalServer(garbage, 'http://127.0.0.1:8000/v1'),
        isNull,
      );
      final wrongShape = MockClient(
        (_) async => http.Response(jsonEncode({'models': <String>[]}), 200),
      );
      expect(
        await probeLocalServer(wrongShape, 'http://127.0.0.1:8000/v1'),
        isNull,
      );
    },
  );

  test(
    'scan reports answering ports; rescan sees newly started servers',
    () async {
      final byPort = <int, List<String>>{
        8000: ['glm-5'],
      };
      final container = ProviderContainer(
        overrides: [
          scanHttpClientProvider.overrideWith((_) => answering(byPort)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(localScanProvider, (_, _) {});
      addTearDown(sub.close);

      var hits = await container.read(localScanProvider.future);
      expect(hits.single.preset.name, 'oMLX');
      expect(hits.single.models, ['glm-5']);

      // The user starts koboldcpp, then hits Rescan.
      byPort[5001] = ['estopia-13b'];
      await container.read(localScanProvider.notifier).rescan();
      hits = await container.read(localScanProvider.future);
      expect(hits.map((h) => h.preset.name), ['oMLX', 'koboldcpp']);
    },
  );

  test('every known preset speaks /v1 on its documented port', () {
    expect(
      {for (final p in localServerPresets) p.name: p.port},
      {
        'oMLX': 8000,
        'koboldcpp': 5001,
        'Ollama': 11434,
        'LM Studio': 1234,
        'llama.cpp': 8080,
      },
    );
    for (final p in localServerPresets) {
      expect(p.baseUrl, 'http://127.0.0.1:${p.port}/v1');
    }
  });
}
