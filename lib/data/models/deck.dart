import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';
import 'word.dart';

enum DeckKind { level, theme, starred }

/// Ana ekranda listelenen bir çalışma destesi.
///
/// Deste kendi kelimelerini taşımaz; yalnızca "hangi kelimeler bana ait"
/// sorusunu cevaplayan bir tanımdır. Kelime çözümlemesi repository'de yapılır.
@immutable
class Deck {
  const Deck({
    required this.id,
    required this.kind,
    required this.icon,
    required this.tint,
    this.level,
    this.theme,
  });

  final String id;
  final DeckKind kind;
  final IconData icon;
  final Color tint;

  /// [DeckKind.level] desteleri için dolu.
  final WordLevel? level;

  /// [DeckKind.theme] desteleri için dolu.
  final WordTheme? theme;

  /// Baslik ve alt baslik burada tutulmuyor: arayuz dili degisince yeniden
  /// uretilmeleri gerekiyor, deste listesi ise repository'de onbellekleniyor.
  String titleOf(Strings strings) => switch (kind) {
        DeckKind.level => level!.label,
        DeckKind.theme => strings.themeName(theme!),
        DeckKind.starred => strings.starredTitle,
      };

  String subtitleOf(Strings strings) => switch (kind) {
        DeckKind.level => strings.levelName(level!),
        DeckKind.theme => strings.themeDeckSubtitle(theme!),
        DeckKind.starred => strings.starredEmptyHint,
      };

  factory Deck.fromLevel(WordLevel level) => Deck(
        id: 'level_${level.name}',
        kind: DeckKind.level,
        icon: _levelIcons[level]!,
        tint: _levelTints[level]!,
        level: level,
      );

  factory Deck.fromTheme(WordTheme theme) => Deck(
        id: 'theme_${theme.name}',
        kind: DeckKind.theme,
        icon: theme.icon,
        tint: theme.tint,
        theme: theme,
      );

  static const starred = Deck(
    id: 'starred',
    kind: DeckKind.starred,
    icon: Icons.star_rounded,
    tint: Color(0xFFEFA818),
  );

  static const _levelIcons = {
    WordLevel.a1: Icons.looks_one_rounded,
    WordLevel.a2: Icons.looks_two_rounded,
    WordLevel.b1: Icons.looks_3_rounded,
    WordLevel.b2: Icons.looks_4_rounded,
    WordLevel.c1: Icons.looks_5_rounded,
  };

  /// Seviye yükseldikçe soğuk mordan sıcak kırmızıya giden bir skala.
  static const _levelTints = {
    WordLevel.a1: Color(0xFF34C7C0),
    WordLevel.a2: Color(0xFF3B82F6),
    WordLevel.b1: Color(0xFF6366F1),
    WordLevel.b2: Color(0xFFA855F7),
    WordLevel.c1: Color(0xFFEC4899),
  };
}
