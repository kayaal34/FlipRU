import 'package:flutter/foundation.dart';
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

  /// [language] yalnızca alfabe ekranında Türkçe okumak için değişiyor;
  /// kelime kartları varsayılan Rusça sesi kullanmaya devam ediyor.
  Future<void> speak(String text, {String language = 'ru-RU'}) async {
    await _ensureInitialized();
    if (!_available || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      if (language != _language) {
        _language = language;
        await _tts.setLanguage(language);
      }
      await _tts.speak(text);
    } catch (_) {
      // Ses yoksa sessizce geç.
    }
  }

  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
