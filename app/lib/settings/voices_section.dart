import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tts/tts.dart';

import '../services/services.dart';

class VoicesSection extends ConsumerStatefulWidget {
  const VoicesSection({super.key});

  @override
  ConsumerState<VoicesSection> createState() => _VoicesSectionState();
}

class _VoicesSectionState extends ConsumerState<VoicesSection> {
  String? _downloadingDir;
  double? _downloadProgress;
  String? _downloadError;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(ttsEnabledProvider);
    final stack = ref.watch(ttsStackProvider);
    final kokoro = ref.watch(kokoroBundleProvider).value;
    final piper = ref.watch(piperBundleProvider).value;
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
          title: 'Kokoro v1.0 (53 speakers)',
          bundle: kokoro,
          missingHint:
              'Every seat gets its own voice. One ~330 MB download into '
              "LLMerta's own folder — nothing else on disk is touched.",
          trailing: _downloadButton(kokoro, kokoroV1),
        ),
        _BundleTile(
          title: 'Piper (en_US lessac)',
          bundle: piper,
          missingHint: 'A single lighter voice, ~64 MB.',
          trailing: _downloadButton(piper, piperLessac),
        ),
        if (_downloadProgress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _downloadProgress),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _downloadProgress == 1
                  ? 'Unpacking…'
                  : 'Downloading — the table stays playable meanwhile.',
              style: text.bodySmall,
            ),
          ),
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
              ? 'No voice bundle yet — the table plays silently until one '
                    'is downloaded.'
              : '${stack.voices.length} voices ready; seats rotate through '
                    'them and the narrator keeps its own.',
          style: text.bodySmall,
        ),
      ],
    );
  }

  Widget? _downloadButton(VoiceBundle? bundle, WellKnownVoice voice) {
    if (bundle != null || _downloadingDir != null) return null;
    return FilledButton.tonalIcon(
      onPressed: () => _download(voice),
      icon: const Icon(Icons.download),
      label: const Text('Download'),
    );
  }

  Future<void> _download(WellKnownVoice voice) async {
    setState(() {
      _downloadingDir = voice.dirName;
      _downloadProgress = 0;
      _downloadError = null;
    });
    try {
      final voicesDir = await ref.read(voicesDirProvider.future);
      await ref
          .read(voiceDownloaderProvider)
          .download(
            voice,
            voicesDir,
            onProgress: (received, total) => setState(
              () => _downloadProgress = total > 0 ? received / total : null,
            ),
          );
      ref
        ..invalidate(kokoroBundleProvider)
        ..invalidate(piperBundleProvider)
        ..invalidate(ttsStackProvider);
    } on Exception catch (error) {
      setState(() => _downloadError = '$error');
    } finally {
      if (mounted) {
        setState(() {
          _downloadingDir = null;
          _downloadProgress = null;
        });
      }
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
      subtitle: Text(bundle == null ? missingHint : 'Ready'),
      trailing: trailing,
    );
  }
}
