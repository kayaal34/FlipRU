import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/models/word.dart';

/// Ana ekran widget'ını besler.
///
/// Widget kendi başına veri okuyamaz; uygulama her açıldığında günün kelimesini
/// paylaşılan tercihlere yazıp widget'ı yeniliyoruz.
class WidgetService {
  const WidgetService();

  static const _androidName = 'WordWidgetProvider';

  /// Seçilen aralık içinde hep aynı kelimeyi veren tohum.
  ///
  /// Rastgele seçim her açılışta çalışsaydı kelime saniyede bir değişirdi;
  /// bunun yerine "epoch'tan bu yana kaçıncı pencere" sayısını tohum yapıyoruz.
  /// Böylece 24 saatlik aralıkta kelime gerçekten gün boyu sabit kalıyor,
  /// 6 saatlikte günde dört kez dönüyor.
  static int windowSeed(DateTime now, int hours) =>
      now.millisecondsSinceEpoch ~/ (hours * 3600 * 1000);

  Future<void> updateDailyWord(
    List<Word> pool, {
    int streak = 0,
    int refreshHours = 24,
  }) async {
    if (kIsWeb || pool.isEmpty) return;

    try {
      final seed = windowSeed(DateTime.now(), refreshHours);
      final word = pool[Random(seed).nextInt(pool.length)];

      await HomeWidget.saveWidgetData<String>('widget_russian', word.accented);
      await HomeWidget.saveWidgetData<String>(
        'widget_translit',
        word.transliteration,
      );
      await HomeWidget.saveWidgetData<String>('widget_turkish', word.turkish);
      await HomeWidget.saveWidgetData<String>(
        'widget_level',
        word.level.label,
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_streak',
        streak > 0 ? '🔥 $streak' : '',
      );
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (_) {
      // Widget eklenmemişse ya da platform desteklemiyorsa sessizce geç.
    }
  }
}
