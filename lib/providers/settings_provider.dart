import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/strings.dart';
import '../core/utils/haptics.dart';
import '../data/models/app_settings.dart';
import 'app_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'app_settings';

  @override
  AppSettings build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    final settings = raw == null
        ? const AppSettings()
        : AppSettings.fromMap(
            (json.decode(raw) as Map<String, dynamic>).cast<String, Object?>(),
          );
    // Haptics statik bir yardımcı; ayarı her değişimde ona da yansıtıyoruz ki
    // her widget'a tek tek geçirmek zorunda kalmayalım.
    Haptics.enabled = settings.hapticsEnabled;
    return settings;
  }

  void update(AppSettings Function(AppSettings) transform) {
    final next = transform(state);
    state = next;
    Haptics.enabled = next.hapticsEnabled;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, json.encode(next.toMap()));
  }

  void reset() => update((_) => const AppSettings());
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Seçili dile göre arayüz metinleri.
final stringsProvider = Provider<Strings>(
  (ref) => Strings.of(ref.watch(settingsProvider.select((s) => s.language))),
);
