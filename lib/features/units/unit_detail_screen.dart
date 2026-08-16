import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/deck.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/study_unit.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../quiz/quiz_screen.dart';
import '../study/study_screen.dart';
import '../study/widgets/report_sheet.dart';
import '../words/word_detail_screen.dart';
import '../../providers/settings_provider.dart';

/// Bölümün kelime listesi.
///
/// Kullanıcı çalışmaya başlamadan önce ne öğreneceğini görebilsin, zorlandığı
/// kelimeleri buradan yıldızlayabilsin diye var.
class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({required this.deck, required this.unit, super.key});

  final Deck deck;
  final StudyUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final starred = ref.watch(starredProvider);
    final learned = ref.watch(learnedProvider);
    final s = ref.watch(stringsProvider);
    final learnedCount = unit.words.where((w) => learned.contains(w.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.unit} ${unit.index + 1}'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$learnedCount / ${unit.words.length} '
                          '${s.unitProgress} ${unit.passThreshold}',
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: unit.words.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final word = unit.words[index];
                      return _WordRow(
                        strings: s,
                        word: word,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WordDetailScreen(word: word),
                          ),
                        ),
                        isStarred: starred.contains(word.id),
                        isLearned: learned.contains(word.id),
                        onStar: () {
                          final added = ref
                              .read(starredProvider.notifier)
                              .toggle(word.id);
                          added ? Haptics.medium() : Haptics.light();
                        },
                        onSpeak: () =>
                            ref.read(speechServiceProvider).speak(word.russian),
                        onReport: () => showReportSheet(context, ref, word),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: palette.canvas,
          border: Border(top: BorderSide(color: palette.separator)),
        ),
        // heightFactor olmadan Center sınırlı kısıt altında tüm ekranı kaplar
        // ve gövdeye yer bırakmaz.
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: deck.tint),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudyScreen(
                          title: '${deck.titleOf(s)} · ${unit.titleOf(s)}',
                          words: unit.words,
                          accent: deck.tint,
                        ),
                      ),
                    ),
                    child: Text(s.studyWithCards),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: BorderSide(color: palette.separator),
                      foregroundColor: palette.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          title: unit.titleOf(s),
                          words: unit.words,
                          accent: deck.tint,
                          // Testi geçmek bu bölümü tamamlamış sayar ve
                          // sonrakinin kilidini açar.
                          unitId: unit.id,
                        ),
                      ),
                    ),
                    child: Text(s.test),
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

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.strings,
    required this.word,
    required this.onOpen,
    required this.isStarred,
    required this.isLearned,
    required this.onStar,
    required this.onSpeak,
    required this.onReport,
  });

  final Strings strings;
  final Word word;
  final VoidCallback onOpen;
  final bool isStarred;
  final bool isLearned;
  final VoidCallback onStar;
  final VoidCallback onSpeak;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.light();
        onOpen();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLearned
                ? palette.learned.withValues(alpha: 0.4)
                : palette.separator,
          ),
        ),
        child: Row(
          children: [
            if (isLearned)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: palette.learned,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          word.accented,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (word.confidence < 3)
                        Tooltip(
                          message: strings.singleSourceWarning,
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 15,
                            color: palette.star,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.turkish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    word.transliteration,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.volume_up_rounded,
                size: 19,
                color: palette.textTertiary,
              ),
              tooltip: strings.pronunciation,
              onPressed: () {
                Haptics.light();
                onSpeak();
              },
            ),
            IconButton(
              icon: Icon(
                isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 21,
                color: isStarred ? palette.star : palette.textTertiary,
              ),
              tooltip: isStarred ? strings.starRemove : strings.starAdd,
              onPressed: onStar,
            ),
            IconButton(
              icon: Icon(
                Icons.flag_outlined,
                size: 18,
                color: palette.textTertiary,
              ),
              tooltip: strings.reportWord,
              onPressed: onReport,
            ),
          ],
        ),
      ),
    );
  }
}
