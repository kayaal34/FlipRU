import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/widget_service.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/segmented_switch.dart';
import '../../data/models/deck.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../../providers/quiz_stats_provider.dart';
import '../alphabet/alphabet_screen.dart';
import '../quiz/quiz_screen.dart';
import '../study/study_screen.dart';
import '../../providers/unit_providers.dart';
import '../units/unit_list_screen.dart';
import 'widgets/deck_tiles.dart';
import '../../providers/settings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  void _openDeck(Deck deck) {
    final words = ref.read(deckWordsProvider(deck.id));
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(stringsProvider).deckEmpty)),
      );
      return;
    }
    // Doğrudan karta değil, bölüm listesine giriyoruz: kullanıcı önce neyi
    // çalışacağını görsün, sırayla ilerlesin.
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UnitListScreen(deck: deck)));
  }

  void _openAlphabet() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AlphabetScreen()));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final levelDecks = ref.watch(levelDecksProvider);
    final themeDecks = ref.watch(themeDecksProvider);
    final alphabetCompact =
        _alphabetDone(ref) == _alphabetSteps ||
        ref.watch(learnedProvider).length >= 20;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 32),
                  // Yildizli/Ogrendigim kartlari burada degil, Pratik
                  // sekmesinde duruyor: ana ekran "bugun ne yapmaliyim"
                  // sorusuna ve destelere ayrildi.
                  SegmentedSwitch(
                    labels: [s.levels, s.themes],
                    selectedIndex: _tab,
                    onChanged: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _tab == 0
                          ? Column(
                              key: const ValueKey('levels'),
                              children: [
                                // Alfabe seviyelerin basinda: A1'den once
                                // ogrenilmesi gereken sey o. Temalar
                                // sekmesinde yeri yok.
                                // Yeni başlayana büyük kart en üstte; alfabe
                                // bittiyse ya da kullanıcı zaten okuyabiliyorsa
                                // ince bir satır olarak listenin sonuna iniyor.
                                if (!alphabetCompact) ...[
                                  _AlphabetCard(onTap: _openAlphabet),
                                  const SizedBox(height: 8),
                                ],
                                for (final deck in levelDecks) ...[
                                  DeckRow(
                                    deck: deck,
                                    progress: ref.watch(
                                      deckProgressProvider(deck.id),
                                    ),
                                    onTap: () => _openDeck(deck),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (alphabetCompact)
                                  _AlphabetCard(
                                    onTap: _openAlphabet,
                                    compact: true,
                                  ),
                              ],
                            )
                          : GridView.count(
                              key: const ValueKey('themes'),
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.2,
                              children: [
                                for (final deck in themeDecks)
                                  DeckCard(
                                    deck: deck,
                                    progress: ref.watch(
                                      deckProgressProvider(deck.id),
                                    ),
                                    onTap: () => _openDeck(deck),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  /// Uygulama adı açılış ekranında ve ayarlarda; burada onu tekrar etmek
  /// yerine kullanıcıyı selamlıyoruz.
  /// Duruma göre bir söz listesi seçip, yılın gününe göre birini alıyor:
  /// gün içinde sabit kalır, ertesi gün değişir, arka arkaya aynısı gelmez.
  String _motivation(
    Strings s, {
    required bool goalDone,
    required int streak,
    required bool everStudied,
  }) {
    final now = DateTime.now();
    final List<String> pool;
    if (!everStudied) {
      pool = s.motivFirst;
    } else if (goalDone) {
      pool = s.motivGoalDone;
    } else if (streak == 0) {
      pool = s.motivComeback;
    } else if (now.hour < 11) {
      pool = s.motivMorning;
    } else if (now.hour >= 19) {
      pool = s.motivEvening;
    } else {
      pool = s.motivStreak;
    }
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return pool[dayOfYear % pool.length];
  }

  String _greeting(Strings s) {
    final hour = DateTime.now().hour;
    if (hour < 6) return s.greetingNight;
    if (hour < 12) return s.greetingMorning;
    if (hour < 18) return s.greetingDay;
    return s.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final overall = ref.watch(overallProgressProvider);
    final daily = ref.watch(dailySummaryProvider);
    final streak = ref.watch(streakProvider);
    final dayDone = daily.goalReached && ref.watch(dailyTestDoneProvider);
    final s = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selamlama solda, toplam seri sağ üstte; altında haftanın günleri.
        // Seriyi sürdürdüğün günler alevle işaretli, bugün koyu.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uzun selamlama ("Добрый вечер") dar ekranda iki
                  // satıra kaymasın, sığacak kadar küçülsün. Kalın değil
                  // yarı kalın: ekranın ferah durmasını sağlayan bu.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _greeting(s),
                      maxLines: 1,
                      style: AppTypography.largeTitle(palette.textPrimary)
                          .copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.dateLine(DateTime.now()),
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.textTertiary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          PhosphorIconsFill.sparkle,
                          size: 16,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _motivation(
                            s,
                            goalDone: daily.goalReached,
                            streak: streak,
                            everStudied: ref.watch(studyDayProvider).isNotEmpty,
                          ),
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _StreakBadge(days: streak),
          ],
        ),
        const SizedBox(height: 24),
        const _WeekStrip(),
        const _ReminderCard(),
        const _ResumeCard(),
        const SizedBox(height: 32),
        Text(s.todayProgress, style: textTheme.titleMedium),
        const SizedBox(height: 16),
        // Hedef ve günün testi ikisi de bittiyse tek kart: aynı ekranda
        // iki ayrı "tamam" kartı ve iki ayrı devam düğmesi kalabalık ediyordu.
        if (dayDone)
          const _DayDoneCard()
        else ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                ProgressRing(
                  value: daily.ratio,
                  color: daily.goalReached ? palette.learned : _flame,
                  size: 52,
                  strokeWidth: 5,
                  child: daily.goalReached
                      ? Icon(
                          PhosphorIconsBold.check,
                          size: 22,
                          color: palette.learned,
                        )
                      : Text(
                          s.percent((daily.ratio * 100).round()),
                          style: textTheme.labelMedium?.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daily.goalReached
                            ? s.goalDone
                            // "Bugün" bölüm başlığında; burada tekrar etmiyor.
                            : '${daily.today} / ${daily.goal} '
                                  '${s.wordUnit(daily.goal)}',
                        style: textTheme.labelLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        // Teşvik mesajı günün ilerlemesine göre değişiyor.
                        daily.goalReached
                            ? s.comeBackTomorrow
                            : switch (daily.ratio) {
                                >= 0.5 => s.encourageAlmost,
                                > 0 => s.encourageGoing,
                                _ => s.encourageStart,
                              },
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.totalLearned} · ${s.number(overall.learned)} '
                        '${s.wordUnit(overall.learned)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _DailyTestCard(),
        ],
        const _WidgetTipCard(),
      ],
    );
  }
}

/// Widget önerisi bir kez gösterildi mi (eklendi ya da "şimdi değil" dendi)?
class WidgetTipNotifier extends Notifier<bool> {
  static const _key = 'widget_tip_done';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  void markDone() {
    state = true;
    ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final widgetTipDoneProvider = NotifierProvider<WidgetTipNotifier, bool>(
  WidgetTipNotifier.new,
);

/// Tek seferlik öneri: "günün kelimesini ana ekranına ekle".
///
/// Widget'ın varlığı yalnızca ayarlarda anlatılıyordu ve neredeyse kimse
/// görmüyordu. Kart, kullanıcı ilk kez bir şey çalıştıktan sonra çıkıyor —
/// uygulamayı daha tanımadan widget önermek erken olurdu. Ana ekranda zaten
/// bir FlipRU widget'ı varsa hiç görünmüyor; kapatıldıysa bir daha gelmiyor.
class _WidgetTipCard extends ConsumerStatefulWidget {
  const _WidgetTipCard();

  @override
  ConsumerState<_WidgetTipCard> createState() => _WidgetTipCardState();
}

class _WidgetTipCardState extends ConsumerState<_WidgetTipCard> {
  /// Kurulu mu diye sormadan kartı çizmeyelim: widget'ı olan kullanıcıya
  /// bir anlığına bile öneri göstermek tuhaf durur.
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (ref.read(widgetTipDoneProvider)) return;
    final installed = await const WidgetService().isInstalled();
    if (!mounted) return;
    if (installed) {
      ref.read(widgetTipDoneProvider.notifier).markDone();
      return;
    }
    setState(() => _checked = true);
  }

  Future<void> _add() async {
    Haptics.light();
    final service = const WidgetService();
    final notifier = ref.read(widgetTipDoneProvider.notifier);
    if (await service.canPin()) {
      await service.requestPin();
      notifier.markDone();
      return;
    }
    // Launcher tek dokunuşla eklemeyi desteklemiyorsa elle nasıl
    // ekleneceğini anlat.
    if (!mounted) return;
    final s = ref.read(stringsProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.widgetTipManualTitle),
        content: Text(s.widgetTipManualBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.gotIt),
          ),
        ],
      ),
    );
    notifier.markDone();
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(widgetTipDoneProvider);
    final studied = ref.watch(studyDayProvider).isNotEmpty;
    if (done || !studied || !_checked) return const SizedBox.shrink();

    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: palette.accentSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.squaresFour,
                    size: 24,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.widgetTipTitle, style: textTheme.labelLarge),
                      const SizedBox(height: 3),
                      Text(
                        s.widgetTipBody,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Haptics.light();
                    ref.read(widgetTipDoneProvider.notifier).markDone();
                  },
                  child: Text(s.widgetTipLater),
                ),
                const SizedBox(width: 4),
                FilledButton(onPressed: _add, child: Text(s.widgetTipAdd)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Alev rengi: seri rozeti, hafta şeridi ve hatırlatıcı kartı ortak
/// kullanıyor. Paletteki yıldız sarısından ayrı: alev daha sıcak durmalı.
const _flame = Color(0xFFF0762A);

Color _flameSoft(AppPalette palette) =>
    palette.isDark ? _flame.withValues(alpha: 0.18) : const Color(0xFFFFE9D6);

/// Ardışık gün serisi, sağ üstte. Uygulamanın en görünür motivasyon öğesi.
class _StreakBadge extends ConsumerWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final active = days > 0;
    final color = active ? _flame : palette.textTertiary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: active ? _flameSoft(palette) : palette.surfaceSunken,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.fire, size: 30, color: color),
          const SizedBox(width: 8),
          Text(
            '$days',
            style: textTheme.titleLarge?.copyWith(
              color: color,
              fontSize: 26,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bu haftanın günleri (pazartesiden pazara). Yalnızca iki şey öne
/// çıkıyor: çalışılan günler alevli, bugün koyu. Geri kalanı sade beyaz.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final studied = ref.watch(studyDayProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayCell(
              label: s.weekdays[i],
              day: DateTime(monday.year, monday.month, monday.day + i),
              today: today,
              done: studied.contains(
                studyDayKey(
                  DateTime(monday.year, monday.month, monday.day + i),
                ),
              ),
              palette: palette,
              textTheme: textTheme,
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.day,
    required this.today,
    required this.done,
    required this.palette,
    required this.textTheme,
  });

  final String label;
  final DateTime day;
  final DateTime today;
  final bool done;
  final AppPalette palette;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;

    final Color background;
    final Color foreground;
    if (isToday && done) {
      background = _flame;
      foreground = Colors.white;
    } else if (isToday) {
      background = palette.textPrimary;
      foreground = palette.canvas;
    } else if (done) {
      background = _flameSoft(palette);
      foreground = _flame;
    } else {
      background = palette.surface;
      foreground = palette.textSecondary;
    }

    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: isToday ? palette.textPrimary : palette.textTertiary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          // Alevli günde sayı yerine alev: referanstaki gibi tek simge.
          child: done
              ? Icon(PhosphorIconsFill.fire, size: 19, color: foreground)
              : Text(
                  '${day.day}',
                  style: textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontSize: 14,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Bildirimler kapalıysa (uygulama içinde ya da telefonda) seriyi korumak
/// için hatırlatıcıyı açmayı öneren kart. Açılınca kendiliğinden kalkıyor.
class _ReminderCard extends ConsumerStatefulWidget {
  const _ReminderCard();

  @override
  ConsumerState<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends ConsumerState<_ReminderCard> {
  /// Sistem izni; okunana kadar null ve kart görünmüyor.
  bool? _systemEnabled;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _check();
    // Telefon ayarlarından izin verip dönünce kart hemen kalksın.
    _lifecycle = AppLifecycleListener(onResume: _check);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final enabled = await ref.read(notificationServiceProvider).areEnabled();
    if (mounted) setState(() => _systemEnabled = enabled);
  }

  Future<void> _enable() async {
    Haptics.light();
    final service = ref.read(notificationServiceProvider);
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(reminderEnabled: true));
    await service.requestPermission();
    final enabled = await service.areEnabled();
    if (!mounted) return;
    setState(() => _systemEnabled = enabled);
    if (!enabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(ref.read(stringsProvider).reminderCardBlocked),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final system = _systemEnabled;
    final show =
        settings.onboardingDone &&
        system != null &&
        (!settings.reminderEnabled || !system);

    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final dark = palette.isDark;
    final ink = dark ? palette.textPrimary : const Color(0xFF3B1B0A);

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: dark
                      ? _flame.withValues(alpha: 0.16)
                      : const Color(0xFFFFE3D2),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.reminderCardTitle,
                            style: textTheme.titleMedium?.copyWith(color: ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.reminderCardBody,
                            style: textTheme.bodySmall?.copyWith(
                              color: dark
                                  ? palette.textSecondary
                                  : const Color(0xFF7A4A2E),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Pressable(
                            onTap: _enable,
                            child: Container(
                              // 13 + 18 + 13: en az 44 px dokunma alanı.
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: dark ? _flame : const Color(0xFF3B1B0A),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                s.reminderCardAction,
                                style: textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      PhosphorIconsFill.bellRinging,
                      size: 68,
                      color: _flame,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Alfabe dersinin adım sayısı: üç harf grubu + okuma adımı.
const _alphabetSteps = 4;

/// Öğrenilen dilin alfabesinden kaç adım bitti.
int _alphabetDone(WidgetRef ref) {
  final settings = ref.watch(settingsProvider);
  final prefix = settings.language == AppLanguage.tr ? 'ru' : 'tr';
  return settings.alphabetDone.where((k) => k.startsWith('$prefix:')).length;
}

class _AlphabetCard extends ConsumerWidget {
  const _AlphabetCard({required this.onTap, this.compact = false});

  final VoidCallback onTap;

  /// Alfabe bittiyse ya da kullanıcı zaten okuyabiliyorsa tek satırlık hâl.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    const total = _alphabetSteps;
    final done = _alphabetDone(ref);
    final ratio = done / total;

    if (compact) {
      return Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.textAa,
                  color: palette.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(s.alphabetTitle, style: textTheme.labelLarge),
              ),
              if (done == total)
                Icon(
                  PhosphorIconsBold.checkCircle,
                  size: 20,
                  color: palette.accent,
                )
              else
                Text(
                  s.percent((ratio * 100).round()),
                  style: textTheme.labelMedium?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 18,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      );
    }

    return Pressable(
      onTap: onTap,
      child: Container(
        // Seviye satirlariyla ayni olculer: ikisi de ayni listede.
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                PhosphorIconsRegular.textAa,
                color: palette.accent,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.alphabetTitle,
                    style: textTheme.titleMedium?.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.alphabetCardSub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Seviye satirlarindaki gibi ilerleme halkasi: alfabe de
            // bitirilebilir bir bolum, tamamlaninca tik gosteriyor.
            ProgressRing(
              value: ratio,
              color: palette.accent,
              size: 48,
              child: done == total
                  ? Icon(
                      PhosphorIconsBold.check,
                      size: 23,
                      color: palette.accent,
                    )
                  : Text(
                      '${(ratio * 100).round()}',
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Günün testi kutusu: günlük ilerleme kartının altında, aynı dilde.
///
/// Çözülmüşse yeşil tik, çözülmemişse teste götüren bir ok gösteriyor.
class _DailyTestCard extends ConsumerWidget {
  const _DailyTestCard();

  /// Gunun testi icin gereken en az ogrenilmis kelime sayisi.
  static const _minLearned = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final done = ref.watch(dailyTestDoneProvider);
    final learnedIds = ref.watch(learnedProvider);
    final learned = ref
        .watch(wordRepositoryProvider)
        .allWords
        .where((w) => learnedIds.contains(w.id))
        .toList(growable: false);
    final ready = learned.length >= _minLearned;

    return Pressable(
      onTap: () {
        if (done) return;
        if (!ready) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.needFourLearned)));
          return;
        }
        final secilen = <Word>[...learned]..shuffle();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                QuizScreen(title: s.dailyTest, words: secilen, kind: 'daily'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: done ? Border.all(color: palette.learned) : null,
        ),
        child: Row(
          children: [
            // Ustteki gunluk ilerleme kartiyla ayni halka: iki kutu yan yana
            // durdugu icin ayni gorsel dili konusmalari gerekiyor.
            ProgressRing(
              value: done ? 1 : 0,
              color: done ? palette.learned : palette.textTertiary,
              size: 52,
              strokeWidth: 5,
              child: Icon(
                done ? PhosphorIconsBold.check : PhosphorIconsRegular.exam,
                size: 22,
                color: done ? palette.learned : palette.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.dailyTest, style: textTheme.labelLarge),
                  const SizedBox(height: 3),
                  Text(
                    done ? s.dailyTestDone : s.dailyTestGo,
                    style: textTheme.bodySmall?.copyWith(
                      color: done ? palette.learned : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!done)
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 26,
                color: palette.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Kaldığın yer": açınca tek eylem. Son çalışılan bölümün sıradaki
/// kelimesini gösteriyor, "Devam et" doğrudan karta götürüyor.
class _ResumeCard extends ConsumerWidget {
  const _ResumeCard();

  static const _ink = Color(0xFF1E1B18);
  static const _paper = Color(0xFFF6F2EE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(resumeProvider);
    final dayDone =
        ref.watch(dailySummaryProvider).goalReached &&
        ref.watch(dailyTestDoneProvider);
    if (target == null || dayDone) return const SizedBox.shrink();

    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final learningRussian =
        ref.watch(settingsProvider.select((x) => x.language)) == AppLanguage.tr;
    final learned = ref.watch(learnedProvider);

    final unit = target.progress.unit;
    final total = unit.words.length;
    final done = target.progress.learned;
    final next = unit.words.firstWhere(
      (w) => !learned.contains(w.id),
      orElse: () => unit.words.first,
    );
    final headline = learningRussian ? next.accented : next.turkish;
    final meaning = learningRussian ? next.turkish : next.accented;
    final (label, action, detail) = switch (target.kind) {
      ResumeKind.inProgress => (
        s.resumeLabel,
        s.resumeAction,
        s.resumeLeft(total - done),
      ),
      ResumeKind.next => (
        s.resumeNextLabel,
        s.resumeNextAction,
        s.resumeNew(total),
      ),
      ResumeKind.start => (
        s.resumeStartLabel,
        s.resumeStartAction,
        s.resumeFirst(total),
      ),
    };
    // "Bölüm 7 tamamlandı · sıradaki: Bölüm 8" yalnızca aynı destede bir
    // önceki bölüm varsa; yeni bir seviyeye geçerken anlamsız olur.
    final doneNote = target.kind == ResumeKind.next && unit.index > 0
        ? s.resumeDoneNote('${s.unit} ${unit.index}', unit.titleOf(s))
        : null;

    void open() => _openResume(context, ref, target);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: open,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: BoxDecoration(
                color: palette.isDark ? palette.surfaceRaised : _ink,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFBDB4AA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3530),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${target.deck.titleOf(s)} · ${unit.titleOf(s)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFF2C4A4),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      headline,
                      maxLines: 1,
                      style: AppTypography.hero(
                        _paper,
                      ).copyWith(fontSize: 34, letterSpacing: -0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$meaning · $detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD8CFC6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF3A3530),
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    // 15 + 18 + 15: 48 px yüksekliğinde ana eylem.
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      action,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (doneNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                doneNote,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Kaldığın yer" bölümünü kartlarla açar; ana karttan ve "Ekstra pratik"ten.
void _openResume(BuildContext context, WidgetRef ref, ResumeTarget target) {
  Haptics.light();
  final s = ref.read(stringsProvider);
  final unit = target.progress.unit;
  ref.read(lastUnitProvider.notifier).set(unit.id);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudyScreen(
        title: '${target.deck.titleOf(s)} · ${unit.titleOf(s)}',
        words: unit.words,
        unlearnedFirst: true,
        accent: target.deck.tint,
      ),
    ),
  );
}

/// Günün hedefi ve testi bitince "Bugün" bölümünün yerini alan tek kart.
///
/// Kullanıcıyı "yarın gel" diye bırakmak yerine iki net seçenek sunuyor:
/// yeni kelimeyle devam (Ekstra pratik) ya da öğrendiklerini pekiştirme
/// (Tekrar). Bu sırada "Kaldığın yer" kartı gizli, aynı iş iki yerde durmasın.
class _DayDoneCard extends ConsumerWidget {
  const _DayDoneCard();

  static const _reviewSize = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final learnedIds = ref.watch(learnedProvider);
    final target = ref.watch(resumeProvider);

    void review() {
      Haptics.light();
      final pool =
          ref
              .read(wordRepositoryProvider)
              .allWords
              .where((w) => learnedIds.contains(w.id))
              .toList()
            ..shuffle();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudyScreen(
            title: s.reviewAction,
            words: pool.take(_reviewSize).toList(growable: false),
          ),
        ),
      );
    }

    Widget stat(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: palette.textTertiary),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.learnedSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsBold.check,
                      size: 24,
                      color: palette.learned,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.dayDoneTitle, style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          s.dayDoneBody,
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: palette.separator),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  children: [
                    stat(
                      s.dailyTest,
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsBold.check,
                            size: 16,
                            color: palette.learned,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.solvedShort,
                            style: textTheme.labelLarge?.copyWith(
                              color: palette.learned,
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 32, color: palette.separator),
                    stat(
                      s.totalLearned,
                      Text(
                        '${s.number(learnedIds.length)} '
                        '${s.wordUnit(learnedIds.length)}',
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (target != null) ...[
              Expanded(
                child: Pressable(
                  onTap: () => _openResume(context, ref, target),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsBold.lightning,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.extraPractice,
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Pressable(
                onTap: review,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIconsBold.arrowsClockwise,
                        size: 18,
                        color: palette.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(s.reviewAction, style: textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
