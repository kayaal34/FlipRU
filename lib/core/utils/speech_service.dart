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

  /// Dil kodu -> kullanıcının seçtiği ses adı. Boşsa motorun varsayılanı.
  final Map<String, String> _voices = {};
  final Map<String, List<String>> _voiceCache = {};

  void setPreferredVoice(String language, String voiceName) {
    _voices[language] = voiceName;
  }

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

  /// Cihazdaki motorlar ve [language] için kullanılabilir sesler.
  ///
  /// Motorların (Google, Samsung…) ve aynı motor içindeki seslerin tınısı
  /// belirgin biçimde farklı; kullanıcıya seçtirebilmek için listeleniyor.
  /// Aynı konuşmacı motorda iki kez bulunuyor (`…-local` ve `…-network`);
  /// listeye konuşmacı başına tek satır, internetsiz de çalışan `-local`
  /// sürümüyle giriyor. Yoksa 11 satırın yarısı aynı sesin tekrarı olurdu.
  Future<List<String>> voicesFor(String language) async {
    await _ensureInitialized();
    if (!_available) return const [];
    final cached = _voiceCache[language];
    if (cached != null) return cached;
    try {
      final raw = await _tts.getVoices as List<dynamic>?;
      if (raw == null) return const [];
      final prefix = language.split('-').first.toLowerCase();
      final bySpeaker = <String, String>{};
      for (final v in raw) {
        if (v is! Map) continue;
        final locale = '${v['locale']}'.toLowerCase();
        if (!locale.startsWith(prefix)) continue;
        final name = '${v['name']}';
        final speaker = name
            .replaceAll('-network', '')
            .replaceAll('-local', '');
        final current = bySpeaker[speaker];
        if (current == null || name.endsWith('-local')) {
          bySpeaker[speaker] = name;
        }
      }
      final names = bySpeaker.values.toList()..sort();
      _voiceCache[language] = names;
      return names;
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> engines() async {
    await _ensureInitialized();
    try {
      final raw = await _tts.getEngines as List<dynamic>?;
      return [for (final e in raw ?? const []) '$e'];
    } catch (_) {
      return const [];
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
  /// [voiceOverride] yalnızca ayarlardaki ses seçicinin önizlemesi için:
  /// kullanıcı listedeki sesi kaydetmeden dinleyebiliyor.
  Future<bool> speak(
    String text, {
    String language = 'ru-RU',
    String? voiceOverride,
  }) async {
    await _ensureInitialized();
    if (!_available || text.trim().isEmpty) return false;
    if (!await supportsLanguage(language)) return false;
    try {
      await _tts.stop();
      // Kayıtlı ses adı bu cihazda olmayabilir: Android ayarları yedekten
      // yeni telefona taşıyor, kullanıcı ses paketini kaldırmış olabiliyor.
      // Böyle bir durumda susmak yerine motorun varsayılanına düşüyoruz.
      final wanted = voiceOverride ?? _voices[language] ?? '';
      final voice =
          wanted.isEmpty || (await voicesFor(language)).contains(wanted)
          ? wanted
          : '';
      if (voice.isEmpty) {
        if (language != _language) {
          await _tts.setLanguage(language);
          _language = language;
        }
      } else {
        // setVoice dili de birlikte ayarlıyor.
        await _tts.setVoice({'name': voice, 'locale': language});
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
    _voiceCache.clear();
  }

  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
