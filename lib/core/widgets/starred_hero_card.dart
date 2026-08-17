import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'pressable.dart';

/// Yıldızlı kelimeler kartı.
///
/// Ana ekranda ve Testler ekranında aynı kart görünüyor; ikisi de bu
/// bileşeni kullanıyor. Daha önce Testler ekranı düz bir liste satırıydı,
/// ana ekran ise degradeli bu kart — aynı şeyin iki farklı görünmesi
/// kullanıcıyı yanıltıyordu.
class StarredHeroCard extends StatelessWidget {
  const StarredHeroCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.accent,
              Color.lerp(palette.accent, palette.star, 0.45)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.32),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
