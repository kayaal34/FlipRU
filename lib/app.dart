import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/widget_service.dart';
import 'features/splash/splash_screen.dart';
import 'providers/app_providers.dart';
import 'providers/daily_provider.dart';
import 'providers/settings_provider.dart';

class FlipRuApp extends ConsumerStatefulWidget {
  const FlipRuApp({super.key});

  @override
  ConsumerState<FlipRuApp> createState() => _FlipRuAppState();
}

class _FlipRuAppState extends ConsumerState<FlipRuApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Seri, uygulamanın açıldığı günlerden hesaplanıyor.
      ref.read(visitProvider.notifier).recordToday();
      _syncReminders();
      _syncWidget();
    });
  }

  /// Ana ekran widget'ındaki kelimeyi tazeler.
  ///
  /// Widget'ın kendi zamanlayıcısı yok; uygulama açıldığında hangi zaman
  /// penceresinde olduğumuza bakıp kelimeyi yazıyoruz. Aralık ayarı
  /// değiştiğinde de çağrılıyor, yoksa kullanıcı seçimini bir sonraki
  /// açılışa kadar göremezdi.
  void _syncWidget() {
    const WidgetService().updateDailyWord(
      ref.read(wordRepositoryProvider).allWords,
      streak: ref.read(streakProvider),
      refreshHours: ref.read(settingsProvider).widgetRefresh.hours,
    );
  }

  /// Hatırlatmaları yeniden planlar.
  ///
  /// Arka plan görevi yok: uygulama her açıldığında ve ilgili durum
  /// değiştiğinde önümüzdeki bir haftalık bildirimler kuruluyor. Hedef bugün
  /// tamamlandıysa bugünün bildirimi atlanıyor.
  Future<void> _syncReminders() async {
    final settings = ref.read(settingsProvider);
    final service = ref.read(notificationServiceProvider);

    if (!settings.reminderEnabled) {
      await service.cancelAll();
      return;
    }
    await service.scheduleDaily(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      skipToday: ref.read(dailySummaryProvider).goalReached,
      goal: settings.dailyGoal,
      strings: ref.read(stringsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hatırlatma ayarı ya da bugünün hedef durumu değiştiğinde yeniden planla.
    ref.listen(
      settingsProvider.select(
        (s) => (s.reminderEnabled, s.reminderHour, s.reminderMinute, s.dailyGoal),
      ),
      (_, _) => _syncReminders(),
    );
    ref.listen(
      dailySummaryProvider.select((s) => s.goalReached),
      (_, _) => _syncReminders(),
    );
    ref.listen(
      settingsProvider.select((s) => s.widgetRefresh),
      (_, _) => _syncWidget(),
    );

    return MaterialApp(
      title: 'FlipRU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(settingsProvider.select((s) => s.themeMode)),
      home: const SplashScreen(),
      // Sistem yazı tipi ölçeğini makul bir aralıkta tutuyoruz; aksi hâlde
      // %200 ölçekte kart içerikleri taşıyor.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.25,
        child: child!,
      ),
    );
  }
}
