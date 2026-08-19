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

/// Yazma yönü.
enum WritingDirection {
  /// Türkçe anlamı gösterilir, Rusçası yazılır.
  trToRu,

  /// Rusça kelime gösterilir, Türkçe karşılığı yazılır.
  ruToTr,
}

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
    required this.direction,
    required this.words,
    required this.unlocked,
    required this.passed,
  });

  /// 1'den başlayan sıra numarası.
  final int index;
  final WritingDirection direction;
  final List<Word> words;
  final bool unlocked;
  final bool passed;

  /// Iki yonun ilerlemesi ayri tutuluyor.
  String get id =>
      direction == WritingDirection.trToRu ? 'yazma_$index' : 'anlam_$index';
}

/// Zorluğa göre sıralanmış yazma havuzu.
///
/// Sıralama seviyeye, sonra harf sayısına, sonra kimliğe bakıyor. Kimlik
/// son ölçüt olduğu için sıra her açılışta aynı: bir testin soruları
/// değişmiyor, "geçtim" işareti anlamını koruyor.
/// Yazılacak metin: yöne göre Rusça kelime ya da Türkçe karşılık.
String writingAnswer(Word word, WritingDirection direction) =>
    direction == WritingDirection.trToRu
        ? word.russian.toLowerCase()
        : word.turkish.toLowerCase();

/// Türkçe tarafta yalnızca düz karşılıklar işe yarıyor.
///
/// Virgüllü, parantezli ya da Türkçe alfabede olmayan harf taşıyan kayıtlar
/// harf harf yazdırılamaz; havuza alınmıyor.
final _duzTurkce = RegExp(r'^[a-zçğıöşü ]+$');

final _writingPoolProvider =
    Provider.family<List<Word>, WritingDirection>((ref, direction) {
  final seviyeSirasi = ['a1', 'a2', 'b1'];
  int harfSayisi(Word w) =>
      writingAnswer(w, direction).replaceAll(RegExp(r'[ -]'), '').length;

  final words = [
    for (final word in ref.watch(wordRepositoryProvider).allWords)
      if (_levels.contains(word.level.name) &&
          harfSayisi(word) >= _minLetters &&
          harfSayisi(word) <= _maxLetters &&
          (direction == WritingDirection.trToRu ||
              _duzTurkce.hasMatch(word.turkish.toLowerCase())))
        word,
  ];
  words.sort((a, b) {
    final s = seviyeSirasi.indexOf(a.level.name) -
        seviyeSirasi.indexOf(b.level.name);
    if (s != 0) return s;
    final u = harfSayisi(a) - harfSayisi(b);
    if (u != 0) return u;
    return a.id.compareTo(b.id);
  });
  return words;
});

/// Kaçıncı testin kaç soru sorduğu.
int writingTestSize(int index) => index <= _shortTests ? 5 : 10;

/// Yazma testleri, sırayla açılan hâlleriyle.
final writingTestsProvider =
    Provider.family<List<WritingTest>, WritingDirection>((ref, direction) {
  final havuz = ref.watch(_writingPoolProvider(direction));
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

    final id = direction == WritingDirection.trToRu
        ? 'yazma_$i'
        : 'anlam_$i';
    final gecti = gecilen.contains(id);
    testler.add(WritingTest(
      index: i,
      direction: direction,
      words: kelimeler,
      // İlk test hep açık; sonrakiler bir öncekini geçince açılıyor.
      unlocked: oncekiGecildi,
      passed: gecti,
    ));
    oncekiGecildi = gecti;
  }
  return testler;
});
