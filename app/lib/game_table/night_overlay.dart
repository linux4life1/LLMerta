import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

const nightOverlayMessages = [
  'The town sleeps…',
  'Someone is stirring.',
  'Floorboards creak, doors stay bolted.',
  'The night takes its course.',
];

/// Passive-night veil (UI_UX.md §2): fixed-order, fixed-pace messaging so
/// timing leaks nothing about which roles are acting. Human-paced nights
/// never show this — the dock has their picker instead.
class NightOverlay extends StatefulWidget {
  const NightOverlay({this.spentAssassinNotice = false, super.key});

  /// One-time notice on the first night after the assassin's bullet went.
  final bool spentAssassinNotice;

  @override
  State<NightOverlay> createState() => _NightOverlayState();
}

class _NightOverlayState extends State<NightOverlay> {
  var _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      setState(() => _step = (_step + 1) % nightOverlayMessages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: LlmertaPalette.ink.withValues(alpha: 0.35),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.spentAssassinNotice) ...[
                Text(
                  'Your bullet is gone — you sleep through the night now.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LlmertaPalette.bone.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                child: Text(
                  nightOverlayMessages[_step],
                  key: ValueKey(_step),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LlmertaPalette.bone.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
