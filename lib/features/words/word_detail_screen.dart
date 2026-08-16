import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/settings_provider.dart';
import '../study/widgets/report_sheet.dart';

/// Tek bir kelimenin tam sayfası.
///
/// Kart akışı hızlı tekrar için; burası "bu kelimeye bir dakika bakayım"
/// dendiğinde açılan yer.
class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({required this.word, super.key});

  final Word word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final isStarred = ref.watch(starredProvider).contains(word.id);
    final isLearned = ref.watch(learnedProvider).contains(word.id);
    final speech = ref.read(speechServiceProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(word.russian),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isStarred ? palette.star : palette.textSecondary,
            ),
            tooltip: isStarred ? s.starRemove : s.starAdd,
            onPressed: () {
              final added =
                  ref.read(starredProvider.notifier).toggle(word.id);
              added ? Haptics.medium() : Haptics.light();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                // ── Başlık kartı ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: word.tint.withValues(alpha: 0.35),
                    ),
                    boxShadow: palette.ambientShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Chip(label: word.level.label, color: word.tint),
                          const SizedBox(width: 8),
                          _Chip(
                            label: s.posName(word.partOfSpeech),
                            color: palette.textTertiary,
                            filled: false,
                          ),
                          if (word.theme != null) ...[
                            const SizedBox(width: 8),
                            _Chip(
                              label: s.themeName(word.theme!),
                              color: word.theme!.tint,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        settings.showStressMarks ? word.accented : word.russian,
                        textAlign: TextAlign.center,
                        style: AppTypography.hero(palette.textPrimary).copyWith(
                          fontSize: word.russian.length > 14 ? 32 : 42,
                        ),
                      ),
                      if (settings.showTransliteration) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceSunken,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            word.transliteration,
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.separator),
                          foregroundColor: palette.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Haptics.light();
                          speech.speak(word.russian);
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 19),
                        label: Text(s.listen),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
                _Section(
                  title: s.meaning,
                  child: Text(
                    word.turkish,
                    style: textTheme.headlineMedium
                        ?.copyWith(color: palette.textPrimary, height: 1.3),
                  ),
                ),

                if (word.hasExample) ...[
                  const SizedBox(height: 22),
                  _Section(
                    title: s.example,
                    action: IconButton(
                      icon: Icon(
                        Icons.graphic_eq_rounded,
                        size: 19,
                        color: palette.accent,
                      ),
                      tooltip: s.listen,
                      onPressed: () {
                        Haptics.light();
                        speech.speak(word.exampleRu);
                      },
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.exampleRu,
                          style: textTheme.bodyLarge?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          word.exampleTr,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),
                _Section(
                  title: s.status,
                  child: Column(
                    children: [
                      _StatusRow(
                        icon: isLearned
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color:
                            isLearned ? palette.learned : palette.textTertiary,
                        label: isLearned ? s.learnedYes : s.learnedNo,
                        actionLabel: isLearned ? s.markReview : s.markLearned,
                        onAction: () {
                          Haptics.medium();
                          final notifier = ref.read(learnedProvider.notifier);
                          isLearned
                              ? notifier.markForReview(word.id)
                              : notifier.markLearned(word.id);
                        },
                      ),
                      Divider(color: palette.separator, height: 24),
                      _StatusRow(
                        icon: isStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isStarred ? palette.star : palette.textTertiary,
                        label: isStarred ? s.starredYes : s.starredNo,
                        actionLabel: isStarred ? s.starRemove : s.starAdd,
                        onAction: () {
                          final added = ref
                              .read(starredProvider.notifier)
                              .toggle(word.id);
                          added ? Haptics.medium() : Haptics.light();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                Center(
                  child: TextButton.icon(
                    onPressed: () => showReportSheet(context, ref, word),
                    icon: Icon(
                      Icons.flag_outlined,
                      size: 17,
                      color: palette.textTertiary,
                    ),
                    label: Text(
                      s.reportWord,
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textTertiary),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: textTheme.labelSmall
                  ?.copyWith(color: palette.textTertiary),
            ),
            const Spacer(),
            ?action,
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.separator),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 21, color: color),
        const SizedBox(width: 11),
        Expanded(child: Text(label, style: textTheme.bodyLarge)),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.filled = true});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
