import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/i18n/strings.dart';
import '../../../data/models/word.dart';
import 'flip_card.dart';

/// Kaydırılabilir desteyi oluşturan tek bir kelime kartı.
///
/// [dragPercent] sürüklemenin kaydırma eşiğine oranıdır: 1.0 = eşiğe ulaşıldı,
/// negatif değer sola sürüklemeyi gösterir.
class Flashcard extends StatelessWidget {
  const Flashcard({
    required this.word,
    required this.isFlipped,
    required this.isStarred,
    required this.onFlip,
    required this.onStarToggle,
    required this.onSpeak,
    required this.onReport,
    required this.strings,
    this.reversed = false,
    this.showTransliteration = true,
    this.showStressMarks = true,
    this.dragPercent = 0,
    super.key,
  });

  final Word word;
  final bool isFlipped;
  final bool isStarred;
  final VoidCallback onFlip;
  final VoidCallback onStarToggle;
  final ValueChanged<String> onSpeak;

  /// Hatalı çeviri/örnek bildirimi.
  final VoidCallback onReport;

  final Strings strings;

  /// true ise ön yüzde Türkçe anlam, arka yüzde Rusça kelime görünür.
  final bool reversed;

  final bool showTransliteration;
  final bool showStressMarks;
  final double dragPercent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // Kullanıcı eşiğe varmadan kararını görsün: %55'te katman tam görünür.
    final intensity = (dragPercent.abs() / 0.55).clamp(0.0, 1.0);
    final isLearnDirection = dragPercent > 0;
    final feedbackColor = isLearnDirection ? palette.learned : palette.review;

    final russianFace = _RussianFace(
      strings: strings,
      word: word,
      showTransliteration: showTransliteration,
      showStressMarks: showStressMarks,
      isPrompt: !reversed,
    );
    final meaningFace = _MeaningFace(
      strings: strings,
      word: word,
      onSpeak: onSpeak,
      onReport: onReport,
      isPrompt: reversed,
      showTransliteration: showTransliteration,
      showStressMarks: showStressMarks,
    );

    return GestureDetector(
      onTap: () {
        Haptics.light();
        onFlip();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlipCard(
            showBack: isFlipped,
            front: _CardShell(
              word: word,
              feedbackColor: feedbackColor,
              intensity: intensity,
              child: reversed ? meaningFace : russianFace,
            ),
            back: _CardShell(
              word: word,
              feedbackColor: feedbackColor,
              intensity: intensity,
              child: reversed ? russianFace : meaningFace,
            ),
          ),
          // Yıldız ve hoparlör kartın dönmesinden etkilenmesin diye
          // FlipCard'ın dışında, sabit konumda duruyor.
          Positioned(
            top: 18,
            right: 18,
            child: _StarButton(isStarred: isStarred, onTap: onStarToggle),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: _CircleIconButton(
              icon: Icons.volume_up_rounded,
              onTap: () => onSpeak(word.russian),
              tooltip: strings.listen,
            ),
          ),
          if (intensity > 0.02)
            Positioned(
              top: 78,
              left: isLearnDirection ? 24 : null,
              right: isLearnDirection ? null : 24,
              child: _SwipeBadge(
                label: isLearnDirection
                    ? strings.badgeLearned
                    : strings.badgeReview,
                icon: isLearnDirection
                    ? Icons.check_rounded
                    : Icons.refresh_rounded,
                color: feedbackColor,
                intensity: intensity,
                tiltLeft: isLearnDirection,
              ),
            ),
        ],
      ),
    );
  }
}

/// Ortak kart gövdesi: yüzey, kenarlık, gölge ve sürükleme geri bildirimi.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.word,
    required this.child,
    required this.feedbackColor,
    required this.intensity,
  });

  final Word word;
  final Widget child;
  final Color feedbackColor;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Color.lerp(palette.separator, feedbackColor, intensity)!,
          width: 1 + intensity * 1.6,
        ),
        boxShadow: palette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Kelimenin temasından (yoksa seviyesinden) gelen yumuşak renk sisi.
            Positioned(
              top: -140,
              left: -60,
              right: -60,
              height: 320,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      word.tint.withValues(alpha: 0.16),
                      word.tint.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            child,
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: intensity * 0.14,
                duration: const Duration(milliseconds: 90),
                child: ColoredBox(color: feedbackColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rusça kelime yüzü. [isPrompt] true ise soru yüzü (ipucu metni gösterir).
class _RussianFace extends StatelessWidget {
  const _RussianFace({
    required this.strings,
    required this.word,
    required this.showTransliteration,
    required this.showStressMarks,
    required this.isPrompt,
  });

  final Strings strings;
  final Word word;
  final bool showTransliteration;
  final bool showStressMarks;
  final bool isPrompt;

  /// Uzun kalıplar taşmasın diye punto uzunluğa göre kademeli küçülüyor.
  double _heroSize(String text) {
    if (text.length <= 8) return 50;
    if (text.length <= 13) return 42;
    if (text.length <= 20) return 34;
    return 27;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final display = showStressMarks ? word.accented : word.russian;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 26),
      child: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: word.level.label, color: word.tint),
              const SizedBox(width: 8),
              _Chip(
                label: strings.posName(word.partOfSpeech),
                color: palette.textTertiary,
                filled: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            display,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppTypography.hero(
              palette.textPrimary,
            ).copyWith(fontSize: _heroSize(word.russian)),
          ),
          if (showTransliteration) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette.surfaceSunken,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                word.transliteration,
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (isPrompt) _TapHint(label: strings.tapForMeaning),
        ],
      ),
    );
  }
}

/// Türkçe anlam + örnek cümle yüzü.
class _MeaningFace extends StatelessWidget {
  const _MeaningFace({
    required this.strings,
    required this.word,
    required this.onSpeak,
    required this.onReport,
    required this.isPrompt,
    required this.showTransliteration,
    required this.showStressMarks,
  });

  final Strings strings;
  final Word word;
  final ValueChanged<String> onSpeak;
  final VoidCallback onReport;
  final bool isPrompt;
  final bool showTransliteration;
  final bool showStressMarks;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    // Soru yüzüyken sadece anlamı ortada göster; cevap yüzüyken detay ver.
    if (isPrompt) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 72, 28, 26),
        child: Column(
          children: [
            const Spacer(),
            _Chip(label: word.level.label, color: word.tint),
            const SizedBox(height: 24),
            Text(
              word.turkish,
              textAlign: TextAlign.center,
              maxLines: 4,
              style: AppTypography.hero(
                palette.textPrimary,
              ).copyWith(fontSize: word.turkish.length <= 14 ? 38 : 29),
            ),
            const Spacer(),
            _TapHint(label: strings.tapForRussian),
          ],
        ),
      );
    }

    // Center + SingleChildScrollView: içerik sığdığında dikeyde ortalanır,
    // uzun örnek cümlelerde kaydırılabilir kalır.
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 26),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(strings.meaning),
              const SizedBox(height: 8),
              Text(
                word.turkish,
                style: textTheme.headlineMedium?.copyWith(
                  color: palette.textPrimary,
                  height: 1.25,
                ),
              ),
              if (showTransliteration) ...[
                const SizedBox(height: 10),
                Text(
                  '${showStressMarks ? word.accented : word.russian}'
                  '  ·  ${word.transliteration}',
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (word.hasExample) ...[
                const SizedBox(height: 22),
                Divider(color: palette.separator, height: 1),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _SectionLabel(strings.example),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Haptics.light();
                        onSpeak(word.exampleRu);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          size: 17,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  word.exampleRu,
                  style: textTheme.bodyLarge?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  word.exampleTr,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Sözlük verisi otomatik derlendiği için hata bildirimi
              // cevabın hemen yanında dursun.
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.light();
                    onReport();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 14,
                          color: palette.textTertiary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          strings.reportWord,
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textTertiary,
                            decoration: TextDecoration.underline,
                            decorationColor: palette.textTertiary,
                          ),
                        ),
                      ],
                    ),
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

class _TapHint extends StatelessWidget {
  const _TapHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_rounded, size: 15, color: palette.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.textTertiary),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: context.palette.textTertiary),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.filled = true});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({required this.isStarred, required this.onTap});

  final bool isStarred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isStarred
              ? palette.star.withValues(alpha: 0.15)
              : palette.surfaceSunken,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
          child: Icon(
            isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
            key: ValueKey(isStarred),
            size: 23,
            color: isStarred ? palette.star : palette.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.light();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceSunken,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 21, color: palette.textSecondary),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Sürükleme yönüne göre beliren "ÖĞRENDİM" / "TEKRAR" rozeti.
class _SwipeBadge extends StatelessWidget {
  const _SwipeBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.intensity,
    required this.tiltLeft,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double intensity;
  final bool tiltLeft;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: intensity,
      child: Transform.rotate(
        angle: tiltLeft ? -0.18 : 0.18,
        child: Transform.scale(
          scale: 0.86 + intensity * 0.14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
