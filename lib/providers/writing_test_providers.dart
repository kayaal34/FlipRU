import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/word.dart';
import 'app_providers.dart';
import 'unit_providers.dart';

/// Yazma testlerinin sayısı.
///
/// Başlangıç için bu kadar; ilerleyen sürümlerde havuz genişletilebilir.
const kWritingTestCount = 25;

/// İlk bu kadar test beş soruluk, sonrakiler on soruluk.
const _shortTests = 8;

/// Havuza giren en uzun kelime.
///
/// Yirmi harflik bir kelimeyi harf harf kurmak alıştırma değil eziyet;
/// başlangıç testlerinde işi yormaya çevirmiyoruz.
const _maxLetters = 10;

/// Havuza giren en kisa kelime.
///
/// Tek ya da iki harfli kelimelerin cogu edat ve baglac ("в", "и", "с");
/// bunlari harf harf kurmak alistirma sayilmaz.
const _minLetters = 3;

/// Havuza giren seviyeler.
///
/// C1 ve B2 dışarıda: yazma pratiği kelimeyi baştan kurmayı istiyor, ileri
/// seviye kelimeler bunun için fazla ağır. Sürüm geldikçe üst seviyeler
/// eklenebilir.
const _levels = {'a1', 'a2', 'b1'};

@immutable
class WritingTest {
  const WritingTest({
    required this.index,
    required this.words,
    required this.unlocked,
    required this.passed,
  });

  /// 1'den başlayan sıra numarası.
  final int index;
  final List<Word> words;
  final bool unlocked;
  final bool passed;

  String get id => 'yazma_$index';
}

/// Zorluğa göre sıralanmış yazma havuzu.
///
/// Sıralama seviyeye, sonra harf sayısına, sonra kimliğe bakıyor. Kimlik
/// son ölçüt olduğu için sıra her açılışta aynı: bir testin soruları
/// değişmiyor, "geçtim" işareti anlamını koruyor.
final _writingPoolProvider = Provider<List<Word>>((ref) {
  final seviyeSirasi = ['a1', 'a2', 'b1'];
  final words = [
    for (final word in ref.watch(wordRepositoryProvider).allWords)
      if (_levels.contains(word.level.name) &&
          word.russian.replaceAll(RegExp(r'[ -]'), '').length >= _minLetters &&
          word.russian.replaceAll(RegExp(r'[ -]'), '').length <= _maxLetters)
        word,
  ];
  words.sort((a, b) {
    final s = seviyeSirasi.indexOf(a.level.name) -
        seviyeSirasi.indexOf(b.level.name);
    if (s != 0) return s;
    final u = a.russian.length - b.russian.length;
    if (u != 0) return u;
    return a.id.compareTo(b.id);
  });
  return words;
});

/// Kaçıncı testin kaç soru sorduğu.
int writingTestSize(int index) => index <= _shortTests ? 5 : 10;

/// Yazma testleri, sırayla açılan hâlleriyle.
final writingTestsProvider = Provider<List<WritingTest>>((ref) {
  final havuz = ref.watch(_writingPoolProvider);
  final gecilen = ref.watch(passedUnitsProvider);
  if (havuz.isEmpty) return const [];

  // Havuz eşit dilimlere bölünüyor ve her test kendi diliminin başından
  // soruları alıyor. Böylece ilk testler havuzun en kolay ucundan, son
  // testler en zor ucundan geliyor; arada düzgün bir tırmanış oluyor.
  final dilim = havuz.length ~/ kWritingTestCount;

  final testler = <WritingTest>[];
  var oncekiGecildi = true;
  for (var i = 1; i <= kWritingTestCount; i++) {
    final adet = writingTestSize(i);
    final basi = (i - 1) * dilim;
    final kelimeler = havuz.skip(basi).take(adet).toList();
    if (kelimeler.length < adet) break;

    final id = 'yazma_$i';
    final gecti = gecilen.contains(id);
    testler.add(WritingTest(
      index: i,
      words: kelimeler,
      // İlk test hep açık; sonrakiler bir öncekini geçince açılıyor.
      unlocked: oncekiGecildi,
      passed: gecti,
    ));
    oncekiGecildi = gecti;
  }
  return testler;
});
