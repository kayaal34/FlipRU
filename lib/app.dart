import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/widget_service.dart';
import 'features/splash/splash_screen.dart';
import 'providers/app_providers.dart';
import 'providers/daily_provider.dart';
import 'providers/report_provider.dart';
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
      // Ağ yokken cihazda kalan hatalı kelime bildirimleri açılışta sessizce
      // yeniden deneniyor; kullanıcının ayarlardaki ekrana girmesi gerekmesin.
      ref.read(reportProvider.notifier).flush();
      _syncReminders();
      _syncWidget();
    });
  }

  /// Ana ekran widget'ının verisini yazar.
  ///
  /// Önümüzdeki dönemlerin kelimeleri peşinen yazılıyor; widget her
  /// yenilendiğinde saate bakıp sırası gelen kelimeyi kendisi seçiyor. Yani
  /// uygulama hiç açılmasa da kelime değişmeye devam ediyor. Aralık ayarı ya
  /// da seri değiştiğinde de çağrılıyor.
  void _syncWidget() {
    const WidgetService().updateSchedule(
      ref.read(wordRepositoryProvider).allWords,
      streak: ref.read(streakProvider),
      lastStudyDay: ref.read(lastStudyDayProvider),
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
    // Hatirlatma artik varsayilan olarak acik geliyor, yani izni kullanicinin
    // bir dugmeye basmasindan once istemek gerekiyor. Tanitim bitene kadar
    // beklemek sart: ilk karsilama ekraninin uzerine sistem izin penceresi
    // acmak, uygulamanin ne oldugunu anlamadan karar vermek demek.
    if (settings.onboardingDone) {
      await service.requestPermission();
    }
    await service.scheduleDaily(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      skipToday: ref.read(dailySummaryProvider).goalReached,
      goal: settings.dailyGoal,
      streak: ref.read(streakProvider),
      studiedToday: ref.read(studiedTodayProvider),
      strings: ref.read(stringsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hatırlatma ayarı ya da bugünün hedef durumu değiştiğinde yeniden planla.
    ref.listen(
      settingsProvider.select(
        (s) => (
          s.reminderEnabled,
          s.reminderHour,
          s.reminderMinute,
          s.dailyGoal,
          s.onboardingDone,
        ),
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
    // Bugünün ilk çalışması seriyi uzatıyor: bu akşamki "serin tehlikede"
    // uyarısı iptal edilmeli, widget'taki alev de güncellenmeli.
    ref.listen(studiedTodayProvider, (_, _) {
      _syncReminders();
      _syncWidget();
    });

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
