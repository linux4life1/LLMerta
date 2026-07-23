// Process-level install paths ported from FPA's UpdateService: a detached
// sidecar (or silent installer) replaces the running app after it exits.
// Excluded from coverage like the other thin native wrappers — everything
// here that spawns processes cannot run inside a test; the script
// generator itself is pure and unit-tested.
import 'dart:io';

String shellEscape(String path) => path.replaceAll("'", r"'\''");

/// Linux: replace the running AppImage in place (unlinking a running
/// executable is legal), make it executable, relaunch detached.
Future<void> replaceAppImage(String downloadedPath) async {
  final current = Platform.environment['APPIMAGE'];
  if (current == null || current.isEmpty) return;
  await Process.run('rm', ['-f', current]);
  final cp = await Process.run('cp', [downloadedPath, current]);
  if (cp.exitCode != 0) {
    throw ProcessException('cp', [downloadedPath, current], '${cp.stderr}');
  }
  await Process.run('chmod', ['+x', current]);
  await Process.start(current, [], mode: ProcessStartMode.detached);
}

/// The macOS swap script, as a pure function so tests can pin its
/// behavior. v0.1.3 regression: hdiutil's attach output is
/// `/dev/diskNsM<TAB>Apple_HFS<TAB>/tmp/dmg.XXXX`, and the FPA-inherited
/// `cut -f 2-` kept the partition type glued to the path — find failed
/// and the app was never replaced. The last tab field is the mount point.
String macDmgSidecarScript({
  required int waitForPid,
  required String dmgPath,
  required String appPath,
  required String scriptPath,
  required String logPath,
}) {
  final escDmg = shellEscape(dmgPath);
  final escApp = shellEscape(appPath);
  final escScript = shellEscape(scriptPath);
  final escLog = shellEscape(logPath);
  return '''
#!/bin/bash
exec >> '$escLog' 2>&1
echo "== LLMerta update \$(date) =="
for i in {1..60}; do
  if ! kill -0 $waitForPid 2>/dev/null; then break; fi
  sleep 0.5
done
MOUNT_OUTPUT=\$(hdiutil attach '$escDmg' -nobrowse -noverify -mountrandom /tmp 2>&1)
if [ \$? -ne 0 ]; then
  echo "attach failed: \$MOUNT_OUTPUT"
  exit 1
fi
MOUNT_POINT=\$(echo "\$MOUNT_OUTPUT" | tail -1 | awk -F'\\t' '{print \$NF}' | xargs)
echo "mounted at: \$MOUNT_POINT"
NEW_APP=\$(find "\$MOUNT_POINT" -maxdepth 1 -name "*.app" -type d | head -1)
if [ -z "\$NEW_APP" ] || [ ! -d "\$NEW_APP" ]; then
  echo "no .app found at mount point"
  hdiutil detach "\$MOUNT_POINT" -quiet 2>/dev/null || true
  exit 1
fi
echo "replacing '$escApp' with \$NEW_APP"
rm -rf '$escApp'
cp -R "\$NEW_APP" '$escApp'
xattr -cr '$escApp' 2>/dev/null || true
hdiutil detach "\$MOUNT_POINT" -quiet 2>/dev/null || true
rm -f '$escDmg' '$escScript' || true
echo "swap complete, relaunching"
open -n '$escApp'
''';
}

/// macOS: detached bash sidecar waits for this PID to exit, mounts the
/// notarized DMG, swaps the .app, strips quarantine, detaches,
/// relaunches. Progress lands in ~/Library/Logs/LLMerta/update.log.
Future<void> spawnMacDmgSidecar(String dmgPath) async {
  final exe = Platform.resolvedExecutable;
  final appPath = File(exe).parent.parent.parent.path;
  final logDir = Directory(
    '${Platform.environment['HOME'] ?? '/tmp'}/Library/Logs/LLMerta',
  );
  await logDir.create(recursive: true);
  final scriptPath =
      '${Directory.systemTemp.path}/llmerta_update_'
      '${DateTime.now().millisecondsSinceEpoch}.sh';
  final script = macDmgSidecarScript(
    waitForPid: pid,
    dmgPath: dmgPath,
    appPath: appPath,
    scriptPath: scriptPath,
    logPath: '${logDir.path}/update.log',
  );
  await File(scriptPath).writeAsString(script);
  await Process.run('chmod', ['+x', scriptPath]);
  await Process.start('/bin/bash', [
    scriptPath,
  ], mode: ProcessStartMode.detached);
}

/// Windows: silent in-place Inno upgrade with FPA's exact flags — /DIR
/// pins the install to where the running exe actually lives.
Future<void> launchWindowsInstaller(String installerPath) async {
  var installDir = File(Platform.resolvedExecutable).parent.path;
  while (installDir.endsWith(r'\')) {
    installDir = installDir.substring(0, installDir.length - 1);
  }
  await Process.start(installerPath, [
    '/VERYSILENT',
    '/DIR=$installDir',
    '/SUPPRESSMSGBOXES',
    '/NORESTART',
    '/CLOSEAPPLICATIONS',
  ]);
}

Future<void> installAndExit(String installerPath) async {
  if (Platform.isLinux) {
    await replaceAppImage(installerPath);
  } else if (Platform.isMacOS) {
    await spawnMacDmgSidecar(installerPath);
  } else if (Platform.isWindows) {
    await launchWindowsInstaller(installerPath);
  }
  exit(0);
}
