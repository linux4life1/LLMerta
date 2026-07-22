import 'package:persistence/persistence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/services.dart';

part 'connection_providers.g.dart';

@riverpod
Stream<List<Connection>> connectionRows(Ref ref) =>
    ref.watch(appDatabaseProvider).watchConnections();

@riverpod
Stream<List<String>> connectionModels(Ref ref, String connectionId) =>
    ref.watch(appDatabaseProvider).watchModels(connectionId);

/// Test = fetch the live model list; success doubles as the cache refresh.
@riverpod
class ConnectionTest extends _$ConnectionTest {
  @override
  AsyncValue<int>? build(String connectionId) => null;

  Future<void> run() async {
    state = const AsyncValue.loading();
    final db = ref.read(appDatabaseProvider);
    final rows = await db.watchConnections().first;
    final connection = rows.firstWhere((c) => c.id == connectionId);
    final apiKey = await ref.read(apiKeyStoreProvider).read(connectionId);
    final client = ref.read(clientFactoryProvider)(connection, apiKey);
    try {
      final models = await client.listModels();
      await db.replaceModels(connectionId, models);
      state = AsyncValue.data(models.length);
    } on Exception catch (error, stack) {
      state = AsyncValue.error(error, stack);
    } finally {
      client.close();
    }
  }
}
