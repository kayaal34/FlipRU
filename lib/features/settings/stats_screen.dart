import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/quiz_stats_provider.dart';
import '../../providers/settings_provider.dart';
import '../premium/premium_screen.dart';

/// Öğrenme istatistikleri: haftalık/aylık toplam ve gün gün dağılım.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(learningStatsProvider);
    final streak = ref.watch(streakProvider);
    final total = ref.watch(overallProgressProvider).learned;
    final starred = ref.watch(starredProvider).length;
    final premium = ref.watch(isPremiumProvider);
    final t = ref.watch(stringsProvider);
    final quiz = ref.watch(quizSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.statsTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: '$total',
                        label: t.statLearned,
                        color: palette.learned,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        value: '$streak',
                        label: t.statStreak,
                        color: palette.star,
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: '${stats.thisWeek}',
                        label: t.statWeek,
                        color: palette.accent,
                        icon: Icons.calendar_view_week_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        value: premium ? '${stats.thisMonth}' : '—',
                        label: t.statMonth,
                        color: palette.accent,
                        icon: Icons.calendar_month_rounded,
                        locked: !premium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                // Yıldızlı sayısı eskiden Ayarlar'da duruyordu. Kullanıcının
                // kendi verisi olduğu için premium arkasında değil, burada
                // ücretsiz görünüyor.
                Text(
                  t.myData,
                  style: textTheme.labelSmall
                      ?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.separator),
                  ),
                  child: _InfoRow(label: t.myStarred, value: '$starred'),
                ),
                const SizedBox(height: 26),
                Text(
                  t.last7,
                  style: textTheme.labelSmall
                      ?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 12),
                _BarChart(
                  values: stats.last7,
                  labels: _weekLabels(t.weekdays),
                  color: palette.accent,
                ),
                const SizedBox(height: 26),
                Text(
                  t.quizSection,
                  style: textTheme.labelSmall
                      ?.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.separator),
                  ),
                  child: quiz.count == 0
                      ? Row(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 19,
                              color: palette.textTertiary,
                            ),
                            const SizedBox(width: 11),
                            Text(
                              t.quizNone,
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: palette.textTertiary),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _InfoRow(
                              label: t.quizCount,
                              value: '${quiz.count}',
                            ),
                            Divider(color: palette.separator, height: 22),
                            _InfoRow(
                              label: t.quizAccuracy,
                              value: '%${(quiz.accuracy * 100).round()}',
                            ),
                            Divider(color: palette.separator, height: 22),
                            _InfoRow(
                              label: t.quizBest,
                              value: '%${(quiz.bestRatio * 100).round()}',
                            ),
                            Divider(color: palette.separator, height: 22),
                            _InfoRow(
                              label: t.quizLast,
                              value: '%${(quiz.lastRatio * 100).round()}',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 26),
                _AdvancedSection(
                  premium: premium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.last30,
                        style: textTheme.labelSmall
                            ?.copyWith(color: palette.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      _BarChart(
                        values: stats.last30,
                        color: palette.learned,
                        compact: true,
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.separator),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: t.bestDay,
                              value: t.words(stats.bestDay),
                            ),
                            Divider(color: palette.separator, height: 22),
                            _InfoRow(
                              label: t.activeDays,
                              value: t.days(stats.activeDays),
                            ),
                            Divider(color: palette.separator, height: 22),
                            _InfoRow(
                              label: t.dailyAverage,
                              value:
                                  '${(stats.thisMonth / 30).toStringAsFixed(1)} '
                                  '${t.wordUnit(stats.thisMonth ~/ 30)}',
                            ),
                          ],
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

  List<String> _weekLabels(List<String> names) {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        names[now.subtract(Duration(days: i)).weekday - 1],
    ];
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.color,
    this.labels,
    this.compact = false,
  });

  final List<int> values;
  final Color color;
  final List<String>? labels;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final max = values.fold(0, (a, b) => b > a ? b : a);

    return SizedBox(
      height: compact ? 90 : 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!compact && values[i] > 0)
                      Text(
                        '${values[i]}',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // En yüksek gün tam yüksekliği alır; sıfır günler ince
                    // bir çizgi olarak yine de görünür.
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: max == 0 ? 0 : values[i] / max,
                      ),
                      duration: Duration(milliseconds: 500 + i * 18),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => Container(
                        height: ((compact ? 62 : 84) * t).clamp(3, 84),
                        decoration: BoxDecoration(
                          color: values[i] == 0
                              ? palette.track
                              : color.withValues(alpha: 0.35 + 0.65 * t),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (labels != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        labels![i],
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.locked = false,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.separator),
      ),
      child: Column(
        children: [
          Icon(
            locked ? Icons.lock_rounded : icon,
            color: locked ? palette.star : color,
            size: 21,
          ),
          const SizedBox(height: 9),
          Text(value, style: textTheme.headlineMedium?.copyWith(color: color)),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyLarge),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}


/// İleri istatistikler premium arkasında: temel görünüm herkese açık kalıyor,
/// derinlemesine analiz aboneliğe bağlı. İçerik silinmiyor, bulanıklaşıyor —
/// kullanıcı neyin açılacağını görsün.
class _AdvancedSection extends ConsumerWidget {
  const _AdvancedSection({required this.premium, required this.child});

  final bool premium;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    if (premium) return child;

    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: IgnorePointer(child: Opacity(opacity: 0.6, child: child)),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.canvas.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.star.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 22,
                      color: palette.star,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(s.advancedStats, style: textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text(
                    s.advancedStatsSub,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 44),
                    ),
                    onPressed: () {
                      Haptics.light();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                    },
                    child: Text(s.unlockWithPremium),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
