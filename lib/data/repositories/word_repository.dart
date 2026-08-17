import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/deck.dart';
import '../models/word.dart';

/// Kelime kaynağı.
///
/// Veri `assets/data/words.json` içinde satır-dizisi biçiminde tutuluyor
/// (nesne yerine dizi: 16 bin kayıtta yaklaşık %40 daha küçük ve daha hızlı
/// çözümleniyor). Çözümleme ana iş parçacığını kilitlememesi için ayrı bir
/// isolate'te yapılıyor.
class WordRepository {
  WordRepository._(this._words)
      : _byLevel = _groupBy(_words, (w) => w.level),
        _byTheme = _groupByTheme(_words);

  final List<Word> _words;
  final Map<WordLevel, List<Word>> _byLevel;
  final Map<WordTheme, List<Word>> _byTheme;

  static const assetPath = 'assets/data/words.json';

  static Future<WordRepository> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final words = await compute(_parse, raw);
    return WordRepository._(words);
  }

  /// Testler için: hazır listeden kur.
  @visibleForTesting
  factory WordRepository.fromWords(List<Word> words) = WordRepository._;

  static List<Word> _parse(String raw) {
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final rows = decoded['rows'] as List<dynamic>;
    return [
      for (final row in rows) Word.fromRow(row as List<dynamic>),
    ];
  }

  static Map<WordLevel, List<Word>> _groupBy(
    List<Word> words,
    WordLevel Function(Word) key,
  ) {
    final out = <WordLevel, List<Word>>{
      for (final level in WordLevel.values) level: <Word>[],
    };
    for (final word in words) {
      out[key(word)]!.add(word);
    }
    return out;
  }

  static Map<WordTheme, List<Word>> _groupByTheme(List<Word> words) {
    final out = <WordTheme, List<Word>>{
      for (final theme in WordTheme.values) theme: <Word>[],
    };
    for (final word in words) {
      final theme = word.theme;
      if (theme != null) out[theme]!.add(word);
    }
    return out;
  }

  List<Word> get allWords => List.unmodifiable(_words);

  /// Yalnızca kelime içeren temalar deste olarak gösterilir.
  List<Deck> get levelDecks => [
        for (final level in WordLevel.values)
          if (_byLevel[level]!.isNotEmpty) Deck.fromLevel(level),
      ];

  List<Deck> get themeDecks => [
        for (final theme in WordTheme.values)
          if (_byTheme[theme]!.length >= 12) Deck.fromTheme(theme),
      ];

  List<Word> wordsOf(Deck deck, {Set<String> starredIds = const {}}) {
    return switch (deck.kind) {
      DeckKind.level => _byLevel[deck.level]!,
      DeckKind.theme => _byTheme[deck.theme]!,
      DeckKind.starred => [
          for (final word in _words)
            if (starredIds.contains(word.id)) word,
        ],
    };
  }

  /// Quiz çeldiricileri: aynı seviyeden rastgele kelimeler (yakın seviye,
  /// şıkları makul zorlukta tutuyor).
  List<Word> randomDistractors(Word target, int count, Random random) {
    final pool = _byLevel[target.level]!;
    // Seviyeden yeterli aday çıkmazsa tüm havuza düş.
    final source = pool.length > count * 4 ? pool : _words;

    final picked = <Word>[];
    final seen = <String>{target.id};
    var attempts = 0;
    while (picked.length < count && attempts < count * 40) {
      attempts++;
      final candidate = source[random.nextInt(source.length)];
      if (candidate.turkish == target.turkish) continue;
      if (seen.add(candidate.id)) picked.add(candidate);
    }
    return picked;
  }
}
