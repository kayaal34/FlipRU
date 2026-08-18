import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/flip_logo.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/settings_provider.dart';
import 'onboarding_screen.dart';

/// İlk açılışta arayüz dilini sorar.
///
/// Tanıtımdan önce geliyor: tanıtım metinlerinin iki dili de hazır, ama dil
/// seçilmeden gösterilirse Rusça kullanacak biri Türkçe metinlerle
/// karşılaşıyordu. Bu ekranda çevrilecek hiçbir metin yok — seçenekler kendi
/// dillerinde yazılı, o yüzden hangi dil varsayılan olursa olsun doğru
/// görünüyor.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  void _pick(BuildContext context, WidgetRef ref, AppLanguage language) {
    Haptics.selection();
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(language: language));
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FlipLogo(size: 84),
                  const SizedBox(height: 22),
                  Text(
                    'FlipRU',
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: 30,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dil · Язык',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: palette.textTertiary),
                  ),
                  const SizedBox(height: 34),
                  _LanguageOption(
                    title: 'Türkçe',
                    subtitle: 'Arayüz Türkçe olsun',
                    onTap: () => _pick(context, ref, AppLanguage.tr),
                  ),
                  const SizedBox(height: 12),
                  _LanguageOption(
                    title: 'Русский',
                    subtitle: 'Интерфейс на русском',
                    onTap: () => _pick(context, ref, AppLanguage.ru),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sonradan ayarlardan değiştirilebilir.\n'
                    'Позже можно изменить в настройках.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.separator),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleLarge),
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
              size: 26,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
