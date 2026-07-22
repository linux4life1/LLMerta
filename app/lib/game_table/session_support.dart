import 'package:llm/llm.dart';

import '../lobby/lobby.dart';

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
