
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/segmented_switch.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../../providers/quiz_stats_provider.dart';
import '../../providers/settings_provider.dart';

/// Öğrenme istatistikleri: toplamlar ve seçilen dönemin gün gün dağılımı.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  /// 0: son 7 gün, 1: son 30 gün, 2: tüm zamanlar.
  int _range = 0;

  /// Uzun serileri çizime sığacak kadar kovaya böler.
  ///
  /// Tüm zamanlar seçilince seri yüzlerce güne çıkabiliyor; her güne bir çubuk
  /// düşerse çubuklar bir piksele iner. Özet sayılar ham seriden hesaplandığı
  /// için bu bölme yalnızca görünümü etkiliyor.
  static List<int> _bucket(List<int> values, int maxBars) {
    if (values.length <= maxBars) return values;
    final size = (values.length / maxBars).ceil();
    return [
      for (var i = 0; i < values.length; i += size)
        values.skip(i).take(size).fold(0, (a, b) => a + b),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(learningStatsProvider);
    final streak = ref.watch(streakProvider);
    final total = ref.watch(overallProgressProvider).learned;
    final starred = ref.watch(starredProvider).length;
    final t = ref.watch(stringsProvider);
    final quiz = ref.watch(quizSummaryProvider);

    // Secilen donemin ham gunluk serisi. Ozet sayilar hep bundan cikiyor.
    final seri = switch (_range) {
      0 => stats.last7,
      1 => stats.last30,
      _ => stats.allTimeDaily,
    };
    final toplam = seri.fold(0, (a, b) => a + b);
    final enIyi = seri.isEmpty ? 0 : seri.reduce((a, b) => a > b ? a : b);
    final aktif = seri.where((v) => v > 0).length;
    final ortalama = seri.isEmpty ? 0.0 : toplam / seri.length;

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
                        value: '${stats.thisMonth}',
                        label: t.statMonth,
                        color: palette.accent,
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                // Yıldızlı sayısı eskiden Ayarlar'da duruyordu; kullanıcının
                // kendi verisi olduğu için istatistiğe taşındı.
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
                SegmentedSwitch(
                  labels: [t.last7, t.last30, t.allTime],
                  selectedIndex: _range,
                  onChanged: (i) => setState(() => _range = i),
                ),
                const SizedBox(height: 16),
                if (seri.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.separator),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 19,
                          color: palette.textTertiary,
                        ),
                        const SizedBox(width: 11),
                        Text(
                          t.statsNoData,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: palette.textTertiary),
                        ),
                      ],
                    ),
                  )
                else
                  _BarChart(
                    values: _bucket(seri, 30),
                    // Gun adlari yalnizca yedi gunluk gorunumde anlamli.
                    labels: _range == 0 ? _weekLabels(t.weekdays) : null,
                    color: palette.accent,
                    compact: _range != 0,
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
                      _InfoRow(label: t.bestDay, value: t.words(enIyi)),
                      Divider(color: palette.separator, height: 22),
                      _InfoRow(label: t.activeDays, value: t.days(aktif)),
                      Divider(color: palette.separator, height: 22),
                      _InfoRow(
                        label: t.dailyAverage,
                        value: '${ortalama.toStringAsFixed(1)} '
                            '${t.wordUnit(ortalama.round())}',
                      ),
                    ],
                  ),
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
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

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
            icon,
            color: color,
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
