import 'package:flutter_test/flutter_test.dart';
import 'package:llmerta_app/services/services.dart';

Map<String, Object?> release(
  String tag, {
  bool prerelease = false,
  String published = '2026-07-22T00:00:00Z',
  List<String> assets = const [
    'LLMerta.dmg',
    'LLMerta_Setup.exe',
    'LLMerta.AppImage',
  ],
}) => {
  'tag_name': tag,
  'prerelease': prerelease,
  'published_at': published,
  'body': 'notes for $tag',
  'assets': [
    for (final name in assets)
      {'name': name, 'browser_download_url': 'https://dl.example/$tag/$name'},
  ],
};

void main() {
  test('newest stable wins by publish time, never by list order', () {
    final picked = selectLatestStable([
      release('v0.1.0', published: '2026-07-01T00:00:00Z'),
      release('v0.1.2', published: '2026-07-22T00:00:00Z'),
      release('v0.1.1', published: '2026-07-10T00:00:00Z'),
    ]);
    expect(picked?['tag_name'], 'v0.1.2');
  });

  test('prereleases are skipped, flagged or merely named like one', () {
    final picked = selectLatestStable([
      release('v0.2.0-beta1', published: '2026-07-23T00:00:00Z'),
      release('v0.2.0-rc1', published: '2026-07-24T00:00:00Z'),
      release('v0.1.9', prerelease: true, published: '2026-07-25T00:00:00Z'),
      release('v0.1.5', published: '2026-07-05T00:00:00Z'),
      'garbage entry',
    ]);
    expect(picked?['tag_name'], 'v0.1.5');
    expect(selectLatestStable([]), isNull);
  });

  test('version comparison: bases, suffixes, and natural ordering', () {
    expect(isNewerVersion('0.1.1', '0.1.0'), isTrue);
    expect(isNewerVersion('v0.2.0', '0.1.9'), isTrue);
    expect(isNewerVersion('1.0.0', '0.9.9'), isTrue);
    expect(isNewerVersion('0.1.0', '0.1.0'), isFalse);
    expect(isNewerVersion('0.1.0', '0.1.1'), isFalse);
    expect(isNewerVersion('0.1', '0.1.0'), isFalse);
    // Stable outranks its own prerelease; suffixes order naturally.
    expect(isNewerVersion('0.2.0', '0.2.0-beta9'), isTrue);
    expect(isNewerVersion('0.2.0-beta1', '0.2.0'), isFalse);
    expect(isNewerVersion('0.2.0-beta10', '0.2.0-beta9'), isTrue);
  });

  test('platform assets carry the release-pipeline names', () {
    expect(platformUpdateAsset('macos'), 'LLMerta.dmg');
    expect(platformUpdateAsset('windows'), 'LLMerta_Setup.exe');
    expect(platformUpdateAsset('linux'), 'LLMerta.AppImage');
    expect(platformUpdateAsset('fuchsia'), '');
  });

  test('evaluateRelease resolves the asset or declines', () {
    final info = evaluateRelease(release('v0.1.2'), assetName: 'LLMerta.dmg');
    expect(info?.version, '0.1.2');
    expect(info?.assetUrl, 'https://dl.example/v0.1.2/LLMerta.dmg');
    expect(
      info?.releaseUrl,
      'https://github.com/linux4life1/LLMerta/releases/tag/v0.1.2',
    );
    expect(
      evaluateRelease(release('v0.1.2', assets: const []), assetName: 'x'),
      isNull,
    );
    expect(evaluateRelease(release('v0.1.2'), assetName: ''), isNull);
  });
}
