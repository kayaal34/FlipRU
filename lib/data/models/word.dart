import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  politics(PhosphorIconsRegular.bank, Color(0xFF3B82F6)),
  economy(PhosphorIconsRegular.trendUp, Color(0xFF10B981)),
  health(PhosphorIconsRegular.heart, Color(0xFFEF4444)),
  science(PhosphorIconsRegular.flask, Color(0xFF8B5CF6)),
  environment(PhosphorIconsRegular.leaf, Color(0xFF22C55E)),
  education(PhosphorIconsRegular.graduationCap, Color(0xFFF59E0B)),
  technology(PhosphorIconsRegular.cpu, Color(0xFF06B6D4)),
  work(PhosphorIconsRegular.identificationBadge, Color(0xFF6366F1)),
  law(PhosphorIconsRegular.gavel, Color(0xFF78716C)),
  transport(PhosphorIconsRegular.bus, Color(0xFF0EA5E9)),
  food(PhosphorIconsRegular.forkKnife, Color(0xFFF97316)),
  family(PhosphorIconsRegular.users, Color(0xFFEC4899)),
  emotion(PhosphorIconsRegular.smiley, Color(0xFFD946EF)),
  body(PhosphorIconsRegular.personArmsSpread, Color(0xFFF43F5E)),
  home(PhosphorIconsRegular.armchair, Color(0xFFA855F7)),
  time(PhosphorIconsRegular.clock, Color(0xFF64748B)),
  culture(PhosphorIconsRegular.palette, Color(0xFFE11D48)),
  sport(PhosphorIconsRegular.soccerBall, Color(0xFF16A34A)),
  military(PhosphorIconsRegular.shieldCheck, Color(0xFF4B5563)),
  religion(PhosphorIconsRegular.sunDim, Color(0xFF7C3AED)),
  geography(PhosphorIconsRegular.globe, Color(0xFF0891B2)),
  agriculture(PhosphorIconsRegular.tractor, Color(0xFF65A30D)),
  construction(PhosphorIconsRegular.hammer, Color(0xFFEA580C)),
  clothing(PhosphorIconsRegular.tShirt, Color(0xFFDB2777)),
  shopping(PhosphorIconsRegular.shoppingBag, Color(0xFF9333EA)),
  media(PhosphorIconsRegular.newspaper, Color(0xFF475569)),
  animals(PhosphorIconsRegular.pawPrint, Color(0xFFCA8A04)),
  travel(PhosphorIconsRegular.suitcase, Color(0xFF14B8A6)),
  personality(PhosphorIconsRegular.brain, Color(0xFFBE185D)),
  quantity(PhosphorIconsRegular.ruler, Color(0xFF57534E));

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
    this.turkishTranslit = '',
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

  /// Türkçe karşılığın Kiril harfleriyle okunuşu (ör. `кёпек`).
  /// Yalnızca arayüz dili Rusça olduğunda gösterilir.
  final String turkishTranslit;

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
      // Veri dosyasi bu alan eklenmeden once uretilmis olabilir.
      turkishTranslit: row.length > 11 ? row[11] as String : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Word && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
