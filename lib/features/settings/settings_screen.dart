import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import 'account_screen.dart';
import 'legal_screen.dart';
import 'reports_screen.dart';
import 'widgets/settings_tiles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final reports = ref.watch(reportProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                const SizedBox(height: 16),
                // ───────────────────────── Görünüm ─────────────────────────
                SettingsSection(
                  title: t.appearance,
                  children: [
                    SettingsOptions<AppLanguage>(
                      title: t.language,
                      icon: Icons.language_rounded,
                      options: AppLanguage.values,
                      selected: settings.language,
                      labelOf: (l) => l.label,
                      onChanged: (l) =>
                          notifier.update((s) => s.copyWith(language: l)),
                    ),
                    SettingsOptions<ThemeMode>(
                      title: t.theme,
                      icon: Icons.contrast_rounded,
                      options: ThemeMode.values,
                      selected: settings.themeMode,
                      labelOf: (mode) => switch (mode) {
                        ThemeMode.system => t.themeSystem,
                        ThemeMode.light => t.themeLight,
                        ThemeMode.dark => t.themeDark,
                      },
                      onChanged: (mode) =>
                          notifier.update((s) => s.copyWith(themeMode: mode)),
                    ),
                  ],
                ),

                // ───────────────────────── Çalışma ─────────────────────────
                SettingsSection(
                  title: t.study,
                  children: [
                    SettingsOptions<StudyDirection>(
                      title: t.direction,
                      subtitle: settings.direction == StudyDirection.ruToTr
                          ? t.dirRuTrDesc
                          : t.dirTrRuDesc,
                      icon: Icons.swap_horiz_rounded,
                      options: StudyDirection.values,
                      selected: settings.direction,
                      labelOf: (d) =>
                          d == StudyDirection.ruToTr ? t.dirRuTr : t.dirTrRu,
                      onChanged: (d) =>
                          notifier.update((s) => s.copyWith(direction: d)),
                    ),
                    SettingsOptions<int>(
                      title: t.sessionSize,
                      subtitle: t.sessionSizeSub,
                      icon: Icons.style_rounded,
                      options: AppSettings.sessionSizeOptions,
                      selected: settings.sessionSize,
                      labelOf: (n) => n == 0 ? t.allCards : '$n ${t.cards}',
                      onChanged: (n) =>
                          notifier.update((s) => s.copyWith(sessionSize: n)),
                    ),
                    SettingsOptions<int>(
                      title: t.dailyGoal,
                      subtitle: t.dailyGoalSub,
                      icon: Icons.flag_rounded,
                      options: AppSettings.dailyGoalOptions,
                      selected: settings.dailyGoal,
                      labelOf: (n) => '$n',
                      onChanged: (n) =>
                          notifier.update((s) => s.copyWith(dailyGoal: n)),
                    ),
                    SettingsSwitch(
                      title: t.stressMarks,
                      subtitle: t.stressMarksSub,
                      icon: Icons.format_overline_rounded,
                      value: settings.showStressMarks,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(showStressMarks: v)),
                    ),
                    SettingsSwitch(
                      title: t.translitTitle,
                      subtitle: t.translitSub,
                      icon: Icons.record_voice_over_rounded,
                      value: settings.showTransliteration,
                      onChanged: (v) => notifier
                          .update((s) => s.copyWith(showTransliteration: v)),
                    ),
                    SettingsSwitch(
                      title: t.shuffle,
                      subtitle: t.shuffleSub,
                      icon: Icons.shuffle_rounded,
                      value: settings.shuffle,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(shuffle: v)),
                    ),
                    SettingsSwitch(
                      title: t.skipLearned,
                      subtitle: t.skipLearnedSub,
                      icon: Icons.filter_alt_rounded,
                      value: settings.hideLearned,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(hideLearned: v)),
                    ),
                  ],
                ),

                // ───────────────────────── Bildirim ────────────────────────
                SettingsSection(
                  title: t.reminder,
                  footer: t.reminderFooter,
                  children: [
                    SettingsSwitch(
                      title: t.dailyReminder,
                      subtitle: t.dailyReminderSub,
                      icon: Icons.notifications_active_rounded,
                      value: settings.reminderEnabled,
                      onChanged: (v) async {
                        if (v) {
                          await ref
                              .read(notificationServiceProvider)
                              .requestPermission();
                        }
                        notifier
                            .update((s) => s.copyWith(reminderEnabled: v));
                      },
                    ),
                    SettingsRow(
                      title: t.reminderTime,
                      icon: Icons.access_time_rounded,
                      trailing: settings.reminderLabel,
                      onTap: settings.reminderEnabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: settings.reminderHour,
                                  minute: settings.reminderMinute,
                                ),
                              );
                              if (picked == null) return;
                              notifier.update(
                                (s) => s.copyWith(
                                  reminderHour: picked.hour,
                                  reminderMinute: picked.minute,
                                ),
                              );
                            }
                          : null,
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
                      icon: Icons.widgets_rounded,
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

                // ────────────────────── Ses & Titreşim ─────────────────────
                SettingsSection(
                  title: t.soundVibration,
                  footer: t.soundFooter,
                  children: [
                    SettingsSwitch(
                      title: t.autoSpeak,
                      subtitle: t.autoSpeakSub,
                      icon: Icons.volume_up_rounded,
                      value: settings.autoSpeak,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(autoSpeak: v)),
                    ),
                    SettingsOptions<SpeechRate>(
                      title: t.speechRate,
                      icon: Icons.speed_rounded,
                      options: SpeechRate.values,
                      selected: settings.speechRate,
                      labelOf: (r) => switch (r) {
                        SpeechRate.slow => t.rateSlow,
                        SpeechRate.normal => t.rateNormal,
                        SpeechRate.fast => t.rateFast,
                      },
                      onChanged: (r) {
                        notifier.update((s) => s.copyWith(speechRate: r));
                        ref.read(speechServiceProvider)
                          ..setRate(r.value)
                          ..speak('Привет');
                      },
                    ),
                    SettingsSwitch(
                      title: t.haptics,
                      subtitle: t.hapticsSub,
                      icon: Icons.vibration_rounded,
                      value: settings.hapticsEnabled,
                      onChanged: (v) {
                        notifier.update((s) => s.copyWith(hapticsEnabled: v));
                        if (v) Haptics.medium();
                      },
                    ),
                  ],
                ),

                // Öğrenilen / yıldızlı / seri sayıları İstatistik ekranında
                // duruyor; aynı veriyi iki yerde göstermek kafa karıştırıyordu.
                SettingsSection(
                  title: t.accountAndData,
                  children: [
                    SettingsRow(
                      title: t.reports,
                      icon: Icons.flag_rounded,
                      trailing: '${reports.length}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReportsScreen(),
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: t.account,
                      subtitle: t.accountSub,
                      icon: Icons.person_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ────────────────────────── Hakkında ───────────────────────
                SettingsSection(
                  title: t.about,
                  footer: t.aboutFooter,
                  children: [
                    const _VersionRow(),
                  ],
                ),
                const SizedBox(height: 22),
                const _LegalLinks(),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'FlipRU',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// Sürüm satırı.
class _VersionRow extends ConsumerWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return SettingsRow(
      title: 'FlipRU',
      subtitle: t.appSubtitle,
      icon: Icons.auto_stories_rounded,
      trailing: t.version,
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: palette.textTertiary,
          fontSize: 11.5,
          decoration: TextDecoration.underline,
          decorationColor: palette.textTertiary,
        );

    Widget link(LegalDocument document) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LegalScreen(document: document),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(document.title, style: style),
          ),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        link(LegalDocument.privacy),
        Text('·', style: style?.copyWith(decoration: TextDecoration.none)),
        link(LegalDocument.terms),
        Text('·', style: style?.copyWith(decoration: TextDecoration.none)),
        link(LegalDocument.contact),
      ],
    );
  }
}
