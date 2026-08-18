import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'pressable.dart';

/// Yıldızlı kelimeler kartı.
///
/// Ana ekranda ve Testler ekranında aynı kart görünüyor; ikisi de bu
/// bileşeni kullanıyor. Daha önce Testler ekranı düz bir liste satırıydı,
/// ana ekran ise degradeli bu kart — aynı şeyin iki farklı görünmesi
/// kullanıcıyı yanıltıyordu.
///
/// Kart eskiden baştan sona degrade ve parlamalıydı; yanındaki "Öğrendiğim
/// Kelimeler" kartı ise düz zeminliydi. Aynı düzeydeki iki girişten birinin
/// bu kadar öne çıkması gereksiz bir vurguydu ve asıl içeriğe (seviyeler ve
/// temalar) giden yolu gölgeliyordu. Artık ikisi de aynı dili konuşuyor:
/// düz zemin, ince çerçeve, rengi yalnızca simgesinde.
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.separator),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.star.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.star_rounded,
                color: palette.star,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
