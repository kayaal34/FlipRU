import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/models/word.dart';

/// Ana ekran widget'ını besler.
///
/// Widget Dart kodu çalıştıramıyor; ama Android onu en fazla yarım saatte
/// bir kendiliğinden yeniliyor. Bu yüzden uygulama açıldığında önümüzdeki
/// dönemlerin kelimelerini tek seferde yazıyoruz; widget yenilendiğinde
/// saate bakıp sırası gelen kelimeyi kendisi seçiyor (bkz.
/// `WordWidgetProvider.kt`). Uygulama günlerce açılmasa da kelime değişiyor —
/// widget'ın asıl işi zaten uygulamayı açmayanı geri getirmek.
class WidgetService {
  const WidgetService();

  static const _androidName = 'WordWidgetProvider';

  /// Peşinen yazılan dönem sayısı. Günlükte dört ay, altı saatlikte bir ay.
  static const scheduleLength = 120;

  /// Seçilen aralık içinde hep aynı kelimeyi veren tohum.
  ///
  /// "Epoch'tan bu yana kaçıncı pencere" sayısı: 24 saatlik aralıkta kelime
  /// gün boyu sabit kalıyor, 6 saatlikte günde dört kez dönüyor. Aynı hesap
  /// Kotlin tarafında da yapılıyor, iki taraf aynı pencereyi buluyor.
  static int windowSeed(DateTime now, int hours) =>
      now.millisecondsSinceEpoch ~/ (hours * 3600 * 1000);

  /// Pencereye düşen kelime; tohum sabit olduğu için hep aynı kelime çıkıyor.
  static Word wordFor(List<Word> pool, int window) =>
      pool[Random(window).nextInt(pool.length)];

  Future<void> updateSchedule(
    List<Word> pool, {
    int streak = 0,
    String? lastStudyDay,
    int refreshHours = 24,
  }) async {
    if (kIsWeb || pool.isEmpty) return;

    try {
      final first = windowSeed(DateTime.now(), refreshHours);
      final entries = [
        for (var w = first; w < first + scheduleLength; w++)
          _entry(wordFor(pool, w), w),
      ];

      await HomeWidget.saveWidgetData<String>(
        'widget_schedule',
        json.encode(entries),
      );
      // Sayılar metin olarak: kanal küçük tamsayıyı Int, büyüğünü Long diye
      // taşıyor; Kotlin tarafında tür tahmin etmekle uğraşmayalım.
      await HomeWidget.saveWidgetData<String>(
        'widget_refresh_hours',
        '$refreshHours',
      );
      await HomeWidget.saveWidgetData<String>('widget_streak_count', '$streak');
      await HomeWidget.saveWidgetData<String>(
        'widget_last_study_day',
        lastStudyDay ?? '',
      );

      // Takvim okunamazsa widget'ın göstereceği yedek: şu anki kelime.
      final now = wordFor(pool, first);
      await HomeWidget.saveWidgetData<String>('widget_russian', now.accented);
      await HomeWidget.saveWidgetData<String>(
        'widget_translit',
        now.transliteration,
      );
      await HomeWidget.saveWidgetData<String>('widget_turkish', now.turkish);
      await HomeWidget.saveWidgetData<String>('widget_level', now.level.label);

      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (_) {
      // Widget eklenmemişse ya da platform desteklemiyorsa sessizce geç.
    }
  }

  Map<String, Object> _entry(Word word, int window) => {
    'w': window,
    'ru': word.accented,
    'tl': word.transliteration,
    'tr': word.turkish,
    'lv': word.level.label,
  };

  /// Ana ekranda en az bir FlipRU widget'ı var mı?
  Future<bool> isInstalled() async {
    if (kIsWeb) return false;
    try {
      final list = await HomeWidget.getInstalledWidgets();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Launcher destekliyorsa widget'ı tek dokunuşla ana ekrana ekletir.
  Future<bool> canPin() async {
    if (kIsWeb) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPin() async {
    try {
      await HomeWidget.requestPinWidget(androidName: _androidName);
    } catch (_) {}
  }
}
