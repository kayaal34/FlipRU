import 'package:flutter/material.dart';

/// Uygulamanın tüm semantik renklerini tutan tema eklentisi.
///
/// Renkler doğrudan widget'lara gömülmez; her widget `context.palette`
/// üzerinden okur. Böylece açık/koyu mod geçişi tek noktadan yönetilir.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.track,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSoft,
    required this.learned,
    required this.learnedSoft,
    required this.review,
    required this.reviewSoft,
    required this.star,
    required this.cardShadow,
    required this.ambientShadow,
  });

  /// Scaffold arka planı.
  final Color canvas;

  /// Standart kart / liste satırı yüzeyi.
  final Color surface;

  /// Modal, bottom sheet, öne çıkan kart yüzeyi.
  final Color surfaceRaised;

  /// İçe gömülü alanlar (chip arka planı, segment kontrolü zemini).
  final Color surfaceSunken;

  /// İlerleme çubuğu / halkasının boş kısmı. Kart yüzeyinin üzerinde
  /// durduğu için [surfaceSunken]'dan belirgin biçimde ayrışması gerekiyor.
  final Color track;

  final Color separator;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color accent;
  final Color accentSoft;

  /// "Öğrendim" – sağa kaydırma.
  final Color learned;
  final Color learnedSoft;

  /// "Tekrar et" – sola kaydırma.
  final Color review;
  final Color reviewSoft;

  final Color star;

  /// Flashcard gibi öne çıkan yüzeyler için katmanlı gölge.
  final List<BoxShadow> cardShadow;

  /// Liste kartları için yumuşak, geniş gölge.
  final List<BoxShadow> ambientShadow;

  static const light = AppPalette(
    canvas: Color(0xFFF4F4F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEAEAF0),
    track: Color(0xFFDCDCE6),
    separator: Color(0xFFE4E4EB),
    textPrimary: Color(0xFF0B0B0F),
    textSecondary: Color(0xFF6C6C78),
    textTertiary: Color(0xFFA2A2AE),
    accent: Color(0xFF5E5CE6),
    accentSoft: Color(0xFFEDEDFE),
    learned: Color(0xFF16A34A),
    learnedSoft: Color(0xFFE3F8EA),
    review: Color(0xFFE5342A),
    reviewSoft: Color(0xFFFDE9E7),
    star: Color(0xFFEFA818),
    cardShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 32,
        offset: Offset(0, 18),
        spreadRadius: -6,
      ),
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 8,
        offset: Offset(0, 3),
        spreadRadius: -2,
      ),
    ],
    ambientShadow: [
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 18,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
    ],
  );

  static const dark = AppPalette(
    canvas: Color(0xFF08080B),
    surface: Color(0xFF16161B),
    surfaceRaised: Color(0xFF1F1F26),
    surfaceSunken: Color(0xFF101014),
    track: Color(0xFF34343E),
    separator: Color(0xFF2A2A32),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF9C9CA7),
    textTertiary: Color(0xFF66666F),
    accent: Color(0xFF8886FF),
    accentSoft: Color(0xFF1E1D33),
    learned: Color(0xFF32D373),
    learnedSoft: Color(0xFF12291C),
    review: Color(0xFFFF5A4E),
    reviewSoft: Color(0xFF2B1310),
    star: Color(0xFFFFC93C),
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 36,
        offset: Offset(0, 20),
        spreadRadius: -8,
      ),
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 10,
        offset: Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
    ambientShadow: [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 20,
        offset: Offset(0, 10),
        spreadRadius: -6,
      ),
    ],
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? track,
    Color? separator,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentSoft,
    Color? learned,
    Color? learnedSoft,
    Color? review,
    Color? reviewSoft,
    Color? star,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? ambientShadow,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      track: track ?? this.track,
      separator: separator ?? this.separator,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      learned: learned ?? this.learned,
      learnedSoft: learnedSoft ?? this.learnedSoft,
      review: review ?? this.review,
      reviewSoft: reviewSoft ?? this.reviewSoft,
      star: star ?? this.star,
      cardShadow: cardShadow ?? this.cardShadow,
      ambientShadow: ambientShadow ?? this.ambientShadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      track: Color.lerp(track, other.track, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      learned: Color.lerp(learned, other.learned, t)!,
      learnedSoft: Color.lerp(learnedSoft, other.learnedSoft, t)!,
      review: Color.lerp(review, other.review, t)!,
      reviewSoft: Color.lerp(reviewSoft, other.reviewSoft, t)!,
      star: Color.lerp(star, other.star, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      ambientShadow: BoxShadow.lerpList(ambientShadow, other.ambientShadow, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  /// `context.palette.accent` şeklinde kısa erişim.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
