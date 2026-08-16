import 'package:flutter/material.dart';

/// Avrupa Dil Portfolyosu (CEFR) seviyeleri.
///
/// Seviye, kelimenin Rusça derlemdeki frekans sırasından türetiliyor:
/// en sık 800 kelime A1, sonraki 1400 A2, ...
enum WordLevel {
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c1('C1');

  const WordLevel(this.label);

  /// Dilden bagimsiz CEFR kodu. Okunabilir aciklama icin `Strings.levelName`.
  final String label;

  static WordLevel? byKey(String key) {
    for (final level in values) {
      if (level.name == key) return level;
    }
    return null;
  }
}

/// Konu başlıkları. Kelimelerin bir kısmı otomatik olarak bu temalara
/// eşleniyor; eşlenemeyenlerin teması `null` olur ve tema destelerinde
/// görünmezler.
enum WordTheme {
  politics(Icons.account_balance_rounded, Color(0xFF3B82F6)),
  economy(Icons.trending_up_rounded, Color(0xFF10B981)),
  health(Icons.favorite_rounded, Color(0xFFEF4444)),
  science(Icons.science_rounded, Color(0xFF8B5CF6)),
  environment(Icons.eco_rounded, Color(0xFF22C55E)),
  education(Icons.school_rounded, Color(0xFFF59E0B)),
  technology(Icons.memory_rounded, Color(0xFF06B6D4)),
  work(Icons.badge_rounded, Color(0xFF6366F1)),
  law(Icons.gavel_rounded, Color(0xFF78716C)),
  transport(Icons.directions_bus_rounded, Color(0xFF0EA5E9)),
  food(Icons.restaurant_rounded, Color(0xFFF97316)),
  family(Icons.family_restroom_rounded, Color(0xFFEC4899)),
  emotion(Icons.mood_rounded, Color(0xFFD946EF)),
  body(Icons.accessibility_new_rounded, Color(0xFFF43F5E)),
  home(Icons.chair_rounded, Color(0xFFA855F7)),
  time(Icons.schedule_rounded, Color(0xFF64748B)),
  culture(Icons.palette_rounded, Color(0xFFE11D48)),
  sport(Icons.sports_soccer_rounded, Color(0xFF16A34A)),
  military(Icons.shield_rounded, Color(0xFF4B5563)),
  religion(Icons.brightness_low_rounded, Color(0xFF7C3AED)),
  geography(Icons.public_rounded, Color(0xFF0891B2)),
  agriculture(Icons.agriculture_rounded, Color(0xFF65A30D)),
  construction(Icons.construction_rounded, Color(0xFFEA580C)),
  clothing(Icons.checkroom_rounded, Color(0xFFDB2777)),
  shopping(Icons.shopping_bag_rounded, Color(0xFF9333EA)),
  media(Icons.newspaper_rounded, Color(0xFF475569)),
  animals(Icons.pets_rounded, Color(0xFFCA8A04)),
  travel(Icons.luggage_rounded, Color(0xFF14B8A6)),
  personality(Icons.psychology_rounded, Color(0xFFBE185D)),
  quantity(Icons.straighten_rounded, Color(0xFF57534E));

  const WordTheme(this.icon, this.tint);

  final IconData icon;
  final Color tint;

  static WordTheme? byKey(String key) {
    if (key.isEmpty) return null;
    for (final theme in values) {
      if (theme.name == key) return theme;
    }
    return null;
  }
}

/// Kelime türü rozeti.
enum PartOfSpeech {
  noun,
  verb,
  adjective,
  other;

  static PartOfSpeech byKey(String key) => switch (key) {
        'noun' => noun,
        'verb' => verb,
        'adj' => adjective,
        _ => other,
      };
}

@immutable
class Word {
  const Word({
    required this.id,
    required this.russian,
    required this.accented,
    required this.transliteration,
    required this.turkish,
    required this.exampleRu,
    required this.exampleTr,
    required this.level,
    required this.theme,
    required this.partOfSpeech,
    required this.confidence,
  });

  final String id;

  /// Yalın hâli — arama ve TTS bu alanı kullanır.
  final String russian;

  /// Vurgu işaretli hâli (ör. `возмо́жность`). Kartta bu gösterilir.
  final String accented;

  /// Türkçe okunuşu; vurgulu hece BÜYÜK harfle (ör. `vaz-MOJ-nast'`).
  final String transliteration;

  final String turkish;

  /// Örnek cümle. Her kelimede bulunmayabilir.
  final String exampleRu;
  final String exampleTr;

  final WordLevel level;
  final WordTheme? theme;
  final PartOfSpeech partOfSpeech;

  /// Çevirinin kaç kaynaktan doğrulandığı: 4 elle düzeltildi, 3 birden çok
  /// sözlük anlaştı, 2 tek güçlü kaynak.
  final int confidence;

  bool get hasExample => exampleRu.isNotEmpty && exampleTr.isNotEmpty;

  /// Tema yoksa seviye rengine düşer; UI'da her kelimenin bir rengi olur.
  Color get tint => theme?.tint ?? _levelTints[level]!;

  static const _levelTints = {
    WordLevel.a1: Color(0xFF34C7C0),
    WordLevel.a2: Color(0xFF3B82F6),
    WordLevel.b1: Color(0xFF6366F1),
    WordLevel.b2: Color(0xFFA855F7),
    WordLevel.c1: Color(0xFFEC4899),
  };

  /// `words.json` içindeki satır dizisinden üretir.
  /// Alan sırası: id, ru, accented, translit, tr, pos, level, theme, exRu,
  /// exTr, conf
  factory Word.fromRow(List<dynamic> row) {
    return Word(
      id: row[0] as String,
      russian: row[1] as String,
      accented: row[2] as String,
      transliteration: row[3] as String,
      turkish: row[4] as String,
      partOfSpeech: PartOfSpeech.byKey(row[5] as String),
      level: WordLevel.byKey(row[6] as String) ?? WordLevel.c1,
      theme: WordTheme.byKey(row[7] as String),
      exampleRu: row[8] as String,
      exampleTr: row[9] as String,
      confidence: row[10] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Word && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
