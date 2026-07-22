import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tts/tts.dart';

import '../services/services.dart';

class VoicesSection extends ConsumerStatefulWidget {
  const VoicesSection({super.key});

  @override
  ConsumerState<VoicesSection> createState() => _VoicesSectionState();
}

class _VoicesSectionState extends ConsumerState<VoicesSection> {
  double? _downloadProgress;
  String? _downloadError;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(ttsEnabledProvider);
    final stack = ref.watch(ttsStackProvider);
    final kokoro = ref.watch(kokoroBundleProvider);
    final piper = ref.watch(piperBundleProvider);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Voices', style: text.titleMedium),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Speak the table aloud'),
          subtitle: const Text(
            'Fully offline — every line is always available as text too',
          ),
          value: enabled,
          onChanged: (v) => ref.read(ttsEnabledProvider.notifier).set(v),
        ),
        const SizedBox(height: 8),
        _BundleTile(
          title: 'Kokoro (53 speakers)',
          bundle: kokoro,
          missingHint:
              'Front Porch AI installs carry the bundle at '
              '~/Documents/FrontPorchAI/system/kokoro_models/sherpa-v1_0 — '
              'the legacy Application Support npz files will not work.',
        ),
        _BundleTile(
          title: 'Piper (en_US lessac)',
          bundle: piper,
          missingHint: 'A single offline voice, ~64 MB.',
          trailing: piper == null && _downloadProgress == null
              ? FilledButton.tonalIcon(
                  onPressed: _downloadPiper,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                )
              : null,
        ),
        if (_downloadProgress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _downloadProgress),
        ],
        if (_downloadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Download failed: $_downloadError',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          stack == null
              ? 'No usable voice bundle yet — the table plays silently.'
              : '${stack.voices.length} voices ready; seats rotate through '
                    'them and the narrator keeps its own.',
          style: text.bodySmall,
        ),
      ],
    );
  }

  Future<void> _downloadPiper() async {
    setState(() {
      _downloadProgress = 0;
      _downloadError = null;
    });
    try {
      final support = await getApplicationSupportDirectory();
      final downloader = VoiceDownloader();
      await downloader.download(
        piperLessac,
        Directory('${support.path}/voices'),
        onProgress: (received, total) => setState(
          () => _downloadProgress = total > 0 ? received / total : null,
        ),
      );
      downloader.close();
      ref
        ..invalidate(piperBundleProvider)
        ..invalidate(ttsStackProvider);
    } on Exception catch (error) {
      setState(() => _downloadError = '$error');
    } finally {
      if (mounted) setState(() => _downloadProgress = null);
    }
  }
}

class _BundleTile extends StatelessWidget {
  const _BundleTile({
    required this.title,
    required this.bundle,
    required this.missingHint,
    this.trailing,
  });

  final String title;
  final VoiceBundle? bundle;
  final String missingHint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        bundle == null ? Icons.voice_over_off : Icons.record_voice_over,
        color: bundle == null ? null : Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(
        bundle == null ? missingHint : 'Ready — ${bundle!.dir.path}',
      ),
      trailing: trailing,
    );
  }
}
