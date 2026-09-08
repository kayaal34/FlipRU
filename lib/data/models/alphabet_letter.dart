import 'package:flutter/foundation.dart';

/// Harflerin öğrenme zorluğuna göre bölündüğü üç grup.
///
/// 33 harfi eşit ağırlıkta dizmek işin asıl zor kısmını gizliyordu: Latin
/// okuru için acı, tanıdık görünüp farklı okunan harflerde (В, Р, С…).
/// Gruplar bu ayrımı görünür kılıyor.
enum LetterGroup {
  /// Görünüşü de sesi de tanıdık: öğrenilecek yeni bir şey yok.
  same,

  /// Tuzak: tanıdık görünüyor ama başka okunuyor.
  trap,

  /// Tamamen yeni şekil.
  fresh,
}

/// Alfabe ekranındaki tek bir harf.
///
/// Metinler öğrenenin kendi dilinde tutuluyor: Kiril alfabesi Türkçe
/// açıklamalarla, Türk alfabesi Rusça açıklamalarla geliyor. Böylece ekran
/// tarafında çeviri katmanına gerek kalmıyor.
@immutable
class AlphabetLetter {
  const AlphabetLetter({
    required this.upper,
    required this.lower,
    required this.name,
    required this.sound,
    required this.example,
    required this.meaning,
    required this.group,
    this.note,
  });

  final LetterGroup group;

  /// Büyük harf (`А`).
  final String upper;

  /// Küçük harf (`а`).
  final String lower;

  /// Harfin adı (`a`, `бе`).
  final String name;

  /// Nasıl okunduğu (`k`, `ч`).
  final String sound;

  /// Harfi içeren örnek kelime.
  final String example;

  /// Örnek kelimenin anlamı.
  final String meaning;

  /// Yalnızca kuraldışı harflerde dolu (`ğ`, `ъ`, vurgusuz `о`).
  final String? note;

  String get pair => '$upper $lower';
}
