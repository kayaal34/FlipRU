import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/segmented_switch.dart';
import '../../core/widgets/starred_hero_card.dart';
import '../../data/models/deck.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../learned/learned_screen.dart';
import '../starred/starred_screen.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UnitListScreen(deck: deck)),
    );
  }


  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);
    final levelDecks = ref.watch(levelDecksProvider);
    final themeDecks = ref.watch(themeDecksProvider);
    final starredCount = ref.watch(starredProvider).length;

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
                  const SizedBox(height: 22),
                  StarredHeroCard(
                    title: s.starredTitle,
                    subtitle: starredCount == 0
                        ? s.starredEmptyHint
                        : '${s.words(starredCount)} ${s.starredWaiting}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StarredScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LearnedCard(
                    count: ref.watch(overallProgressProvider).learned,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LearnedScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
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
                                for (final deck in levelDecks) ...[
                                  DeckRow(
                                    deck: deck,
                                    progress:
                                        ref.watch(deckProgressProvider(deck.id)),
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
                                    progress:
                                        ref.watch(deckProgressProvider(deck.id)),
                                    onTap: () => _openDeck(deck),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      s.swipeHint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textTertiary),
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
        Row(
          children: [
            _StreakBadge(days: streak),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(s),
                    style: AppTypography.largeTitle(palette.textPrimary),
                  ),
                ],
              ),
            ),
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
                        style: textTheme.labelMedium
                            ?.copyWith(color: palette.textPrimary),
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
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.words(overall.learned)} ${s.learnedWords}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textTertiary),
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
    final s = ref.watch(stringsProvider);
    final active = days > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 9, 16, 9),
      decoration: BoxDecoration(
        color: active
            ? palette.star.withValues(alpha: 0.15)
            : palette.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
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
            size: 26,
            color: active ? palette.star : palette.textTertiary,
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: textTheme.headlineMedium?.copyWith(
                  color: active ? palette.star : palette.textTertiary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                active ? s.streakDays : s.streakNone,
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearnedCard extends ConsumerWidget {
  const _LearnedCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.separator),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.learned.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: palette.learned,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.myLearned, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    count == 0 ? s.learnedListSub : s.words(count),
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
