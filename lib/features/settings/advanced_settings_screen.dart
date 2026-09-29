import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/haptics.dart';
import '../../data/models/app_settings.dart';
import '../../providers/settings_provider.dart';
import 'widgets/settings_tiles.dart';

/// Ayarlar → Gelişmiş.
///
/// Ana ayarlar ekranı yeni kullanıcının anlamadığı seçeneklerle doluydu
/// (seans uzunluğu, vurgu işareti, widget tazeleme...). Bir kez kurulup
/// unutulan, varsayılanı zaten iyi olan her şey burada; ana ekranda yalnızca
/// herkesin değiştirmek isteyeceği ayarlar kaldı.
class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.advanced),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // ───────────────────── Kartlar ve testler ───────────────────
                SettingsSection(
                  title: t.study,
                  children: [
                    SettingsOptions<int>(
                      title: t.sessionSize,
                      subtitle: t.sessionSizeSub,
                      icon: PhosphorIconsRegular.cards,
                      options: AppSettings.sessionSizeOptions,
                      selected: settings.sessionSize,
                      labelOf: (n) => n == 0 ? t.allCards : '$n ${t.cards}',
                      onChanged: (n) =>
                          notifier.update((s) => s.copyWith(sessionSize: n)),
                    ),
                    SettingsOptions<int>(
                      title: t.quizLength,
                      subtitle: t.quizLengthSub,
                      icon: PhosphorIconsRegular.exam,
                      options: AppSettings.quizCountOptions,
                      selected: settings.quizQuestionCount,
                      labelOf: (n) => '$n',
                      onChanged: (n) => notifier.update(
                        (s) => s.copyWith(quizQuestionCount: n),
                      ),
                    ),
                    SettingsSwitch(
                      title: t.shuffle,
                      subtitle: t.shuffleSub,
                      icon: PhosphorIconsRegular.shuffle,
                      value: settings.shuffle,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(shuffle: v)),
                    ),
                    SettingsSwitch(
                      title: t.skipLearned,
                      subtitle: t.skipLearnedSub,
                      icon: PhosphorIconsRegular.funnel,
                      value: settings.hideLearned,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(hideLearned: v)),
                    ),
                  ],
                ),

                // ──────────────────────── Kart görünümü ──────────────────────
                SettingsSection(
                  title: t.cardAppearance,
                  children: [
                    SettingsSwitch(
                      title: t.stressMarks,
                      subtitle: t.stressMarksSub,
                      icon: PhosphorIconsRegular.textAUnderline,
                      value: settings.showStressMarks,
                      onChanged: (v) => notifier.update(
                        (s) => s.copyWith(showStressMarks: v),
                      ),
                    ),
                    SettingsSwitch(
                      title: t.translitTitle,
                      subtitle: t.translitSub,
                      icon: PhosphorIconsRegular.microphoneStage,
                      value: settings.showTransliteration,
                      onChanged: (v) => notifier.update(
                        (s) => s.copyWith(showTransliteration: v),
                      ),
                    ),
                  ],
                ),

                // ───────────────────── Ana ekran widget'ı ───────────────────
                SettingsSection(
                  title: t.widgetSection,
                  footer: t.widgetFooter,
                  children: [
                    SettingsOptions<WidgetRefresh>(
                      title: t.widgetRefreshTitle,
                      subtitle: t.widgetRefreshSub,
                      icon: PhosphorIconsRegular.squaresFour,
                      options: WidgetRefresh.values,
                      selected: settings.widgetRefresh,
                      labelOf: (r) => switch (r) {
                        WidgetRefresh.every6h => t.widgetEvery6h,
                        WidgetRefresh.every12h => t.widgetEvery12h,
                        WidgetRefresh.daily => t.widgetDaily,
                      },
                      onChanged: (r) =>
                          notifier.update((s) => s.copyWith(widgetRefresh: r)),
                    ),
                  ],
                ),

                // ─────────────────────────── Titreşim ──────────────────────
                SettingsSection(
                  children: [
                    SettingsSwitch(
                      title: t.haptics,
                      subtitle: t.hapticsSub,
                      icon: PhosphorIconsRegular.vibrate,
                      value: settings.hapticsEnabled,
                      onChanged: (v) {
                        notifier.update((s) => s.copyWith(hapticsEnabled: v));
                        if (v) Haptics.medium();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
