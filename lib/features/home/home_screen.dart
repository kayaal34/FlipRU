import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/segmented_switch.dart';
import '../../data/models/deck.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../alphabet/alphabet_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final levelDecks = ref.watch(levelDecksProvider);
    final themeDecks = ref.watch(themeDecksProvider);

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
                                _AlphabetCard(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AlphabetScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
    if (hour < 6) return Icons.bedtime_rounded;
    if (hour < 12) return Icons.wb_twilight_rounded;
    if (hour < 18) return Icons.wb_sunny_rounded;
    return Icons.nights_stay_rounded;
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
        // Selamlama ve seri aynı satırda: seri tek başına bir satır
        // kaplıyordu ve üst taraf boş görünüyordu. Saate göre değişen
        // simge ve tarih satırı, tek başına duran selamlamaya can veriyor.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_greetingIcon(), size: 26, color: palette.star),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          _greeting(s),
                          style: AppTypography.largeTitle(palette.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.dateLine(DateTime.now()),
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
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
                        Icons.check_rounded,
                        size: 22,
                        color: palette.learned,
                      )
                    : Text(
                        '%${(daily.ratio * 100).round()}',
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
      ],
    );
  }
}

/// Ardışık gün serisi. Uygulamanın en görünür motivasyon öğesi olduğu için
/// başlıkla aynı ağırlıkta duruyor.
class _StreakBadge extends ConsumerWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final active = days > 0;

    // Yalnızca alev + sayı: "günlük seri" yazısı her açılışta aynı şeyi
    // tekrar ediyor ve selamlamanın yanında yer kaplıyordu.
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 13, 6),
      decoration: BoxDecoration(
        color: active
            ? palette.star.withValues(alpha: 0.15)
            : palette.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? palette.star.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 21,
            color: active ? palette.star : palette.textTertiary,
          ),
          const SizedBox(width: 5),
          Text(
            '$days',
            style: textTheme.titleLarge?.copyWith(
              color: active ? palette.star : palette.textTertiary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlphabetCard extends ConsumerWidget {
  const _AlphabetCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

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
              child: Icon(Icons.abc_rounded, color: palette.accent, size: 30),
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
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 27,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
