import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import 'game_session.dart';
import 'table_view.dart';

class SeatRing extends ConsumerWidget {
  const SeatRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final seats = session.names.length;
    if (seats == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = seats <= 9 ? 128.0 : 108.0;
        final cardHeight = seats <= 9 ? 128.0 : 118.0;
        final rx = (constraints.maxWidth - cardWidth) / 2 - 8;
        final ry = (constraints.maxHeight - cardHeight) / 2 - 8;
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2;
        return Stack(
          children: [
            for (var seat = 0; seat < seats; seat++)
              Positioned(
                left:
                    cx +
                    rx *
                        cos(
                          pi / 2 + 2 * pi * (seat - session.humanSeat) / seats,
                        ) -
                    cardWidth / 2,
                top:
                    cy +
                    ry *
                        sin(
                          pi / 2 + 2 * pi * (seat - session.humanSeat) / seats,
                        ) -
                    cardHeight / 2,
                width: cardWidth,
                height: cardHeight,
                child: PlayerCard(seat: seat),
              ),
          ],
        );
      },
    );
  }
}

class PlayerCard extends ConsumerWidget {
  const PlayerCard({required this.seat, super.key});

  final int seat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionControllerProvider);
    final view = ref.watch(tableViewProvider);
    final scheme = Theme.of(context).colorScheme;
    final alive = view.isAlive(seat);
    final speaking = view.activeSpeech?.$1 == seat && alive;
    final onTrial = view.onTrial.contains(seat);
    final isHuman = seat == session.humanSeat;
    final mafiaBadged = session.humanIsMafia && view.mafiaTeam.contains(seat);
    final revealedRole = view.revealedRoles[seat];
    final vote = view.lastVotes[seat];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: alive ? 0.92 : 0.55,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: speaking
              ? LlmertaPalette.brass
              : onTrial
              ? LlmertaPalette.blood
              : scheme.outline.withValues(alpha: 0.4),
          width: speaking || onTrial ? 2.5 : 1,
        ),
        boxShadow: speaking
            ? [
                BoxShadow(
                  color: LlmertaPalette.brass.withValues(alpha: 0.45),
                  blurRadius: 14,
                ),
              ]
            : const [],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SeatAvatar(
            name: session.names[seat],
            avatarPath: session.personas[seat]?.avatarPath,
            dead: !alive,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (mafiaBadged)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(Icons.handshake, size: 12),
                ),
              Flexible(
                child: Text(
                  session.names[seat],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isHuman ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            isHuman
                ? 'seat ${seat + 1} · you'
                : 'seat ${seat + 1} · ${session.modelBadges[seat] ?? '?'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          // Uniform for every living seat at night — no timing/role tells.
          if (view.night && alive && !view.over)
            Text(
              '· · ·',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          if (!alive)
            Text(
              revealedRole == null ? 'departed' : 'was ${revealedRole.name}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: LlmertaPalette.blood),
            )
          else if (vote != null && session.names.isNotEmpty)
            Text(
              'voted ${session.names[vote]}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            )
          else if (vote == null && view.lastVotes.containsKey(seat))
            Text('abstained', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  const _SeatAvatar({required this.name, this.avatarPath, required this.dead});

  final String name;
  final String? avatarPath;
  final bool dead;

  @override
  Widget build(BuildContext context) {
    final path = avatarPath;
    final avatar = path != null && File(path).existsSync()
        ? CircleAvatar(radius: 22, backgroundImage: FileImage(File(path)))
        : CircleAvatar(radius: 22, child: Text(name.isEmpty ? '?' : name[0]));
    if (!dead) return avatar;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0.45, child: avatar),
        const Icon(Icons.clear, size: 30, color: LlmertaPalette.blood),
      ],
    );
  }
}
