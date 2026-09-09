import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final textTheme = AppTypography.textTheme(p.textPrimary, p.textSecondary);
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      textTheme: textTheme,
      extensions: [p],
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: p.accent,
            brightness: brightness,
          ).copyWith(
            primary: p.accent,
            surface: p.surface,
            onSurface: p.textPrimary,
            error: p.review,
          ),
      // iOS'taki gibi kenardan kaydırarak geri gitme, Android'de de aktif.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: p.separator,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          // Koyu temada vurgu rengi açık mor; üzerinde beyaz yazı yalnızca
          // 3.04:1 kontrast veriyordu (AA için 4.5 gerek). Koyu zemin
          // rengiyle 6.5:1'e çıkıyor.
          foregroundColor: p.isDark ? p.canvas : Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          // Size.fromHeight en az genişliği de sonsuz yapıyor: her metin
          // düğmesi satırın tamamını kaplıyordu. Uyarı pencerelerinde iki
          // düğme yan yana sığmayıp alt alta diziliyor, tanıtımdaki "Atla"
          // ise sağa yaslanmış görünmüyordu. Yükseklik dokunma hedefi için
          // kalıyor, genişlik içeriğe göre.
          minimumSize: const Size(64, 50),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}
