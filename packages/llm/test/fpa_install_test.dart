import 'dart:io';

import 'package:llm/llm.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('fpa_install_home');
  });

  tearDown(() {
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  Directory mkInstall(String name, {DateTime? dbMtime}) {
    final root = Directory(p.join(home.path, 'Documents', name))
      ..createSync(recursive: true);
    final km = Directory(p.join(root.path, 'KoboldManager'))
      ..createSync(recursive: true);
    Directory(p.join(km.path, 'Characters')).createSync();
    final db = File(p.join(km.path, 'front_porch.db'))..writeAsStringSync('x');
    if (dbMtime != null) {
      db.setLastModifiedSync(dbMtime);
    }
    return root;
  }

  test('discover finds nothing when empty', () {
    expect(discoverFpaInstalls(homeOverride: home.path), isEmpty);
    expect(resolveFpaInstall(homeOverride: home.path), isNull);
  });

  test('single stable install resolves', () {
    mkInstall('FrontPorchAI');
    final r = resolveFpaInstall(homeOverride: home.path)!;
    expect(r.channel, FpaInstallChannel.stable);
    expect(r.label, 'Stable');
    expect(r.charactersDir.existsSync(), isTrue);
    expect(detectFpaCharacterDir(homeOverride: home.path)!.path,
        r.charactersDir.path);
    expect(
      detectPorchMemoriesDir(homeOverride: home.path)!.path,
      endsWith('llmerta_porch_memories'),
    );
  });

  test('single beta install resolves (Rawhide-only)', () {
    mkInstall('FrontPorchAI-Beta');
    final r = resolveFpaInstall(homeOverride: home.path)!;
    expect(r.channel, FpaInstallChannel.beta);
    expect(r.label, 'Rawhide (Beta)');
    expect(r.helperLabel, contains('Rawhide'));
  });

  test('dual install prefers newer front_porch.db', () {
    final older = DateTime.utc(2020, 1, 1);
    final newer = DateTime.utc(2026, 7, 1);
    mkInstall('FrontPorchAI', dbMtime: older);
    mkInstall('FrontPorchAI-Beta', dbMtime: newer);

    final r = resolveFpaInstall(homeOverride: home.path)!;
    expect(r.channel, FpaInstallChannel.beta);
    expect(r.root.path, contains('FrontPorchAI-Beta'));
  });

  test('dual install prefers stable when its db is newer', () {
    final older = DateTime.utc(2020, 1, 1);
    final newer = DateTime.utc(2026, 7, 1);
    mkInstall('FrontPorchAI', dbMtime: newer);
    mkInstall('FrontPorchAI-Beta', dbMtime: older);

    final r = resolveFpaInstall(homeOverride: home.path)!;
    expect(r.channel, FpaInstallChannel.stable);
  });

  test('never merges — discover lists both separately', () {
    mkInstall('FrontPorchAI');
    mkInstall('FrontPorchAI-Beta');
    final all = discoverFpaInstalls(homeOverride: home.path);
    expect(all, hasLength(2));
    expect(
      all.map((i) => i.channel).toSet(),
      {FpaInstallChannel.stable, FpaInstallChannel.beta},
    );
  });

  test('root without KoboldManager is ignored', () {
    Directory(p.join(home.path, 'Documents', 'FrontPorchAI'))
        .createSync(recursive: true);
    expect(discoverFpaInstalls(homeOverride: home.path), isEmpty);
  });
}
