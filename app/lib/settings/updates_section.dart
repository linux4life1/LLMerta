import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';

class UpdatesSection extends ConsumerWidget {
  const UpdatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final version = ref.watch(appVersionProvider).value ?? '';
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Updates', style: text.titleMedium),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.verified_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(version.isEmpty ? 'LLMerta' : 'LLMerta v$version'),
          subtitle: Text(switch (update.phase) {
            UpdatePhase.idle =>
              UpdateController.isSupported
                  ? 'Not checked yet this session.'
                  : 'Self-update runs only in installed builds.',
            UpdatePhase.checking => 'Checking GitHub releases…',
            UpdatePhase.upToDate => 'You are current.',
            UpdatePhase.available => 'v${update.latest?.version} is available.',
            UpdatePhase.downloading => 'Downloading the update…',
            UpdatePhase.ready => 'Downloaded — restart to update.',
            UpdatePhase.error => 'Check failed: ${update.error}',
          }),
          trailing: OutlinedButton(
            onPressed:
                UpdateController.isSupported &&
                    update.phase != UpdatePhase.checking
                ? controller.check
                : null,
            child: const Text('Check now'),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Check automatically on launch'),
          subtitle: const Text(
            'Once per start, quietly — a chip on the home screen when '
            "something's new",
          ),
          value: update.autoCheck,
          onChanged: UpdateController.isSupported
              ? controller.setAutoCheck
              : null,
        ),
        if (update.latest case final latest?) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'v${latest.version} is out',
                    style: text.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (latest.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      latest.notes.trim(),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (update.phase == UpdatePhase.downloading) ...[
                        Expanded(
                          child: LinearProgressIndicator(
                            value: update.progress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(update.progress * 100).round()}%',
                          style: text.labelSmall,
                        ),
                      ] else if (update.phase == UpdatePhase.ready)
                        FilledButton.icon(
                          onPressed: controller.restartAndUpdate,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restart & update'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: controller.download,
                          icon: const Icon(Icons.download),
                          label: const Text('Download update'),
                        ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: latest.releaseUrl),
                        ),
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Copy release link'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
