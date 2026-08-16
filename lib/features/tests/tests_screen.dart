import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/deck.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/premium_provider.dart';
import '../premium/premium_screen.dart';
import '../quiz/quiz_screen.dart';

/// Testler sekmesi: kullanıcının kendini ölçebileceği bütün yollar.
class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final repository = ref.watch(wordRepositoryProvider);
    final learnedIds = ref.watch(learnedProvider);
    final starredIds = ref.watch(starredProvider);
    final locked = ref.watch(generalTestsLockedProvider);
    final t = ref.watch(stringsProvider);

    final learned = repository.allWords
        .where((w) => learnedIds.contains(w.id))
        .toList(growable: false);
    final starred = repository.allWords
        .where((w) => starredIds.contains(w.id))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  t.testsTitle,
                  style: AppTypography.largeTitle(palette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  t.testsSubtitle,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),

                _TestCard(
                  icon: Icons.today_rounded,
                  tint: palette.accent,
                  title: t.dailyTest,
                  subtitle: learned.length < 4
                      ? t.needFourLearned
                      : t.dailyTestSub,
                  locked: false,
                  enabled: learned.length >= 4,
                  onTap: () => _start(
                    context,
                    ref,
                    t.dailyTest,
                    _shuffled(learned, 15),
                  ),
                ),
                const SizedBox(height: 10),
                _TestCard(
                  icon: Icons.check_circle_rounded,
                  tint: palette.learned,
                  title: t.myLearned,
                  subtitle: '${t.words(learned.length)} ${t.fromWords}',
                  locked: false,
                  enabled: learned.length >= 4,
                  onTap: () =>
                      _start(context, ref, t.myLearned, learned),
                ),
                const SizedBox(height: 10),
                _TestCard(
                  icon: Icons.star_rounded,
                  tint: palette.star,
                  title: t.myStarred,
                  subtitle: starred.length < 4
                      ? t.needFourStarred
                      : '${t.words(starred.length)} ${t.fromWords}',
                  locked: locked,
                  enabled: starred.length >= 4,
                  onTap: () => _start(context, ref, t.myStarred, starred),
                ),

                const SizedBox(height: 26),
                Text(
                  t.levelTests,
                  style: textTheme.labelSmall
                      ?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 10),
                for (final deck in ref.watch(levelDecksProvider))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LevelTestRow(deck: deck),
                  ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: palette.surfaceSunken,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 19,
                        color: palette.textTertiary,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          t.unitTestInfo,
                          style: textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Word> _shuffled(List<Word> words, int count) {
    final copy = [...words]..shuffle(Random());
    return copy.take(count).toList();
  }

  void _start(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Word> words,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(title: title, words: words),
      ),
    );
  }
}

class _LevelTestRow extends ConsumerWidget {
  const _LevelTestRow({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final words = ref.watch(deckWordsProvider(deck.id));
    final learned = ref.watch(learnedProvider);
    final premium = ref.watch(isPremiumProvider);
    final t = ref.watch(stringsProvider);

    final known = words.where((w) => learned.contains(w.id)).toList();

    // Ucretsiz surumde test yalnizca ogrenilmis kelimeleri sorar — bilmedigin
    // seyden sinava girmek ogretici degil. Premium'da butun seviye acik:
    // abone, hic calismamis olsa bile seviyeyi bastan sona olcebilir.
    final pool = premium ? words : known;
    final enabled = pool.length >= 4;

    return _TestCard(
      badge: deck.level?.label,
      icon: deck.icon,
      tint: deck.tint,
      title: '${deck.titleOf(t)} · ${deck.subtitleOf(t)}',
      subtitle: premium
          ? '${t.words(words.length)} · ${t.levelTestAll}'
          : (known.length < 4
              ? t.levelTestNeed
              : '${known.length} ${t.levelTestKnown}'),
      locked: false,
      enabled: enabled,
      compact: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            title: '${deck.titleOf(t)} · ${t.test}',
            words: pool,
            accent: deck.tint,
          ),
        ),
      ),
      trailing: Text(
        '${known.length}/${words.length}',
        style: textTheme.bodySmall?.copyWith(color: palette.textTertiary),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.locked,
    required this.enabled,
    required this.onTap,
    this.compact = false,
    this.trailing,
    this.badge,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final bool locked;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;
  final Widget? trailing;

  /// Seviye rozetinde ikon yerine kodu gosteriyoruz (A1, B2…).
  ///
  /// Ikon seti burada 1–5 arasi numarali kareler veriyordu; hem cirkindi hem
  /// de seviye adiyla ilgisi yoktu. Ana ekrandaki deste kartlariyla ayni dili
  /// konussun diye kodun kendisi yaziliyor.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final active = enabled && !locked;

    return Pressable(
      onTap: () {
        if (locked) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
          return;
        }
        if (!enabled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(subtitle)));
          return;
        }
        onTap();
      },
      child: Opacity(
        opacity: active ? 1 : 0.72,
        child: Container(
          padding: EdgeInsets.all(compact ? 13 : 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            border: Border.all(color: palette.separator),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: badge == null
                    ? Icon(icon, color: tint, size: compact ? 19 : 22)
                    : Text(
                        badge!,
                        style: textTheme.labelLarge?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 15,
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textTertiary),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              const SizedBox(width: 4),
              Icon(
                locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                size: locked ? 19 : 24,
                color: locked ? palette.star : palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
