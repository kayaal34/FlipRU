import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/deck.dart';
import '../../data/models/study_unit.dart';
import '../../providers/library_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/unit_providers.dart';
import '../quiz/quiz_screen.dart';

/// Bir seviyenin test bölümleri.
///
/// Seviye testi eskiden doğrudan başlıyordu ve bütün seviyeyi tek seferde
/// soruyordu — B2'de 2.500 kelime demek. Artık çalışma tarafındaki bölüm
/// yapısının aynısı: kullanıcı bölüm bölüm ölçüyor, geçtiği bölüm sonrakinin
/// kilidini açıyor.
class LevelTestUnitsScreen extends ConsumerWidget {
  const LevelTestUnitsScreen({required this.deck, super.key});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(deckUnitsProvider(deck.id));
    final words = ref.watch(deckWordsProvider(deck.id));
    final learned = ref.watch(learnedProvider);
    final premium = ref.watch(isPremiumProvider);
    final s = ref.watch(stringsProvider);

    final known = words.where((w) => learned.contains(w.id)).toList();
    // Ucretsiz surumde test yalnizca ogrenilmis kelimeleri sorar; premium'da
    // butun seviye acik. Bolum testlerinde de ayni kural gecerli.
    final wholePool = premium ? words : known;
    final passed = units.where((u) => u.passed).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${deck.subtitleOf(s)} · ${s.test}'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WholeLevelCard(
                          deck: deck,
                          title: s.wholeLevelTest,
                          subtitle: wholePool.length < 4
                              ? s.levelTestNeed
                              : '${s.words(wholePool.length)} · '
                                  '$passed/${units.length} ${s.unitsDone}',
                          enabled: wholePool.length >= 4,
                          onTap: () => _startQuiz(
                            context,
                            title: '${deck.titleOf(s)} · ${s.test}',
                            words: wholePool,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          s.unitTestsTitle,
                          style: textTheme.labelSmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _UnitTestTile(
                        progress: units[index],
                        tint: deck.tint,
                        strings: s,
                        onTap: () => _openUnit(context, ref, units[index], s),
                      ),
                      childCount: units.length,
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

  void _openUnit(
    BuildContext context,
    WidgetRef ref,
    UnitProgress progress,
    Strings s,
  ) {
    if (!progress.unlocked) {
      Haptics.medium();
      _warn(context, s.unitLockedHint);
      return;
    }

    // Ucretsiz surumde bolum testi de yalnizca ogrenilmis kelimeleri sorar.
    final premium = ref.read(isPremiumProvider);
    final learned = ref.read(learnedProvider);
    final pool = premium
        ? progress.unit.words
        : progress.unit.words
            .where((w) => learned.contains(w.id))
            .toList(growable: false);

    if (pool.length < 4) {
      Haptics.medium();
      _warn(context, s.levelTestNeed);
      return;
    }

    _startQuiz(
      context,
      title: '${progress.unit.titleOf(s)} · ${s.test}',
      words: pool,
      // Bolum testini gecmek bolumu tamamlamis sayar ve sonrakini acar —
      // calisma tarafindaki testle ayni davranis.
      unitId: progress.unit.id,
    );
  }

  void _warn(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _startQuiz(
    BuildContext context, {
    required String title,
    required List<dynamic> words,
    String? unitId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          title: title,
          words: List.from(words),
          accent: deck.tint,
          unitId: unitId,
        ),
      ),
    );
  }
}

/// "Seviyenin tamamı" seçeneği: eski davranışı koruyor.
class _WholeLevelCard extends StatelessWidget {
  const _WholeLevelCard({
    required this.deck,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final Deck deck;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: () {
        if (!enabled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(subtitle)));
          return;
        }
        onTap();
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
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
                  color: deck.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.all_inclusive_rounded,
                  color: deck.tint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
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
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm karesi. Çalışma tarafındaki bölüm listesiyle aynı görünüm; farkı,
/// dokununca kart çalışması değil test başlatması.
class _UnitTestTile extends StatelessWidget {
  const _UnitTestTile({
    required this.progress,
    required this.tint,
    required this.strings,
    required this.onTap,
  });

  final UnitProgress progress;
  final Color tint;
  final Strings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final locked = !progress.unlocked;
    final color = locked ? palette.textTertiary : tint;

    return Pressable(
      onTap: onTap,
      haptic: !locked,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: progress.testPassed
                  ? tint.withValues(alpha: 0.5)
                  : palette.separator,
              width: progress.testPassed ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                Icon(Icons.lock_rounded, size: 22, color: color)
              else if (progress.testPassed)
                Icon(Icons.workspace_premium_rounded, size: 24, color: color)
              else
                Icon(Icons.quiz_outlined, size: 22, color: color),
              const SizedBox(height: 7),
              Text(
                locked
                    ? strings.locked
                    : '${strings.unit} ${progress.unit.index + 1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium
                    ?.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                '${progress.learned}/${progress.total}',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
