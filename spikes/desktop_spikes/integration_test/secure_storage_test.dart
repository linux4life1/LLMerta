// M0 spike 4: flutter_secure_storage behavior, esp. Linux without a keyring.
// The test reports observed behavior rather than assuming success: on Linux
// with no Secret Service the write is expected to throw — the spike's job is
// to capture exactly what happens so the key-storage design can react.
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('write/read/delete round-trip (or documented failure)', (
    tester,
  ) async {
    // macOS: the default data-protection keychain needs a real signing
    // identity (ad-hoc dev builds get -34018); the legacy login keychain
    // works unsigned. Release builds are Developer ID-signed, so this only
    // affects dev ergonomics.
    const storage = FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    );
    const key = 'm0_spike_api_key';
    try {
      await storage.write(key: key, value: 'sk-spike-123');
      final back = await storage.read(key: key);
      await storage.delete(key: key);
      final gone = await storage.read(key: key);
      // ignore: avoid_print
      print(
        'SPIKE4 RESULT: platform=${Platform.operatingSystem} '
        'roundtrip=${back == 'sk-spike-123'} deleted=${gone == null}',
      );
      expect(back, 'sk-spike-123');
      expect(gone, isNull);
    } on Object catch (e) {
      // ignore: avoid_print
      print(
        'SPIKE4 RESULT: platform=${Platform.operatingSystem} '
        'FAILED with ${e.runtimeType}: $e',
      );
      rethrow;
    }
  });
}
