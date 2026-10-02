import 'package:flutter/material.dart';

/// Tipografi ölçeği.
///
/// Inter uygulamaya gömülü (bkz. `pubspec.yaml`): hem Latin hem Kiril
/// (Кириллица) desteği tam, vurgu işaretini (U+0301) doğru konumlandırıyor ve
/// SF Pro'ya çok yakın metrikleri var. Gömülü olduğu için ilk açılışta ağ
/// gerekmiyor.
///
/// Başlıklar Outfit: yuvarlak hatları ekrana daha sıcak ve ferah bir hava
/// veriyor. Outfit'te Kiril yok; Rusça başlıklar Inter'e düşüyor.
abstract final class AppTypography {
  static const family = 'Inter';
  static const displayFamily = 'Outfit';

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required double spacing,
    required double height,
    required Color color,
    bool display = false,
  }) => TextStyle(
    fontFamily: display ? displayFamily : family,
    fontFamilyFallback: display ? const [family] : null,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
    color: color,
  );

  /// Rusça kelimenin kart üzerinde gösterildiği "hero" stil.
  static TextStyle hero(Color color) => _base(
    size: 46,
    weight: FontWeight.w700,
    spacing: -1.4,
    height: 1.08,
    color: color,
  );

  /// Ana ekran büyük başlığı (iOS Large Title).
  static TextStyle largeTitle(Color color) => _base(
    size: 34,
    weight: FontWeight.w600,
    spacing: -0.6,
    height: 1.12,
    color: color,
    display: true,
  );

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: _base(
        size: 40,
        weight: FontWeight.w700,
        spacing: -0.8,
        height: 1.1,
        color: primary,
        display: true,
      ),
      headlineLarge: _base(
        size: 30,
        weight: FontWeight.w600,
        spacing: -0.5,
        height: 1.16,
        color: primary,
        display: true,
      ),
      headlineMedium: _base(
        size: 24,
        weight: FontWeight.w600,
        spacing: -0.3,
        height: 1.2,
        color: primary,
        display: true,
      ),
      titleLarge: _base(
        size: 19,
        weight: FontWeight.w600,
        spacing: -0.2,
        height: 1.25,
        color: primary,
        display: true,
      ),
      titleMedium: _base(
        size: 17,
        weight: FontWeight.w600,
        spacing: -0.1,
        height: 1.3,
        color: primary,
        display: true,
      ),
      bodyLarge: _base(
        size: 17,
        weight: FontWeight.w400,
        spacing: -0.2,
        height: 1.45,
        color: primary,
      ),
      bodyMedium: _base(
        size: 15,
        weight: FontWeight.w400,
        spacing: -0.1,
        height: 1.45,
        color: secondary,
      ),
      bodySmall: _base(
        size: 13,
        weight: FontWeight.w400,
        spacing: 0,
        height: 1.4,
        color: secondary,
      ),
      labelLarge: _base(
        size: 15,
        weight: FontWeight.w600,
        spacing: -0.2,
        height: 1.2,
        color: primary,
      ),
      labelMedium: _base(
        size: 13,
        weight: FontWeight.w600,
        spacing: 0,
        height: 1.2,
        color: secondary,
      ),

      /// Chip / rozet metinleri – büyük harf, geniş harf aralığı.
      labelSmall: _base(
        size: 11,
        weight: FontWeight.w700,
        spacing: 0.8,
        height: 1.2,
        color: secondary,
      ),
    );
  }
}
