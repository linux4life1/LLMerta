import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_keys.g.dart';

/// API keys live only in the OS keychain, addressed by connection id
/// (ARCHITECTURE.md §5 — never in SQLite, saves, or logs).
abstract interface class ApiKeyStore {
  Future<String?> read(String connectionId);
  Future<void> write(String connectionId, String apiKey);
  Future<void> delete(String connectionId);
}

class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Ad-hoc dev builds lack provisioning for the protected
            // keychain (docs/SPIKES.md §4); the file keychain works there
            // and in signed release builds alike.
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _storage;

  String _slot(String connectionId) => 'llmerta.apikey.$connectionId';

  @override
  Future<String?> read(String connectionId) =>
      _storage.read(key: _slot(connectionId));

  @override
  Future<void> write(String connectionId, String apiKey) =>
      _storage.write(key: _slot(connectionId), value: apiKey);

  @override
  Future<void> delete(String connectionId) =>
      _storage.delete(key: _slot(connectionId));
}

@Riverpod(keepAlive: true)
ApiKeyStore apiKeyStore(Ref ref) => SecureApiKeyStore();
