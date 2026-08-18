import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_palette.dart';
import '../../data/models/word.dart';
import 'progress_ring.dart';

/// Test bitince gösterilen sonuç ekranı.
///
/// Çoktan seçmeli test ve yazma pratiği aynı sonucu gösteriyor; ekran burada
/// ortak tutuluyor ki ikisi birbirinden ayrışmasın.
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    required this.title,
    required this.correct,
    required this.total,
    required this.accent,
    required this.strings,
    required this.wrong,
    this.unlockedUnit = false,
    this.onRetryWrong,
    super.key,
  });

  final String title;
  final int correct;
  final int total;
  final Color accent;
  final Strings strings;
  final List<Word> wrong;
  final bool unlockedUnit;
  final VoidCallback? onRetryWrong;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final ratio = total == 0 ? 0.0 : correct / total;
    final perfect = total > 0 && correct == total;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tam puanda halka yerine kocaman bir onay isareti: sonuc
                  // tek bakista anlasilsin.
                  if (perfect)
                    Container(
                      width: 164,
                      height: 164,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.learnedSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.learned, width: 4),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 96,
                        color: palette.learned,
                      ),
                    )
                  else
                    ProgressRing(
                      value: ratio,
                      color: ratio >= 0.7 ? palette.learned : palette.review,
                      size: 164,
                      strokeWidth: 12,
                      child: Text(
                        '%${(ratio * 100).round()}',
                        style: textTheme.displayLarge,
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Buyuk skor: "18 / 20"
                  Text(
                    '$correct / $total',
                    style: textTheme.displayLarge?.copyWith(
                      color: perfect ? palette.learned : palette.textPrimary,
                      fontSize: 46,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ScoreChip(
                        icon: Icons.check_circle_rounded,
                        color: palette.learned,
                        label: '$correct ${strings.correctOf}',
                      ),
                      if (wrong.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        _ScoreChip(
                          icon: Icons.cancel_rounded,
                          color: palette.review,
                          label: '${wrong.length} ${strings.quizWrong}',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    perfect
                        ? strings.perfectScore
                        : switch (ratio) {
                            >= 0.7 => strings.resultGood,
                            >= 0.4 => strings.resultHalf,
                            _ => strings.resultPoor,
                          },
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: textTheme.bodyMedium),
                  if (unlockedUnit) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: palette.learnedSoft,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: palette.learned),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            size: 19,
                            color: palette.learned,
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              strings.unitUnlocked,
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: palette.learned),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (onRetryWrong != null) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.review,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: onRetryWrong,
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: Text(strings.retryWrong),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: palette.separator),
                        foregroundColor: palette.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(strings.finish),
                    ),
                  ] else
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(strings.finish),
                    ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// Sonuc ekranindaki "18 dogru" / "2 yanlis" etiketi.
class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style:
                Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
