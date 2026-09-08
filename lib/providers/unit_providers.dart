import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/study_unit.dart';
import 'app_providers.dart';
import 'library_providers.dart';

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

  /// Yalnizca QA derlemesi icin: verilen butun bolum/test kimliklerini tek
  /// seferde gecilmis isaretler.
  void seedAll(Iterable<String> unitIds) {
    state = {...unitIds};
    ref.read(sharedPreferencesProvider).setStringList(_key, state.toList());
  }
}

final passedUnitsProvider = NotifierProvider<PassedUnitsNotifier, Set<String>>(
  PassedUnitsNotifier.new,
);

/// Bir bölüm/yazma testi tam puanla geçilemeden yarıda bırakılırsa, o turda
/// yanlış yapılan kelimeler burada saklanıyor.
///
/// Önceden bu yalnızca ekranın kendi State'inde tutuluyordu: "Bitir"e basıp
/// çıkan kullanıcı bölümü yeniden açtığında bütün bölüm baştan soruluyordu,
/// oysa "Yanlışlarına dön" ile aynı ekranda kalsaydı yalnızca yanlışları
/// görecekti. Artık bu tutarsızlık yok: nereden çıkarsa çıksın, bölüme dönen
/// kullanıcı kaldığı yerden — yalnızca hâlâ bilmediği kelimelerden — devam
/// ediyor. Tamamı doğru cevaplanınca kayıt siliniyor.
class PendingWrongNotifier extends Notifier<Map<String, List<String>>> {
  static const _key = 'pending_wrong_words';

  @override
  Map<String, List<String>> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        entry.key: (entry.value as List).cast<String>(),
    };
  }

  void setWrong(String testId, List<String> wordIds) {
    final next = {...state};
    if (wordIds.isEmpty) {
      next.remove(testId);
    } else {
      next[testId] = wordIds;
    }
    _persist(next);
  }

  void clear(String testId) {
    if (!state.containsKey(testId)) return;
    _persist({...state}..remove(testId));
  }

  void _persist(Map<String, List<String>> value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, json.encode(value));
  }
}

final pendingWrongProvider =
    NotifierProvider<PendingWrongNotifier, Map<String, List<String>>>(
      PendingWrongNotifier.new,
    );

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
  final pendingWrong = ref.watch(pendingWrongProvider);
  final units = StudyUnit.split(deckId, words);

  // Sirali ilerleme: bir onceki bolum gecilmeden sonraki acilmaz. Onceden
  // iki bolum birden acikti; kullanici "neden ikisi de acik" diye sordu ve
  // hakliydi — bolum testi tam puan istiyorsa yol da tek olmali.
  const lookahead = 1;
  var lastPassed = -1;
  final passedFlags = <bool>[];
  for (var i = 0; i < units.length; i++) {
    final count = units[i].words.where((w) => learned.contains(w.id)).length;
    final passed =
        passedByTest.contains(units[i].id) || count >= units[i].passThreshold;
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
        pendingWrong: pendingWrong[units[i].id]?.length ?? 0,
      ),
  ];
});
