import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/deck.dart';
import '../../data/models/study_unit.dart';
import '../../data/models/word.dart';
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
    final s = ref.watch(stringsProvider);


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

    // Bolum testi bolumun butun kelimelerini soruyor: "20/20" ancak boyle
    // anlamli oluyor. Celdiriciler sozlugun tamamindan geldigi icin kelime
    // sayisi sinirina gerek yok.
    _startQuiz(
      context,
      title: '${progress.unit.titleOf(s)} · ${s.test}',
      words: progress.unit.words,
      questionCount: progress.unit.words.length,
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
    required List<Word> words,
    required int questionCount,
    String? unitId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          title: title,
          words: words,
          accent: deck.tint,
          questionCount: questionCount,
          unitId: unitId,
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
