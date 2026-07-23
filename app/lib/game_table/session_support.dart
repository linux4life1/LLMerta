import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llm/llm.dart';

import '../lobby/lobby.dart';
import '../services/services.dart';
import '../settings/settings.dart';
import 'session_state.dart';

Persona humanSeatPersona(String name, String? avatarPath) => Persona(
  name: name,
  archetype: 'themself',
  style: 'their own',
  quirk: 'unpredictable — a human is playing this seat',
  avatarPath: avatarPath,
);

/// One tiny request per connection hosting exactly one distinct model:
/// JIT backends (Ollama, LM Studio) load before Night 0, so decision
/// timeouts never race a cold model. Skipped when a connection hosts
/// several models — swap-by-reload backends would thrash (BALANCE.md).
Future<void> prewarmBackends(
  LobbySetup setup,
  Map<int, (ChatProvider, String)> backends,
) async {
  final byConnection = <String, (ChatProvider, String)>{};
  final distinct = <String, Set<String>>{};
  for (final seat in setup.aiSeats) {
    final id = setup.seats[seat].connectionId!;
    distinct.putIfAbsent(id, () => {}).add(setup.seats[seat].model!);
    byConnection[id] = backends[seat]!;
  }
  await Future.wait([
    for (final MapEntry(key: id, value: (client, model))
        in byConnection.entries)
      if (distinct[id]!.length == 1)
        client
            .chat(
              [ChatMessage.user('Say "ready".')],
              model: model,
              maxTokens: 1,
            )
            .then((_) {}, onError: (Object _, StackTrace _) {}),
  ]).timeout(const Duration(seconds: 120), onTimeout: () => const []);
}

Future<Persona Function(String)> personaResolver(Ref ref) async {
  final db = ref.read(appDatabaseProvider);
  final customs = {
    for (final row in await db.watchPersonas().first) row.name: row.toPersona(),
  };
  final house = {for (final p in personaLibrary) p.name: p};
  return (String name) =>
      customs[name] ??
      house[name] ??
      Persona(
        name: name,
        archetype: 'townsperson',
        style: 'plain',
        quirk: 'unremarkable',
      );
}

Future<Map<int, String>> grudgeMemories(
  Ref ref, {
  required bool grudgeMode,
  required List<String> names,
}) async {
  if (!grudgeMode) return const {};
  final json = await ref.read(appDatabaseProvider).pref(grudgeBookPrefKey);
  if (json == null) return const {};
  final grudges = GrudgeBook.fromJson(json);
  return {
    for (var s = 0; s < names.length; s++)
      if (grudges.promptBlockFor(names[s]) case final String block) s: block,
  };
}

/// Clients are cached per connection and tracked in [track] so the
/// session can close them at teardown.
Future<Future<ChatProvider> Function(String)> clientResolver(
  Ref ref,
  List<ChatProvider> track,
) async {
  final keyStore = ref.read(apiKeyStoreProvider);
  final factory = ref.read(clientFactoryProvider);
  final connections = {
    for (final c
        in await ref.read(appDatabaseProvider).watchConnections().first)
      c.id: c,
  };
  final cache = <String, ChatProvider>{};
  return (String connectionId) async {
    final cached = cache[connectionId];
    if (cached != null) return cached;
    final connection = connections[connectionId];
    if (connection == null) {
      throw StateError('Connection $connectionId no longer exists');
    }
    final client = factory(connection, await keyStore.read(connectionId));
    cache[connectionId] = client;
    track.add(client);
    return client;
  };
}
