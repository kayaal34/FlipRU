import 'package:flutter/foundation.dart';

/// Satın alınabilir abonelik süreleri.
enum PremiumPlan {
  monthly(1, '₺79,90', null),
  quarterly(3, '₺199,90', '%17'),
  yearly(12, '₺599,90', '%37');

  const PremiumPlan(this.months, this.price, this.badge);

  final int months;

  /// Mağaza entegrasyonu bağlanana kadar gösterim amaçlı fiyat.
  final String price;
  final String? badge;

  String get perMonth {
    final digits = price.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    final total = double.tryParse(digits);
    if (total == null) return '';
    return '₺${(total / months).toStringAsFixed(2).replaceAll('.', ',')} ';
  }
}

/// Kullanıcının premium durumu.
@immutable
class PremiumState {
  const PremiumState({this.expiresAt});

  /// null ise premium yok.
  final DateTime? expiresAt;

  bool get isActive {
    final until = expiresAt;
    return until != null && until.isAfter(DateTime.now());
  }

  int get remainingDays {
    final until = expiresAt;
    if (until == null) return 0;
    return until.difference(DateTime.now()).inDays.clamp(0, 100000);
  }

  Map<String, Object?> toMap() => {'expiresAt': expiresAt?.toIso8601String()};

  factory PremiumState.fromMap(Map<String, Object?> map) => PremiumState(
        expiresAt: DateTime.tryParse(map['expiresAt'] as String? ?? ''),
      );
}

/// Ücretsiz sürümün sınırları.
abstract final class FreeLimits {
  /// Ücretsiz kullanıcıya açık seviyeler.
  static const openLevels = {'a1', 'a2'};

  /// Ücretsiz kullanıcıya açık tema sayısı (listenin başından).
  static const openThemes = 5;

  /// Bölüm testleri herkese açık; genel testler premium.
  static const generalTestsRequirePremium = true;
}
