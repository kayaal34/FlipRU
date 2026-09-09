import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Rusça telaffuz için cihazın kendi TTS motorunu kullanır.
///
/// Rusça sesi olmayan cihazlarda `speak` sessizce başarısız olur; UI tarafında
/// [isAvailable] ile hoparlör butonunu gizlemek yerine kullanıcıya tek seferlik
/// bilgi vermeyi tercih ediyoruz.
class SpeechService {
  SpeechService();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _available = false;
  String _language = 'ru-RU';
  final Map<String, bool> _support = {};

  bool get isAvailable => _available;

  double _rate = 0.45;

  /// Ayarlardan gelen konuşma hızı (0.3 yavaş – 0.6 hızlı).
  Future<void> setRate(double rate) async {
    _rate = rate;
    if (!_initialized) return;
    try {
      await _tts.setSpeechRate(kIsWeb ? rate * 2 : rate);
    } catch (_) {}
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(kIsWeb ? _rate * 2 : _rate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      // iOS'ta sessiz moddayken de duyulsun ve diğer sesleri kesmesin.
      await _tts.setSharedInstance(true);
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  /// Cihazda o dilin sesi kurulu mu? Sonuç önbelleğe alınıyor.
  ///
  /// Kurulu olmayan dil için `setLanguage` sessizce başarısız oluyor ve
  /// motor bir önceki dilde kalıyor: Türkçe kelimeyi Rusça sesle okumak,
  /// hiç okumamaktan daha kötü olduğu için önce burada kontrol ediliyor.
  Future<bool> supportsLanguage(String language) async {
    await _ensureInitialized();
    if (!_available) return false;
    final cached = _support[language];
    if (cached != null) return cached;
    var ok = false;
    try {
      ok = await _tts.isLanguageAvailable(language) == true;
    } catch (_) {
      ok = false;
    }
    _support[language] = ok;
    return ok;
  }

  /// Okuyabildiyse `true` döner; dil kurulu değilse hiç ses çıkarmaz.
  ///
  /// Ses seçimi yok, motorun o dil için varsayılan sesi kullanılıyor.
  /// Ayarlarda altı ses listeleniyordu; isimleri cihazdan cihaza değiştiği
  /// için kayıtlı seçim yeni telefonda bulunamıyordu ve zaten varsayılan
  /// sesten daha iyisi çıkmıyordu.
  Future<bool> speak(String text, {String language = 'ru-RU'}) async {
    await _ensureInitialized();
    if (!_available || text.trim().isEmpty) return false;
    if (!await supportsLanguage(language)) return false;
    try {
      await _tts.stop();
      if (language != _language) {
        await _tts.setLanguage(language);
        _language = language;
      }
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sistemin seslendirme verisi indirme ekranını açar.
  ///
  /// Ses paketi olmayan kullanıcıya "ayarlardan indir" demek yetmiyordu;
  /// ekranı bulmak zor. Açılamazsa `false` döner.
  Future<bool> openVoiceInstaller() async {
    if (kIsWeb) return false;
    try {
      const channel = MethodChannel('com.flipru.app/tts');
      return await channel.invokeMethod<bool>('installVoiceData') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Dil desteği yeniden sorulsun: kullanıcı ses indirdikten sonra
  /// uygulamayı kapatmadan tekrar denediğinde eski "yok" cevabı kalmasın.
  void forgetLanguageSupport() {
    _support.clear();
  }

  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
