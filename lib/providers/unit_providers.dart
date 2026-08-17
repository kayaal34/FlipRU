import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/study_unit.dart';
import 'app_providers.dart';
import 'library_providers.dart';
import 'premium_provider.dart';

/// Testi geçilerek tamamlanan bölümler.
///
/// Kullanıcı kelimeleri kartla tek tek işaretlemek yerine bölüm testini
/// geçerek de ilerleyebiliyor; bu küme o yolu kaydediyor.
class PassedUnitsNotifier extends Notifier<Set<String>> {
  static const _key = 'passed_units';

  @override
  Set<String> build() {
    final stored = ref.read(sharedPreferencesProvider).getStringList(_key);
    return {...?stored};
  }

  void markPassed(String unitId) {
    if (state.contains(unitId)) return;
    final next = {...state, unitId};
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next.toList());
  }

  void clear() {
    state = const {};
    ref.read(sharedPreferencesProvider).setStringList(_key, const []);
  }
}

final passedUnitsProvider =
    NotifierProvider<PassedUnitsNotifier, Set<String>>(PassedUnitsNotifier.new);

/// Bir destenin bölümleri, kullanıcı ilerlemesiyle birlikte.
///
/// Tek provider hem bölümü hem durumunu döndürüyor: bölüm listesi ekranının
/// ihtiyacı olan her şey burada, kilit hesabı tek yerde.
final deckUnitsProvider = Provider.family<List<UnitProgress>, String>((
  ref,
  deckId,
) {
  final words = ref.watch(deckWordsProvider(deckId));
  final learned = ref.watch(learnedProvider);
  final passedByTest = ref.watch(passedUnitsProvider);
  final premium = ref.watch(isPremiumProvider);
  final units = StudyUnit.split(deckId, words);

  // Premium'da sirali ilerleme sarti yok: abone olan her bolume istedigi an
  // girebilsin, "once sunu bitir" duvariyla karsilasmasin.
  if (premium) {
    return [
      for (final unit in units)
        UnitProgress(
          unit: unit,
          learned: unit.words.where((w) => learned.contains(w.id)).length,
          unlocked: true,
          testPassed: passedByTest.contains(unit.id),
        ),
    ];
  }

  // Geçilen son bölümden sonra iki bölüm açık kalıyor: kullanıcı bir bölümü
  // bitirdiğinde önünde her zaman seçenek olsun, tek bir dar yol olmasın.
  const lookahead = 2;
  var lastPassed = -1;
  final passedFlags = <bool>[];
  for (var i = 0; i < units.length; i++) {
    final count =
        units[i].words.where((w) => learned.contains(w.id)).length;
    final passed = passedByTest.contains(units[i].id) ||
        count >= units[i].passThreshold;
    passedFlags.add(passed);
    if (passed) lastPassed = i;
  }

  return [
    for (var i = 0; i < units.length; i++)
      UnitProgress(
        unit: units[i],
        learned: units[i].words.where((w) => learned.contains(w.id)).length,
        unlocked: i <= lastPassed + lookahead,
        testPassed: passedByTest.contains(units[i].id),
      ),
  ];
});
