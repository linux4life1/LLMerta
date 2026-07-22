import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_client.g.dart';

/// Shared plain HTTP client (local-server scans, update checks) — one
/// override point for tests.
@Riverpod(keepAlive: true)
http.Client scanHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}
