import 'dart:io';

import 'package:path/path.dart' as p;

/// Which Front Porch data tree an [FpaInstall] came from.
enum FpaInstallChannel {
  /// `FrontPorchAI` — stable / release installs.
  stable,

  /// `FrontPorchAI-Beta` — Rawhide / beta / pre-release installs.
  beta,
}

/// One local Front Porch AI data root (never a merge of stable + beta).
///
/// Personas, character cards, and porch-memory mailbox all live under this
/// single root so UUID identity stays coherent. Dual installs are resolved
/// by [resolveFpaInstall] (newest `front_porch.db` wins).
class FpaInstall {
  const FpaInstall({
    required this.root,
    required this.channel,
  });

  /// Data directory root, e.g. `…/Documents/FrontPorchAI` or `…-Beta`.
  final Directory root;
  final FpaInstallChannel channel;

  Directory get koboldManager =>
      Directory(p.join(root.path, 'KoboldManager'));

  Directory get charactersDir =>
      Directory(p.join(koboldManager.path, 'Characters'));

  /// Mailbox LLMerta writes / FPA drains (may not exist yet on disk).
  Directory get porchMemoriesDir =>
      Directory(p.join(koboldManager.path, 'llmerta_porch_memories'));

  File get personaDb =>
      File(p.join(koboldManager.path, 'front_porch.db'));

  Directory get customBackgroundsDir =>
      Directory(p.join(root.path, 'custom_backgrounds'));

  /// Short lobby / settings label.
  String get label => switch (channel) {
    FpaInstallChannel.stable => 'Stable',
    FpaInstallChannel.beta => 'Rawhide (Beta)',
  };

  /// Longer helper for form fields.
  String get helperLabel => 'Front Porch AI — $label';

  /// Sort key for dual-install auto-pick: newest persona DB wins; fall back
  /// to KoboldManager / root mtime so a brand-new beta folder still ranks.
  DateTime activityTime() {
    final db = personaDb;
    if (db.existsSync()) {
      return db.statSync().modified;
    }
    final km = koboldManager;
    if (km.existsSync()) {
      return km.statSync().modified;
    }
    return root.statSync().modified;
  }
}

String? _homePath({String? homeOverride}) {
  final home = homeOverride ??
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '';
  return home.isEmpty ? null : home;
}

/// Candidate data roots under [home] (Documents first, then bare home).
/// Stable and Beta are both listed — no preference order here.
List<({String path, FpaInstallChannel channel})> fpaInstallCandidateRoots(
  String home,
) {
  return [
    (
      path: p.join(home, 'Documents', 'FrontPorchAI'),
      channel: FpaInstallChannel.stable,
    ),
    (
      path: p.join(home, 'Documents', 'FrontPorchAI-Beta'),
      channel: FpaInstallChannel.beta,
    ),
    (
      path: p.join(home, 'FrontPorchAI'),
      channel: FpaInstallChannel.stable,
    ),
    (
      path: p.join(home, 'FrontPorchAI-Beta'),
      channel: FpaInstallChannel.beta,
    ),
  ];
}

/// All FPA installs that have a `KoboldManager` directory on disk.
/// Does **not** merge libraries — each entry is a separate root.
List<FpaInstall> discoverFpaInstalls({String? homeOverride}) {
  final home = _homePath(homeOverride: homeOverride);
  if (home == null) return const [];

  final seen = <String>{};
  final out = <FpaInstall>[];
  for (final c in fpaInstallCandidateRoots(home)) {
    final root = Directory(c.path);
    final norm = p.normalize(root.path);
    if (!seen.add(norm)) continue;
    if (!root.existsSync()) continue;
    final km = Directory(p.join(root.path, 'KoboldManager'));
    if (!km.existsSync()) continue;
    out.add(FpaInstall(root: root, channel: c.channel));
  }
  return out;
}

/// The single FPA install LLMerta binds for this process:
/// - none → null  
/// - one → that install  
/// - several → highest [FpaInstall.activityTime] (newest `front_porch.db`)
///
/// Never unions stable + beta personas or cards.
FpaInstall? resolveFpaInstall({String? homeOverride}) {
  final installs = discoverFpaInstalls(homeOverride: homeOverride);
  if (installs.isEmpty) return null;
  if (installs.length == 1) return installs.first;
  installs.sort((a, b) => b.activityTime().compareTo(a.activityTime()));
  return installs.first;
}
