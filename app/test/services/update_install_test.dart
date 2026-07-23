import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/services/update_install.dart';

void main() {
  test('mac sidecar script extracts the mount point from the last tab field', () {
    final script = macDmgSidecarScript(
      waitForPid: 4242,
      dmgPath: '/tmp/LLMerta.dmg',
      appPath: '/Applications/LLMerta.app',
      scriptPath: '/tmp/update.sh',
      logPath: '/tmp/update.log',
    );
    // The v0.1.3 regression: `cut -f 2-` kept "Apple_HFS<TAB>/tmp/dmg.X"
    // glued together. The fix takes the LAST tab-separated field.
    expect(script, contains(r"awk -F'\t' '{print $NF}'"));
    expect(script, isNot(contains('cut -f')));
    expect(script, contains('kill -0 4242'));
    expect(script, contains("hdiutil attach '/tmp/LLMerta.dmg'"));
    expect(script, contains("rm -rf '/Applications/LLMerta.app'"));
    expect(script, contains("open -n '/Applications/LLMerta.app'"));
    expect(script, contains("exec >> '/tmp/update.log'"));
    // No unescaped Dart interpolation left dollar-less shell vars broken.
    expect(script, contains(r'$MOUNT_OUTPUT'));
    expect(script, contains(r'$NEW_APP'));
  });

  test('single quotes in paths are shell-escaped', () {
    expect(shellEscape("it's.app"), r"it'\''s.app");
    final script = macDmgSidecarScript(
      waitForPid: 1,
      dmgPath: "/tmp/o'brien.dmg",
      appPath: "/Applications/it's.app",
      scriptPath: '/tmp/s.sh',
      logPath: '/tmp/l.log',
    );
    expect(script, contains(r"'/tmp/o'\''brien.dmg'"));
  });

  // Harness hook for the local end-to-end swap check (never runs in CI):
  //   SIDECAR_OUT=… SIDECAR_DMG=… SIDECAR_APP=… SIDECAR_LOG=… \
  //     flutter test test/services/update_install_test.dart
  test('writes a runnable script when the harness asks for one', () {
    final out = Platform.environment['SIDECAR_OUT'];
    if (out == null) return;
    File(out).writeAsStringSync(
      macDmgSidecarScript(
        waitForPid: int.parse(Platform.environment['SIDECAR_PID'] ?? '1'),
        dmgPath: Platform.environment['SIDECAR_DMG']!,
        appPath: Platform.environment['SIDECAR_APP']!,
        scriptPath: out,
        logPath: Platform.environment['SIDECAR_LOG']!,
      ),
    );
  });
}
