import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dokunsal geri bildirim sarmalayıcısı.
///
/// Web ve masaüstünde titreşim kanalı yok; oradaki `MissingPluginException`
/// hatalarını yutup sessizce devam ediyoruz.
abstract final class Haptics {
  /// Ayarlardan gelen açma/kapama. `SettingsNotifier` her değişimde günceller;
  /// böylece titreşim tercihini her widget'a ayrı ayrı geçirmek gerekmiyor.
  static bool enabled = true;

  static bool get _supported =>
      enabled &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static Future<void> _run(Future<void> Function() action) async {
    if (!_supported) return;
    try {
      await action();
    } catch (_) {
      // Titreşim kritik değil, hata kullanıcıya yansımasın.
    }
  }

  /// Kart çevrildiğinde, yıldıza dokunulduğunda.
  static Future<void> light() => _run(HapticFeedback.lightImpact);

  /// Kart kaydırılıp bir karar verildiğinde.
  static Future<void> medium() => _run(HapticFeedback.mediumImpact);

  /// Seans bittiğinde.
  static Future<void> heavy() => _run(HapticFeedback.heavyImpact);

  /// Segment değiştirme gibi ince etkileşimler.
  static Future<void> selection() => _run(HapticFeedback.selectionClick);
}
