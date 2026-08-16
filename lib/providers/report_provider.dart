import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/word_report.dart';
import 'app_providers.dart';

/// Kullanıcının bildirdiği hatalı kelimeler.
///
/// Backend olmadığı için cihazda birikiyor; kullanıcı hazır olduğunda tek
/// dokunuşla paylaşıyor (e-posta, mesaj, not defteri — hangisini seçerse).
class ReportNotifier extends Notifier<List<WordReport>> {
  static const _key = 'word_reports';

  @override
  List<WordReport> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    final decoded = json.decode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        WordReport.fromMap((item as Map<String, dynamic>).cast<String, Object?>()),
    ];
  }

  /// Aynı kelime için birden fazla bildirim tutmuyoruz; sonuncusu geçerli.
  void add(WordReport report) {
    final next = [
      ...state.where((r) => r.wordId != report.wordId),
      report,
    ];
    _persist(next);
  }

  void remove(String wordId) =>
      _persist(state.where((r) => r.wordId != wordId).toList());

  void clear() => _persist(const []);

  bool isReported(String wordId) => state.any((r) => r.wordId == wordId);

  /// Paylaşıma hazır düz metin.
  String asText() {
    final buffer = StringBuffer()
      ..writeln('FlipRU — hatalı kelime bildirimleri')
      ..writeln('Toplam: ${state.length}')
      ..writeln();
    for (final report in state) {
      buffer.writeln(report.toLine());
    }
    return buffer.toString();
  }

  void _persist(List<WordReport> value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(
          _key,
          json.encode([for (final r in value) r.toMap()]),
        );
  }
}

final reportProvider =
    NotifierProvider<ReportNotifier, List<WordReport>>(ReportNotifier.new);
