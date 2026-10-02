import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/qa_mode.dart';
import '../../core/i18n/strings.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/library_providers.dart';
import '../../core/utils/word_of_day.dart';
import '../../providers/daily_provider.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import 'account_screen.dart';
import 'advanced_settings_screen.dart';
import 'stats_screen.dart';
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
                const SizedBox(height: 8),
                const _StreakCard(),
                const SizedBox(height: 16),
                // ───────────────────── Hesap ve veri ───────────────────────
                //
                // Listenin basinda: buradakiler ayar degil, gidilecek yer.
                // Istatistik ayri bir sekmeydi, alt menuden kaldirilinca en
                // alta dusmustu ve kimse iki ekran kaydirip bulamiyordu.
                // Asagisi ise ayarlar — bir kez kurulup unutulan seyler.
                SettingsSection(
                  title: t.accountAndData,
                  children: [
                    SettingsRow(
                      title: t.statsTitle,
                      subtitle: t.statsRowSub,
                      icon: PhosphorIconsRegular.chartLineUp,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      ),
                    ),
                    SettingsRow(
                      title: t.reports,
                      icon: PhosphorIconsRegular.flag,
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
                      icon: PhosphorIconsRegular.user,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ───────────────────────── Görünüm ─────────────────────────
                SettingsSection(
                  title: t.appearance,
                  children: [
                    SettingsOptions<AppLanguage>(
                      title: t.language,
                      icon: PhosphorIconsRegular.globeHemisphereWest,
                      options: AppLanguage.values,
                      selected: settings.language,
                      labelOf: (l) => l.label,
                      onChanged: (l) =>
                          notifier.update((s) => s.copyWith(language: l)),
                    ),
                    SettingsOptions<ThemeMode>(
                      title: t.theme,
                      icon: PhosphorIconsRegular.circleHalf,
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
                      icon: PhosphorIconsRegular.arrowsLeftRight,
                      options: StudyDirection.values,
                      selected: settings.direction,
                      labelOf: (d) =>
                          d == StudyDirection.ruToTr ? t.dirRuTr : t.dirTrRu,
                      onChanged: (d) =>
                          notifier.update((s) => s.copyWith(direction: d)),
                    ),
                    SettingsOptions<int>(
                      title: t.dailyGoal,
                      subtitle: t.dailyGoalSub,
                      icon: PhosphorIconsRegular.flag,
                      options: AppSettings.dailyGoalOptions,
                      selected: settings.dailyGoal,
                      labelOf: (n) => '$n',
                      onChanged: (n) =>
                          notifier.update((s) => s.copyWith(dailyGoal: n)),
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
                      icon: PhosphorIconsRegular.bellRinging,
                      value: settings.reminderEnabled,
                      onChanged: (v) async {
                        if (v) {
                          await ref
                              .read(notificationServiceProvider)
                              .requestPermission();
                        }
                        notifier.update((s) => s.copyWith(reminderEnabled: v));
                      },
                    ),
                    SettingsRow(
                      title: t.reminderTime,
                      icon: PhosphorIconsRegular.clock,
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
                    SettingsSwitch(
                      title: t.wordOfDayToggle,
                      subtitle: t.wordOfDayToggleSub,
                      icon: PhosphorIconsRegular.sunHorizon,
                      value: settings.wordOfDayEnabled,
                      onChanged: (v) async {
                        if (v) {
                          await ref
                              .read(notificationServiceProvider)
                              .requestPermission();
                        }
                        notifier.update((s) => s.copyWith(wordOfDayEnabled: v));
                      },
                    ),
                    SettingsRow(
                      title: t.wordOfDayTime,
                      icon: PhosphorIconsRegular.clock,
                      trailing: settings.wordOfDayLabel,
                      onTap: settings.wordOfDayEnabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: settings.wordOfDayHour,
                                  minute: settings.wordOfDayMinute,
                                ),
                              );
                              if (picked == null) return;
                              notifier.update(
                                (s) => s.copyWith(
                                  wordOfDayHour: picked.hour,
                                  wordOfDayMinute: picked.minute,
                                ),
                              );
                            }
                          : null,
                    ),
                    // Yalnızca QA derlemesinde: bildirimleri saatini
                    // beklemeden görmek için. Play sürümünde qaMode hep false.
                    if (qaMode)
                      SettingsRow(
                        title: 'QA: Test bildirimlerini gönder',
                        icon: PhosphorIconsRegular.bellSimpleRinging,
                        onTap: () => ref
                            .read(notificationServiceProvider)
                            .showTestNotifications(
                              wordOfDay: wordOfDayContent(
                                pool: ref.read(wordRepositoryProvider).allWords,
                                when: DateTime.now(),
                                strings: t,
                                learningTurkish:
                                    settings.language == AppLanguage.ru,
                              ),
                              goal: settings.dailyGoal,
                              streak: ref.read(streakProvider),
                              strings: t,
                            ),
                      ),
                  ],
                ),

                // ──────────────────────────── Ses ────────────────────────────
                SettingsSection(
                  title: t.soundVibration,
                  footer: t.soundFooter,
                  children: [
                    SettingsSwitch(
                      title: t.autoSpeak,
                      subtitle: t.autoSpeakSub,
                      icon: PhosphorIconsRegular.speakerHigh,
                      value: settings.autoSpeak,
                      onChanged: (v) =>
                          notifier.update((s) => s.copyWith(autoSpeak: v)),
                    ),
                    SettingsOptions<SpeechRate>(
                      title: t.speechRate,
                      icon: PhosphorIconsRegular.gauge,
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
                  ],
                ),

                // ───────────────────────── Gelişmiş ────────────────────────
                //
                // Varsayilani zaten iyi olan, bir kez kurulup unutulan
                // secenekler burada toplu: yeni kullaniciyi ilk ekranda
                // anlamadigi on ayarla karsilamiyoruz.
                SettingsSection(
                  children: [
                    SettingsRow(
                      title: t.advanced,
                      subtitle: t.advancedSub,
                      icon: PhosphorIconsRegular.slidersHorizontal,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdvancedSettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                // ────────────────────────── Hakkında ───────────────────────
                SettingsSection(
                  title: t.about,
                  footer: t.aboutFooter,
                  children: [const _VersionRow()],
                ),
                const SizedBox(height: 22),
                const _LegalLinks(),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'FlipRU',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.textTertiary,
                    ),
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
      icon: PhosphorIconsRegular.bookOpenText,
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
        MaterialPageRoute(builder: (_) => LegalScreen(document: document)),
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

/// Ayarların en üstünde seri özeti; dokununca istatistik ekranı açılıyor.
class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  static const _flame = Color(0xFFF0762A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final t = ref.watch(stringsProvider);
    final streak = ref.watch(streakProvider);
    final longest = ref.watch(longestStreakProvider);
    final learned = ref.watch(learnedProvider).length;

    return Pressable(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.separator),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.isDark
                    ? _flame.withValues(alpha: 0.18)
                    : const Color(0xFFFFE9D6),
              ),
              child: Icon(
                PhosphorIconsFill.fire,
                size: 28,
                color: streak > 0 ? _flame : palette.textTertiary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.streakTitle(streak), style: textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    t.longestStreak(longest, learned),
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.chartBar,
              size: 24,
              color: palette.accent,
            ),
          ],
        ),
      ),
    );
  }
}
