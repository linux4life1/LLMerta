import 'package:flutter/material.dart';

/// Caption-style reveal: words fade in across the line's real audio
/// duration, so the text tracks the voice. Layout never reflows — the
/// full text is laid out once, with the unspoken tail transparent.
class SpokenText extends StatelessWidget {
  const SpokenText({
    required this.text,
    required this.startedAt,
    required this.duration,
    this.style,
    super.key,
  });

  final String text;
  final DateTime startedAt;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    if (MediaQuery.of(context).disableAnimations || duration <= Duration.zero) {
      return Text(text, textAlign: TextAlign.center, style: base);
    }
    final elapsed = DateTime.now().difference(startedAt);
    final startFraction = (elapsed.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0);
    final remaining = duration - elapsed;
    return TweenAnimationBuilder<double>(
      key: ValueKey('$text-$startedAt'),
      tween: Tween(begin: startFraction, end: 1),
      duration: remaining > Duration.zero ? remaining : Duration.zero,
      builder: (context, t, _) {
        final cut = revealCut(text, t);
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: text.substring(0, cut)),
              TextSpan(
                text: text.substring(cut),
                style: const TextStyle(color: Colors.transparent),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: base,
        );
      },
    );
  }
}

/// Character index of the last whole word within fraction [t] of the
/// text — reveal advances word by word, proportional to characters
/// (closer to speech cadence than uniform words).
int revealCut(String text, double t) {
  if (t >= 1) return text.length;
  final target = (text.length * t).floor();
  if (target <= 0) return 0;
  final lastSpace = text.lastIndexOf(' ', target.clamp(0, text.length - 1));
  return lastSpace < 0 ? target : lastSpace + 1;
}
