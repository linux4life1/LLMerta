import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_info.dart';
import 'database.dart';
import 'http_client.dart';
import 'update_install.dart';
import 'update_logic.dart';

part 'update_service.freezed.dart';
part 'update_service.g.dart';

const updateAutoCheckPrefKey = 'updateAutoCheck';

enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  ready,
  error,
}

@freezed
abstract class UpdateState with _$UpdateState {
  const factory UpdateState({
    @Default(UpdatePhase.idle) UpdatePhase phase,
    ReleaseInfo? latest,
    @Default(0.0) double progress,
    String? error,
    DateTime? checkedAt,
    @Default(true) bool autoCheck,
  }) = _UpdateState;
}

/// FPA-precedent self-updater, single stable channel: GitHub Releases
/// check → streamed download → sidecar install on restart.
@Riverpod(keepAlive: true)
class UpdateController extends _$UpdateController {
  /// Test seam; production support is platform-derived (never in debug,
  /// Windows needs the installer's .installed marker, Linux the APPIMAGE
  /// env, macOS a real .app bundle).
  @visibleForTesting
  static bool? supportedOverride;

  String? _installerPath;

  static bool get isSupported {
    if (supportedOverride != null) return supportedOverride!;
    if (kDebugMode) return false;
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return File('$exeDir\\.installed').existsSync();
    }
    if (Platform.isLinux) {
      return Platform.environment.containsKey('APPIMAGE');
    }
    if (Platform.isMacOS) {
      return Platform.resolvedExecutable.contains('.app/Contents/MacOS/');
    }
    return false;
  }

  @override
  UpdateState build() => const UpdateState();

  Future<void> _hydrate() async {
    try {
      final saved = await ref
          .read(appDatabaseProvider)
          .pref(updateAutoCheckPrefKey);
      if (saved != null) state = state.copyWith(autoCheck: saved == 'true');
    } on Exception {
      // No DB yet: keep the default.
    }
  }

  Future<void> setAutoCheck(bool enabled) async {
    state = state.copyWith(autoCheck: enabled);
    try {
      await ref
          .read(appDatabaseProvider)
          .setPref(updateAutoCheckPrefKey, '$enabled');
    } on Exception {
      // Preference persistence is best-effort.
    }
  }

  /// Once per launch, quietly, only when supported and opted in.
  Future<void> autoCheckOnLaunch() async {
    if (!isSupported || state.checkedAt != null) return;
    await _hydrate();
    if (!state.autoCheck) return;
    await check();
  }

  Future<void> check() async {
    if (!isSupported || state.phase == UpdatePhase.checking) return;
    state = state.copyWith(phase: UpdatePhase.checking, error: null);
    try {
      final response = await ref
          .read(scanHttpClientProvider)
          .get(
            Uri.parse('https://api.github.com/repos/$updateRepo/releases'),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          );
      if (response.statusCode != 200) {
        throw HttpException('GitHub answered ${response.statusCode}');
      }
      final release = selectLatestStable(jsonDecode(response.body) as List);
      final info = release == null
          ? null
          : evaluateRelease(
              release,
              assetName: platformUpdateAsset(Platform.operatingSystem),
            );
      final current = await ref.read(appVersionProvider.future);
      final newer =
          info != null &&
          current.isNotEmpty &&
          isNewerVersion(info.version, current);
      state = state.copyWith(
        phase: newer ? UpdatePhase.available : UpdatePhase.upToDate,
        latest: newer ? info : null,
        checkedAt: DateTime.now(),
      );
    } on Exception catch (error) {
      state = state.copyWith(
        phase: UpdatePhase.error,
        error: '$error',
        checkedAt: DateTime.now(),
      );
    }
  }

  Future<void> download() async {
    final info = state.latest;
    if (info == null || state.phase == UpdatePhase.downloading) return;
    state = state.copyWith(phase: UpdatePhase.downloading, progress: 0);
    try {
      final response = await ref
          .read(scanHttpClientProvider)
          .send(http.Request('GET', Uri.parse(info.assetUrl)));
      if (response.statusCode != 200) {
        throw HttpException('download answered ${response.statusCode}');
      }
      final path = '${Directory.systemTemp.path}/${info.assetName}';
      final sink = File(path).openWrite();
      final total = response.contentLength ?? -1;
      var received = 0;
      var lastShown = 0.0;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0 && received / total - lastShown >= 0.01) {
            lastShown = received / total;
            state = state.copyWith(progress: lastShown);
          }
        }
      } finally {
        await sink.close();
      }
      _installerPath = path;
      state = state.copyWith(phase: UpdatePhase.ready, progress: 1);
    } on Exception catch (error) {
      state = state.copyWith(phase: UpdatePhase.error, error: '$error');
    }
  }

  /// Test seam: the pending installer path.
  @visibleForTesting
  String? get installerPath => _installerPath;

  /// Hands off to the platform sidecar and exits the process.
  Future<void> restartAndUpdate() async {
    final path = _installerPath;
    if (path == null) return;
    await installAndExit(path);
  }
}
