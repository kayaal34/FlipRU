import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../data/models/deck.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/settings_provider.dart';

/// Seviye destesi için tam genişlikte liste satırı.
class DeckRow extends ConsumerWidget {
  const DeckRow({
    required this.deck,
    required this.progress,
    required this.onTap,
    this.locked = false,
    super.key,
  });

  final Deck deck;
  final DeckProgress progress;
  final VoidCallback onTap;

  /// Premium gerektiren desteler kilit rozetiyle gösterilir.
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.separator),
          boxShadow: palette.ambientShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: deck.tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                deck.titleOf(s),
                style: textTheme.labelLarge?.copyWith(
                  color: deck.tint,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.subtitleOf(s), style: textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    progress.isComplete
                        ? '${progress.total} ${s.allDone}'
                        : '${progress.learned} / ${progress.total} '
                            '${s.wordUnit(progress.total)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (locked)
              Icon(Icons.lock_rounded, size: 21, color: palette.star)
            else
            ProgressRing(
              value: progress.ratio,
              color: deck.tint,
              size: 42,
              child: progress.isComplete
                  ? Icon(Icons.check_rounded, size: 20, color: deck.tint)
                  : Text(
                      '${(progress.ratio * 100).round()}',
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Tema destesi için kare kart. Grid içinde kullanılır.
class DeckCard extends ConsumerWidget {
  const DeckCard({
    required this.deck,
    required this.progress,
    required this.onTap,
    this.locked = false,
    super.key,
  });

  final Deck deck;
  final DeckProgress progress;
  final VoidCallback onTap;

  /// Premium gerektiren desteler kilit rozetiyle gösterilir.
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.separator),
          boxShadow: palette.ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: deck.tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(deck.icon, size: 21, color: deck.tint),
                ),
                const Spacer(),
                if (locked)
                  Icon(Icons.lock_rounded, size: 17, color: palette.star),
              ],
            ),
            const Spacer(),
            Text(
              deck.titleOf(s),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(
              '${progress.learned}/${progress.total} '
              '${s.wordUnit(progress.total)}',
              style: textTheme.bodySmall?.copyWith(color: palette.textTertiary),
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.ratio),
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: palette.track,
                  valueColor: AlwaysStoppedAnimation(deck.tint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
