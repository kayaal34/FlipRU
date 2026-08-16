import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/app_settings.dart';
import '../../providers/app_providers.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/premium.dart';
import '../../providers/premium_provider.dart';
import '../premium/premium_screen.dart';
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
    final premium = ref.watch(premiumProvider);
    final t = ref.watch(stringsProvider);
    final learnedCount = ref.watch(learnedProvider).length;
    final starredCount = ref.watch(starredProvider).length;
    final streakCount = ref.watch(streakProvider);

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
                _PremiumBanner(premium: premium),

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
                  footer: t.directionFooter,
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

                SettingsSection(
                  title: t.myData,
                  children: [
                    SettingsRow(
                      title: t.statLearned,
                      icon: Icons.check_circle_rounded,
                      trailing: '$learnedCount',
                    ),
                    SettingsRow(
                      title: t.myStarred,
                      icon: Icons.star_rounded,
                      trailing: '$starredCount',
                    ),
                    SettingsRow(
                      title: t.statStreak,
                      icon: Icons.local_fire_department_rounded,
                      trailing: t.days(streakCount),
                    ),
                  ],
                ),

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

/// Sürüm satırı — arka arkaya yedi dokunuşta premium'u test için açar.
///
/// Mağaza bağlantısı henüz yok; yayına çıkmadan önce içerideki her şeyin
/// elle denenebilmesi gerekiyor. Kazara bulunmayacak kadar gizli, geliştirici
/// derlemesi beklemeyecek kadar da erişilebilir.
class _VersionRow extends ConsumerStatefulWidget {
  const _VersionRow();

  @override
  ConsumerState<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends ConsumerState<_VersionRow> {
  static const _tapsNeeded = 7;

  int _taps = 0;
  DateTime? _first;

  void _onTap() {
    final now = DateTime.now();
    // Dokunuslar arasi uzun bosluk sayaci sifirlar; boylece gunluk kullanimda
    // birikip kendiliginden tetiklenmez.
    if (_first == null || now.difference(_first!) > const Duration(seconds: 6)) {
      _first = now;
      _taps = 0;
    }
    _taps++;

    if (_taps < _tapsNeeded) return;
    _taps = 0;
    _first = null;

    final premium = ref.read(premiumProvider.notifier);
    final active = ref.read(isPremiumProvider);
    if (active) {
      premium.deactivate();
    } else {
      premium.activate(PremiumPlan.yearly);
    }
    Haptics.medium();

    final strings = ref.read(stringsProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(active ? strings.testModeOff : strings.testModeOn),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return SettingsRow(
      title: 'FlipRU',
      subtitle: t.appSubtitle,
      icon: Icons.auto_stories_rounded,
      trailing: t.version,
      onTap: _onTap,
    );
  }
}


/// Ayar listesinden ayrışan premium tanıtım alanı.
///
/// Ayar satırlarıyla aynı görünürse "bir ayar" gibi algılanıyor; burası bir
/// teklif, o yüzden kendi zemini ve rengi var.
class _PremiumBanner extends ConsumerWidget {
  const _PremiumBanner({required this.premium});

  final PremiumState premium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final active = premium.isActive;

    return Pressable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [palette.learned, Color.lerp(palette.learned, palette.accent, 0.4)!]
                : [palette.accent, Color.lerp(palette.accent, palette.star, 0.5)!],
          ),
          boxShadow: [
            BoxShadow(
              color: (active ? palette.learned : palette.accent)
                  .withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active ? s.premiumActive : s.premiumTitle,
                    style: textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    active
                        ? '${premium.remainingDays} ${s.premiumDaysLeft}'
                        : s.premiumPitch,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}


/// Hukuki belgeler ve iletişim: ayar listesinin bir parçası değil, sayfanın
/// dibinde küçük bağlantılar. İngilizce tutuluyor.
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
