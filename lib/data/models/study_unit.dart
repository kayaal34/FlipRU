import 'package:flutter/foundation.dart';

import '../../core/i18n/strings.dart';
import 'word.dart';

/// Bir destenin (seviye ya da tema) kolaydan zora sıralanmış parçası.
///
/// Kelimeler veri setinde zaten sıklık sırasında; deste sırayla dilimlendiği
/// için Bölüm 1 her zaman en sık kullanılan kelimeleri içerir.
@immutable
class StudyUnit {
  const StudyUnit({
    required this.deckId,
    required this.index,
    required this.words,
  });

  /// Bir bölümdeki kelime sayısı.
  static const size = 20;

  /// Bölümün "geçilmiş" sayılması için gereken oran.
  static const passRatio = 0.8;

  final String deckId;

  /// 0 tabanlı sıra.
  final int index;

  final List<Word> words;

  String get id => '${deckId}_u$index';

  String titleOf(Strings strings) => '${strings.unit} ${index + 1}';

  int get passThreshold => (words.length * passRatio).ceil();

  static List<StudyUnit> split(String deckId, List<Word> words) {
    final units = <StudyUnit>[];
    for (var start = 0; start < words.length; start += size) {
      final end = (start + size).clamp(0, words.length);
      units.add(
        StudyUnit(
          deckId: deckId,
          index: units.length,
          words: words.sublist(start, end),
        ),
      );
    }
    return units;
  }
}

/// Bölümün kullanıcıya göre durumu.
@immutable
class UnitProgress {
  const UnitProgress({
    required this.unit,
    required this.learned,
    required this.unlocked,
    this.testPassed = false,
  });

  final StudyUnit unit;
  final int learned;

  /// Önceki bölüm geçilmediyse kilitli.
  final bool unlocked;

  /// Bölüm testi başarıyla geçildi mi.
  final bool testPassed;

  int get total => unit.words.length;
  double get ratio => total == 0 ? 0 : learned / total;

  /// Kelimeleri tek tek öğrenmek ya da bölüm testini geçmek — ikisi de yeterli.
  bool get passed => testPassed || learned >= unit.passThreshold;
  bool get completed => learned == total;

  /// Kilidin açılması için önceki bölümde kaç kelime kaldığı.
  int get remainingToPass => (unit.passThreshold - learned).clamp(0, total);
}
