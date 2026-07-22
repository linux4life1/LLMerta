/// Pure release-selection and version-comparison logic, ported from Front
/// Porch AI's UpdateService and trimmed to LLMerta's single stable channel.
library;

const updateRepo = 'linux4life1/LLMerta';

class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.version,
    required this.notes,
    required this.assetUrl,
    required this.assetName,
  });

  final String tag;
  final String version;
  final String notes;
  final String assetUrl;
  final String assetName;

  String get releaseUrl => 'https://github.com/$updateRepo/releases/tag/$tag';

  @override
  bool operator ==(Object other) =>
      other is ReleaseInfo && other.tag == tag && other.assetUrl == assetUrl;

  @override
  int get hashCode => Object.hash(tag, assetUrl);
}

String platformUpdateAsset(String operatingSystem) => switch (operatingSystem) {
  'macos' => 'LLMerta.dmg',
  'windows' => 'LLMerta_Setup.exe',
  'linux' => 'LLMerta.AppImage',
  _ => '',
};

/// Newest stable release by publish timestamp — GitHub's list order is not
/// reliably newest-first (FPA field lesson), and prereleases are skipped
/// whether flagged or merely named like one.
Map<String, dynamic>? selectLatestStable(List<dynamic> releases) {
  Map<String, dynamic>? best;
  DateTime? bestStamp;
  for (final release in releases) {
    if (release is! Map<String, dynamic>) continue;
    if (release['prerelease'] == true || release['draft'] == true) continue;
    final tag = (release['tag_name'] as String? ?? '').toLowerCase();
    if (RegExp('beta|alpha|rc|dev|nightly').hasMatch(tag)) continue;
    final stamp =
        DateTime.tryParse(
          (release['published_at'] ?? release['created_at'] ?? '') as String,
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (best == null || stamp.isAfter(bestStamp!)) {
      best = release;
      bestStamp = stamp;
    }
  }
  return best;
}

String normalizeVersion(String v) => v.trim().replaceFirst(RegExp('^[vV]'), '');

ReleaseInfo? evaluateRelease(
  Map<String, dynamic> release, {
  required String assetName,
}) {
  if (assetName.isEmpty) return null;
  final assets = release['assets'] as List<dynamic>? ?? const [];
  for (final asset in assets) {
    if (asset is Map<String, dynamic> && asset['name'] == assetName) {
      final url = asset['browser_download_url'] as String?;
      if (url == null) return null;
      final tag = release['tag_name'] as String? ?? '';
      return ReleaseInfo(
        tag: tag,
        version: normalizeVersion(tag),
        notes: release['body'] as String? ?? '',
        assetUrl: url,
        assetName: assetName,
      );
    }
  }
  return null;
}

/// FPA's semver-plus-suffix comparison: numeric base first, a bare version
/// outranks a suffixed one, suffixes compare naturally ("beta10" > "beta9").
bool isNewerVersion(String remote, String local) {
  final r = normalizeVersion(remote).toLowerCase();
  final l = normalizeVersion(local).toLowerCase();
  if (r == l) return false;

  final rSplit = r.split('-');
  final lSplit = l.split('-');
  final rBase = [
    for (final part in rSplit.first.split('.')) int.tryParse(part) ?? 0,
  ];
  final lBase = [
    for (final part in lSplit.first.split('.')) int.tryParse(part) ?? 0,
  ];
  while (rBase.length < lBase.length) {
    rBase.add(0);
  }
  while (lBase.length < rBase.length) {
    lBase.add(0);
  }
  for (var i = 0; i < rBase.length; i++) {
    if (rBase[i] != lBase[i]) return rBase[i] > lBase[i];
  }

  final rSuffix = rSplit.length > 1 ? rSplit.sublist(1).join('-') : '';
  final lSuffix = lSplit.length > 1 ? lSplit.sublist(1).join('-') : '';
  if (rSuffix.isEmpty && lSuffix.isNotEmpty) return true;
  if (rSuffix.isNotEmpty && lSuffix.isEmpty) return false;
  return _compareAlphanumeric(rSuffix, lSuffix) > 0;
}

int _compareAlphanumeric(String a, String b) {
  final re = RegExp(r'(\d+)|(\D+)');
  final aParts = re.allMatches(a).map((m) => m.group(0)!).toList();
  final bParts = re.allMatches(b).map((m) => m.group(0)!).toList();
  final length = aParts.length < bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < length; i++) {
    final aNum = int.tryParse(aParts[i]);
    final bNum = int.tryParse(bParts[i]);
    final cmp = aNum != null && bNum != null
        ? aNum.compareTo(bNum)
        : aParts[i].compareTo(bParts[i]);
    if (cmp != 0) return cmp;
  }
  return aParts.length.compareTo(bParts.length);
}
