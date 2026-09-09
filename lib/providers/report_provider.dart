import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/report_sender.dart';
import '../data/models/word_report.dart';
import 'app_providers.dart';
import 'settings_provider.dart';

/// Kullanıcının bildirdiği hatalı kelimeler.
///
/// Bildirim önce cihaza yazılıyor, sonra Google Formuna gönderiliyor. Sıra
/// bu: ağ yoksa da bildirim kaybolmuyor, bir sonraki denemede gidiyor.
/// Gönderilenler listede kalıyor ama işaretli — kullanıcı neyi bildirdiğini
/// görebilsin, biz de aynı satırı iki kez almayalım.
class ReportNotifier extends Notifier<List<WordReport>> {
  static const _key = 'word_reports';

  @override
  List<WordReport> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    final decoded = json.decode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        WordReport.fromMap(
          (item as Map<String, dynamic>).cast<String, Object?>(),
        ),
    ];
  }

  /// Aynı kelime için birden fazla bildirim tutmuyoruz; sonuncusu geçerli.
  ///
  /// Kaydettikten hemen sonra göndermeyi deniyor. Sonucu beklemiyoruz:
  /// kullanıcı "Bildir"e basıp kartına dönebilsin.
  void add(WordReport report) {
    final next = [...state.where((r) => r.wordId != report.wordId), report];
    _persist(next);
    flush();
  }

  void remove(String wordId) =>
      _persist(state.where((r) => r.wordId != wordId).toList());

  void clear() => _persist(const []);

  bool isReported(String wordId) => state.any((r) => r.wordId == wordId);

  /// Henüz bize ulaşmamış bildirimler.
  List<WordReport> get pending => [for (final r in state) if (!r.sent) r];

  /// Bekleyen bildirimleri gönderir; kaçının ulaştığını döner.
  ///
  /// Tek tek gönderiliyor: her kelime e-tabloda kendi satırına düşsün,
  /// biri başarısız olunca ötekiler etkilenmesin.
  Future<int> flush() async {
    final bekleyen = pending;
    if (bekleyen.isEmpty) return 0;

    const sender = ReportSender();
    final surum = ref.read(stringsProvider).version;
    final gidenler = <String>{};

    for (final report in bekleyen) {
      if (await sender.send(report, version: surum)) {
        gidenler.add(report.wordId);
      }
    }
    if (gidenler.isEmpty) return 0;

    _persist([
      for (final r in state)
        if (gidenler.contains(r.wordId)) r.copyWith(sent: true) else r,
    ]);
    return gidenler.length;
  }

  void _persist(List<WordReport> value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, json.encode([for (final r in value) r.toMap()]));
  }
}

final reportProvider = NotifierProvider<ReportNotifier, List<WordReport>>(
  ReportNotifier.new,
);
