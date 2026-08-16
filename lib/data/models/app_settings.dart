import 'package:flutter/material.dart';

import '../../core/i18n/strings.dart';

/// Kartın ön yüzünde ne gösterileceği.
enum StudyDirection { ruToTr, trToRu }

/// Seslendirme hizi. Etiketleri `Strings` tasiyor.
enum SpeechRate {
  slow(0.32),
  normal(0.45),
  fast(0.6);

  const SpeechRate(this.value);

  final double value;
}

/// Ana ekran widget'ındaki kelimenin ne sıklıkla değişeceği.
///
/// "Günün kelimesi" adı üzerinde günlük; ama bazı kullanıcılar daha sık yeni
/// kelime görmek istiyor. Saatten kısa aralık anlamsız olurdu — widget zaten
/// yalnızca uygulama açıldığında tazeleniyor.
enum WidgetRefresh {
  every6h(6),
  every12h(12),
  daily(24);

  const WidgetRefresh(this.hours);

  final int hours;
}

/// Kalıcı kullanıcı tercihleri.
@immutable
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.tr,
    this.themeMode = ThemeMode.system,
    this.direction = StudyDirection.ruToTr,
    this.sessionSize = 20,
    this.dailyGoal = 20,
    this.shuffle = true,
    this.hapticsEnabled = true,
    this.autoSpeak = false,
    this.speechRate = SpeechRate.normal,
    this.showTransliteration = true,
    this.showStressMarks = true,
    this.hideLearned = false,
    this.hideLowConfidence = false,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.widgetRefresh = WidgetRefresh.daily,
  });

  /// Arayüz dili. Kelime verisi her hâlükârda Rusça-Türkçe.
  final AppLanguage language;

  final ThemeMode themeMode;
  final StudyDirection direction;

  /// Bir seansta gösterilecek kart sayısı. 0 = sınırsız (destenin tamamı).
  final int sessionSize;

  /// Günlük öğrenme hedefi (kelime).
  final int dailyGoal;

  final bool shuffle;
  final bool hapticsEnabled;

  /// Kart açıldığında Rusçayı otomatik seslendir.
  final bool autoSpeak;
  final SpeechRate speechRate;

  final bool showTransliteration;
  final bool showStressMarks;

  /// Açıksa, öğrenilmiş kelimeler yeni seanslara alınmaz.
  final bool hideLearned;

  /// Açıksa yalnızca birden fazla sözlüğün doğruladığı kelimeler gösterilir.
  final bool hideLowConfidence;

  /// Ana ekran widget'ındaki kelime kaç saatte bir değişsin.
  final WidgetRefresh widgetRefresh;

  /// Günlük hatırlatma bildirimi.
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  String get reminderLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:'
      '${reminderMinute.toString().padLeft(2, '0')}';

  static const sessionSizeOptions = [10, 20, 30, 50, 0];
  static const dailyGoalOptions = [5, 10, 20, 30, 50];

  AppSettings copyWith({
    AppLanguage? language,
    ThemeMode? themeMode,
    StudyDirection? direction,
    int? sessionSize,
    int? dailyGoal,
    bool? shuffle,
    bool? hapticsEnabled,
    bool? autoSpeak,
    SpeechRate? speechRate,
    bool? showTransliteration,
    bool? showStressMarks,
    bool? hideLearned,
    bool? hideLowConfidence,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    WidgetRefresh? widgetRefresh,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      direction: direction ?? this.direction,
      sessionSize: sessionSize ?? this.sessionSize,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      shuffle: shuffle ?? this.shuffle,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      speechRate: speechRate ?? this.speechRate,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showStressMarks: showStressMarks ?? this.showStressMarks,
      hideLearned: hideLearned ?? this.hideLearned,
      hideLowConfidence: hideLowConfidence ?? this.hideLowConfidence,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      widgetRefresh: widgetRefresh ?? this.widgetRefresh,
    );
  }

  Map<String, Object> toMap() => {
        'language': language.name,
        'themeMode': themeMode.name,
        'direction': direction.name,
        'sessionSize': sessionSize,
        'dailyGoal': dailyGoal,
        'shuffle': shuffle,
        'haptics': hapticsEnabled,
        'autoSpeak': autoSpeak,
        'speechRate': speechRate.name,
        'showTranslit': showTransliteration,
        'showStress': showStressMarks,
        'hideLearned': hideLearned,
        'hideLowConf': hideLowConfidence,
        'reminderOn': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'widgetRefresh': widgetRefresh.name,
      };

  factory AppSettings.fromMap(Map<String, Object?> map) {
    T pick<T extends Enum>(List<T> values, Object? key, T fallback) {
      for (final value in values) {
        if (value.name == key) return value;
      }
      return fallback;
    }

    return AppSettings(
      language: AppLanguage.byKey(map['language'] as String?),
      themeMode: pick(ThemeMode.values, map['themeMode'], ThemeMode.system),
      direction:
          pick(StudyDirection.values, map['direction'], StudyDirection.ruToTr),
      sessionSize: map['sessionSize'] as int? ?? 20,
      dailyGoal: map['dailyGoal'] as int? ?? 20,
      shuffle: map['shuffle'] as bool? ?? true,
      hapticsEnabled: map['haptics'] as bool? ?? true,
      autoSpeak: map['autoSpeak'] as bool? ?? false,
      speechRate: pick(SpeechRate.values, map['speechRate'], SpeechRate.normal),
      showTransliteration: map['showTranslit'] as bool? ?? true,
      showStressMarks: map['showStress'] as bool? ?? true,
      hideLearned: map['hideLearned'] as bool? ?? false,
      hideLowConfidence: map['hideLowConf'] as bool? ?? false,
      reminderEnabled: map['reminderOn'] as bool? ?? false,
      reminderHour: map['reminderHour'] as int? ?? 20,
      reminderMinute: map['reminderMinute'] as int? ?? 0,
      widgetRefresh: pick(
        WidgetRefresh.values,
        map['widgetRefresh'],
        WidgetRefresh.daily,
      ),
    );
  }
}
