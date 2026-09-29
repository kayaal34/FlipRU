import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/deck.dart';
import '../models/word.dart';

/// Kelime kaynağı.
///
/// Veri `assets/data/words.json` içinde satır-dizisi biçiminde tutuluyor
/// (nesne yerine dizi: ~9 bin kayıtta yaklaşık %40 daha küçük ve daha hızlı
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
    return [for (final row in rows) Word.fromRow(row as List<dynamic>)];
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

  /// Quiz çeldiricileri.
  ///
  /// Rastgele kelime seçmek testi kolaylaştırıyordu: "не" sorusuna
  /// "telefon" şıkkı gelince cevap eleyerek bulunuyordu. Artık şıklar
  /// hedefe benziyor: önce aynı konu ve aynı türden (fiile fiil, isme isim),
  /// yetmezse aynı türden, o da yetmezse aynı seviyeden seçiliyor. Seviye
  /// hep aynı kalıyor ki zorluk tutarlı olsun.
  ///
  /// İlk anlamı hedefle aynı olan adaylar atlanıyor: "ev" sorusunda
  /// "ev / yuva" şıkkı çıkarsa iki doğru cevap olurdu.
  List<Word> randomDistractors(Word target, int count, Random random) {
    final level = _byLevel[target.level]!;
    final hedef = _firstSense(target.turkish);

    bool uygun(Word w) =>
        w.id != target.id &&
        w.turkish != target.turkish &&
        _firstSense(w.turkish) != hedef;

    final sameKind = [
      for (final w in level)
        if (w.partOfSpeech == target.partOfSpeech && uygun(w)) w,
    ];
    final sameTheme = target.theme == null
        ? const <Word>[]
        : [
            for (final w in sameKind)
              if (w.theme == target.theme) w,
          ];

    final picked = <Word>[];
    final seen = <String>{target.id};
    void draw(List<Word> source, int upTo) {
      if (source.isEmpty) return;
      var attempts = 0;
      while (picked.length < upTo && attempts < upTo * 40) {
        attempts++;
        final candidate = source[random.nextInt(source.length)];
        if (!uygun(candidate)) continue;
        // Aynı ilk anlamlı iki çeldirici de olmasın.
        if (picked.any(
          (p) => _firstSense(p.turkish) == _firstSense(candidate.turkish),
        )) {
          continue;
        }
        if (seen.add(candidate.id)) picked.add(candidate);
      }
    }

    // En fazla ikisi aynı konudan: hepsi aynı konudan gelince (üç meyve
    // adı) soru bu kez gereğinden zorlaşıyor.
    draw(sameTheme, count > 1 ? count - 1 : count);
    draw(sameKind, count);
    draw(level, count);
    draw(_words, count);
    return picked;
  }

  /// "ev / yuva" → "ev"; parantez içi açıklamalar da atılıyor.
  static String _firstSense(String turkish) => turkish
      .split(RegExp(r'\s*[/;,]\s*'))
      .first
      .replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ')
      .trim()
      .toLowerCase();
}
