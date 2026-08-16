import 'package:flutter/foundation.dart';

/// Kullanıcının bir kelimede ne bulduğunu bildirdiği sorun türü.
enum ReportReason {
  translation('Çeviri yanlış'),
  example('Örnek cümle saçma'),
  pronunciation('Okunuş / vurgu yanlış'),
  other('Başka bir sorun');

  const ReportReason(this.label);

  final String label;

  static ReportReason byKey(String key) {
    for (final reason in values) {
      if (reason.name == key) return reason;
    }
    return other;
  }
}

@immutable
class WordReport {
  const WordReport({
    required this.wordId,
    required this.russian,
    required this.turkish,
    required this.reason,
    required this.note,
    required this.createdAt,
  });

  final String wordId;
  final String russian;
  final String turkish;
  final ReportReason reason;

  /// Kullanıcının serbest açıklaması; boş olabilir.
  final String note;

  final DateTime createdAt;

  Map<String, Object> toMap() => {
        'wordId': wordId,
        'ru': russian,
        'tr': turkish,
        'reason': reason.name,
        'note': note,
        'at': createdAt.toIso8601String(),
      };

  factory WordReport.fromMap(Map<String, Object?> map) => WordReport(
        wordId: map['wordId'] as String? ?? '',
        russian: map['ru'] as String? ?? '',
        turkish: map['tr'] as String? ?? '',
        reason: ReportReason.byKey(map['reason'] as String? ?? ''),
        note: map['note'] as String? ?? '',
        createdAt:
            DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime(2026),
      );

  /// Paylaşım metni — bize e-posta/mesaj olarak gelecek biçim.
  String toLine() {
    final date = createdAt.toIso8601String().split('T').first;
    final suffix = note.isEmpty ? '' : ' — $note';
    return '[$date] $wordId  $russian → $turkish  :: ${reason.label}$suffix';
  }
}
