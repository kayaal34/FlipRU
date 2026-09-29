import '../../data/models/word.dart';
import '../i18n/strings.dart';
import 'widget_service.dart';

/// Günün kelimesi bildiriminin (başlık, gövde) metni.
///
/// Kelime widget'taki günlük kelimeyle aynı hesaptan geliyor: bildirime
/// dokunup widget'a bakan kullanıcı aynı kelimeyi görüyor. Rusça arayüzde
/// (Türkçe öğrenen) başlıkta Türkçe kelime, gövdede okunuşu ve Rusçası var.
(String, String) wordOfDayContent({
  required List<Word> pool,
  required DateTime when,
  required Strings strings,
  required bool learningTurkish,
}) {
  final word = WidgetService.wordFor(pool, WidgetService.windowSeed(when, 24));
  if (learningTurkish) {
    final head = word.turkish.split(' / ').first;
    final reading = word.turkishTranslit.isEmpty
        ? ''
        : '${word.turkishTranslit} · ';
    return (
      strings.wordOfDayNotifTitle.replaceFirst('{}', head),
      '$reading${word.russian}',
    );
  }
  return (
    strings.wordOfDayNotifTitle.replaceFirst('{}', word.accented),
    '${word.transliteration} · ${word.turkish}',
  );
}
