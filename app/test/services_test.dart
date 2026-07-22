import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llm/llm.dart';
import 'package:llmerta_app/services/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:persistence/persistence.dart';

class _FakeStorage implements FlutterSecureStorage {
  final map = <String, String?>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    return switch (invocation.memberName) {
      #read => Future<String?>.value(map[key]),
      #write => Future<void>.sync(
        () => map[key!] = invocation.namedArguments[#value] as String?,
      ),
      #delete => Future<void>.sync(() => map.remove(key)),
      _ => super.noSuchMethod(invocation),
    };
  }
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

Connection _connection(ProviderKind kind) => Connection(
  id: 'c1',
  label: 'test',
  kind: kind,
  baseUrl: 'http://localhost:1234/v1',
);

void main() {
  test('buildClient maps each provider kind to its adapter', () {
    expect(
      buildClient(_connection(ProviderKind.openaiCompat), 'k'),
      isA<OpenAiCompatClient>(),
    );
    expect(
      buildClient(_connection(ProviderKind.anthropic), 'k'),
      isA<AnthropicClient>(),
    );
    expect(
      buildClient(_connection(ProviderKind.gemini), null),
      isA<GeminiClient>(),
    );
  });

  test('secure key store namespaces slots by connection id', () async {
    final storage = _FakeStorage();
    final store = SecureApiKeyStore(storage);
    await store.write('omlx', 'sk-secret');
    expect(storage.map.keys.single, 'llmerta.apikey.omlx');
    expect(await store.read('omlx'), 'sk-secret');
    await store.delete('omlx');
    expect(await store.read('omlx'), isNull);
  });

  test(
    'appDatabase opens under application support and closes on dispose',
    () async {
      final tmp = await Directory.systemTemp.createTemp('llmerta-db');
      addTearDown(() => tmp.delete(recursive: true));
      PathProviderPlatform.instance = _FakePathProvider(tmp.path);

      final container = ProviderContainer();
      final db = container.read(appDatabaseProvider);
      await db.setPref('townName', 'Brasshollow');
      expect(await db.pref('townName'), 'Brasshollow');
      expect(File('${tmp.path}/llmerta.db').existsSync(), isTrue);
      container.dispose();
    },
  );
}
