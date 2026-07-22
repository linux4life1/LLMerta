import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info.g.dart';

/// Empty when platform info is unavailable (tests, bare `flutter test`).
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Exception {
    return '';
  }
}
