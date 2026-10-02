import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/pressable.dart';
import '../../../data/models/deck.dart';
import '../../../providers/library_providers.dart';
import '../../../providers/settings_provider.dart';

/// Seviye destesi için tam genişlikte liste satırı.
class DeckRow extends ConsumerWidget {
  const DeckRow({
    required this.deck,
    required this.progress,
    required this.onTap,
    super.key,
  });

  final Deck deck;
  final DeckProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    final percent = (progress.ratio * 100).round();
    final status = progress.isComplete ? s.levelComplete : s.percent(percent);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: palette.ambientShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: deck.tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                deck.titleOf(s),
                style: textTheme.labelLarge?.copyWith(
                  color: deck.tint,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Halka yerine yazı + çubuk: "692 / 692 kelime · Tamamlandı"
            // tek bakışta okunuyor, "tamamının tamamı tamam" tekrarı yok.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.subtitleOf(s),
                    style: textTheme.titleMedium?.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.number(progress.learned)} / '
                    '${s.number(progress.total)} '
                    '${s.wordUnit(progress.total)} · $status',
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.ratio,
                      minHeight: 6,
                      color: deck.tint,
                      backgroundColor: palette.track,
                    ),
                  ),
                ],
              ),
            ),
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
    super.key,
  });

  final Deck deck;
  final DeckProgress progress;
  final VoidCallback onTap;

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
