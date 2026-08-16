import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/word.dart';
import 'study_screen.dart';
import '../../providers/settings_provider.dart';

/// Seans bitince gösterilen özet.
///
/// Amaç sadece skor göstermek değil; kullanıcıyı "tekrar edilecekleri hemen
/// çalış" akışına yönlendirerek öğrenme döngüsünü kapatmak.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({
    required this.deckTitle,
    required this.learnedWords,
    required this.reviewWords,
    this.accent,
    super.key,
  });

  final String deckTitle;
  final List<Word> learnedWords;
  final List<Word> reviewWords;
  final Color? accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final total = learnedWords.length + reviewWords.length;
    final ratio = total == 0 ? 0.0 : learnedWords.length / total;
    final tint = accent ?? palette.accent;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ProgressRing(
                    value: ratio,
                    color: palette.learned,
                    size: 168,
                    strokeWidth: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '%${(ratio * 100).round()}',
                          style: textTheme.displayLarge,
                        ),
                        Text(
                          s.percentLearned,
                          style: textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    _headline(ratio, s),
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$deckTitle · $total ${s.sessionSummary}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.check_circle_rounded,
                          color: palette.learned,
                          value: learnedWords.length,
                          label: s.sessionLearned,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.refresh_rounded,
                          color: palette.review,
                          value: reviewWords.length,
                          label: s.sessionReview,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (reviewWords.isNotEmpty)
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: tint),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => StudyScreen(
                            title: '${s.badgeReview} · $deckTitle',
                            words: reviewWords,
                            accent: accent,
                          ),
                        ),
                      ),
                      child: Text(
                        '${s.studyReviewWords} (${reviewWords.length})',
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(s.backHome),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _headline(double ratio, Strings s) {
    if (ratio >= 0.9) return s.resultGreat;
    if (ratio >= 0.6) return s.resultGood;
    if (ratio >= 0.3) return s.resultHalf;
    return s.resultPoor;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.separator),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: textTheme.headlineMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }
}
