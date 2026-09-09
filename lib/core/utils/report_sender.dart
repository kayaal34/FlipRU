import 'dart:io';

import '../../data/models/word_report.dart';

/// Hatalı kelime bildirimlerini bir Google Formuna gönderir.
///
/// Önceki akış kullanıcıyı posta uygulamasına atıyordu: üç dokunuş, bir de
/// "gönder"e basmayı unutma ihtimali. Bildirimlerin çoğu bu yüzden bize hiç
/// ulaşmıyordu. Burada bildirim önce cihaza kaydediliyor, sonra arka planda
/// sessizce gönderiliyor; kullanıcının yapacağı bir şey kalmıyor.
///
/// Sunucu tarafı yok: form yanıtları doğrudan bir e-tabloya düşüyor.
class ReportSender {
  const ReportSender();

  /// Formun yanıt uç noktası. Düzenleme bağlantısındaki `viewform` yerine
  /// `formResponse` yazılıyor.
  static const _endpoint =
      'https://docs.google.com/forms/d/e/'
      '1FAIpQLSdBOi8HGANvW4Q0EsOlwPN7PiHOKOfAq_o9q8Gr5TVTiiAYxg/formResponse';

  /// Formdaki alan kimlikleri. Sıra: kelime kimliği, Rusça, Türkçe, sorun
  /// türü, açıklama, sürüm.
  ///
  /// Bu numaralar forma özel; formdaki bir soru silinip yeniden eklenirse
  /// numarası da değişir ve buranın güncellenmesi gerekir.
  static const _fieldWordId = 'entry.1796310503';
  static const _fieldRussian = 'entry.1427037275';
  static const _fieldTurkish = 'entry.1352438999';
  static const _fieldReason = 'entry.1803583032';
  static const _fieldNote = 'entry.702845230';
  static const _fieldVersion = 'entry.932226083';

  /// Tek bir bildirimi gönderir; başarılıysa `true` döner.
  ///
  /// Ağ yoksa ya da form yanıt vermiyorsa `false` dönüyor ve bildirim
  /// cihazda kalıyor — bir sonraki denemede yeniden gönderiliyor.
  Future<bool> send(WordReport report, {required String version}) async {
    final body = _encode({
      _fieldWordId: report.wordId,
      _fieldRussian: report.russian,
      _fieldTurkish: report.turkish,
      _fieldReason: report.reason.label,
      _fieldNote: report.note,
      _fieldVersion: version,
    });

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded; charset=utf-8',
      );
      // Formu kapatan yönlendirmeyi takip etmiyoruz: yanıt zaten kaydedildi,
      // 302 gelmesi başarı demek.
      request.followRedirects = false;
      request.add(body);

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      await response.drain<void>();

      // Form doldurulduğunda 200 (onay sayfası) ya da 302 (yönlendirme)
      // dönüyor; ikisi de kaydedildi anlamına geliyor.
      return response.statusCode == 200 || response.statusCode == 302;
    } on Exception {
      // Ağ hatası, zaman aşımı, çözümlenemeyen adres… Hepsinde bildirim
      // cihazda kalıyor, kullanıcıya hata gösterip korkutmuyoruz.
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Alanları `application/x-www-form-urlencoded` gövdesine çevirir.
  List<int> _encode(Map<String, String> fields) {
    final parts = [
      for (final entry in fields.entries)
        '${Uri.encodeQueryComponent(entry.key)}='
            '${Uri.encodeQueryComponent(entry.value)}',
    ];
    return parts.join('&').codeUnits;
  }
}
