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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 26),
                  // Yildizli/Ogrendigim kartlari burada degil, Pratik
                  // sekmesinde duruyor: ana ekran "bugun ne yapmaliyim"
                  // sorusuna ve destelere ayrildi.
                  SegmentedSwitch(
                    labels: [s.levels, s.themes],
                    selectedIndex: _tab,
                    onChanged: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: 18),
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
                                  const SizedBox(height: 10),
                                ],
                                for (final deck in levelDecks) ...[
                                  DeckRow(
                                    deck: deck,
                                    progress: ref.watch(
                                      deckProgressProvider(deck.id),
                                    ),
                                    onTap: () => _openDeck(deck),
                                  ),
                                  const SizedBox(height: 10),
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
  String _greeting(Strings s) {
    final hour = DateTime.now().hour;
    if (hour < 6) return s.greetingNight;
    if (hour < 12) return s.greetingMorning;
    if (hour < 18) return s.greetingDay;
    return s.greetingEvening;
  }

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) return PhosphorIconsFill.moon;
    if (hour < 12) return PhosphorIconsFill.sunHorizon;
    if (hour < 18) return PhosphorIconsFill.sun;
    return PhosphorIconsFill.moonStars;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final overall = ref.watch(overallProgressProvider);
    final daily = ref.watch(dailySummaryProvider);
    final streak = ref.watch(streakProvider);
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
                  Row(
                    children: [
                      Icon(_greetingIcon(), size: 32, color: palette.star),
                      const SizedBox(width: 10),
                      // Uzun selamlama ("Добрый вечер") dar ekranda iki
                      // satıra kaymasın, sığacak kadar küçülsün.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _greeting(s),
                            maxLines: 1,
                            style: AppTypography.largeTitle(
                              palette.textPrimary,
                            ).copyWith(fontSize: 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    s.dateLine(DateTime.now()),
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.textTertiary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StreakBadge(days: streak),
          ],
        ),
        const SizedBox(height: 18),
        const _WeekStrip(),
        const _ReminderCard(),
        const SizedBox(height: 20),
        Text(
          s.dailyGoalsTitle,
          style: textTheme.labelSmall?.copyWith(
            color: palette.textTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.separator),
          ),
          child: Row(
            children: [
              ProgressRing(
                value: daily.ratio,
                color: daily.goalReached ? palette.learned : palette.accent,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daily.goalReached
                          ? s.goalDone
                          : '${s.todayProgress} ${daily.today} / ${daily.goal} '
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
                      '${s.words(overall.learned)} ${s.learnedWords}',
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
        const SizedBox(height: 10),
        const _DailyTestCard(),
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
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
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
                const SizedBox(width: 13),
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
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
      decoration: BoxDecoration(
        color: active ? _flameSoft(palette) : palette.surfaceSunken,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.fire, size: 30, color: color),
          const SizedBox(width: 6),
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

/// Bu haftanın günleri (pazartesiden pazara). Çalışılan günler alevli,
/// bugün koyu, kaçırılan günler soluk, gelecek günler boş.
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
    final isFuture = day.isAfter(today);

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
    } else if (isFuture) {
      background = palette.surface;
      foreground = palette.textSecondary;
    } else {
      background = palette.surfaceSunken;
      foreground = palette.textTertiary;
    }

    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: isToday ? palette.textPrimary : palette.textTertiary,
            fontWeight: isToday ? FontWeight.w700 : null,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 40,
          height: 50,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: isFuture ? Border.all(color: palette.separator) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (done)
                Icon(PhosphorIconsFill.fire, size: 18, color: foreground),
              Text(
                '${day.day}',
                style: textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontSize: done ? 11 : 14,
                  height: 1.1,
                ),
              ),
            ],
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
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
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
                          const SizedBox(height: 12),
                          Pressable(
                            onTap: _enable,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
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
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.separator),
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
              const SizedBox(width: 12),
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
              const SizedBox(width: 6),
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
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.separator),
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
            const SizedBox(width: 14),
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
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: done ? palette.learned : palette.separator),
        ),
        child: Row(
          children: [
            // Ustteki gunluk ilerleme kartiyla ayni halka: iki kutu yan yana
            // durdugu icin ayni gorsel dili konusmalari gerekiyor.
            ProgressRing(
              value: done ? 1 : 0,
              color: done ? palette.learned : palette.accent,
              size: 52,
              strokeWidth: 5,
              child: Icon(
                done ? PhosphorIconsBold.check : PhosphorIconsRegular.exam,
                size: 22,
                color: done ? palette.learned : palette.accent,
              ),
            ),
            const SizedBox(width: 14),
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
