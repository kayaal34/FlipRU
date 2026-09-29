import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
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
    final t = ref.watch(stringsProvider);
    final quiz = ref.watch(quizSummaryProvider);
    final hedef = ref.watch(settingsProvider).dailyGoal;

    // Secilen donemin ham gunluk serisi. Ozet sayilar hep bundan cikiyor.
    final seri = switch (_range) {
      0 => stats.last7,
      1 => stats.last30,
      _ => stats.allTimeDaily,
    };
    final toplam = seri.fold(0, (a, b) => a + b);
    // Hic calisma yoksa sifirlarla dolu kutular, bos grafik ve "0 gun"
    // satirlari ayni seyi uc kez soyluyordu; onun yerine tek bir karsilama
    // gosteriliyor.
    final hicVeriYok = total == 0 && !stats.allTimeDaily.any((v) => v > 0);
    final enIyi = seri.isEmpty ? 0 : seri.reduce((a, b) => a > b ? a : b);
    // Secilen donemde gunluk hedefin tutturuldugu gun sayisi.
    final hedefTutan = seri.where((v) => v >= hedef).length;

    return Scaffold(
      // Artik sekme degil, ana ekrandaki seri rozetinden aciliyor: geri
      // dugmesi gerekiyor.
      appBar: AppBar(title: Text(t.statsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: hicVeriYok
                ? _EmptyStats(strings: t)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              value: '$total',
                              label: t.statLearned,
                              color: palette.learned,
                              icon: PhosphorIconsFill.checkCircle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatBox(
                              value: '$streak',
                              label: t.statStreak,
                              color: palette.star,
                              icon: PhosphorIconsFill.fire,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _LevelProgressCard(last30: stats.last30),
                      const SizedBox(height: 26),
                      // Son 7 / son 30 kutulari kaldirildi: ayni bilgiyi
                      // asagidaki donem secici ve grafik zaten veriyor.
                      SegmentedSwitch(
                        labels: [t.last7, t.last30, t.allTime],
                        selectedIndex: _range,
                        onChanged: (i) => setState(() => _range = i),
                      ),
                      const SizedBox(height: 16),
                      // Yalnizca uzunluga degil toplama bakiyoruz: yedi gunluk
                      // seri "0,0,0..." oldugunda da grafik bos ciziliyordu.
                      if (toplam == 0)
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
                                PhosphorIconsRegular.chartBar,
                                size: 19,
                                color: palette.textTertiary,
                              ),
                              const SizedBox(width: 11),
                              Text(
                                t.statsNoData,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: palette.textTertiary,
                                ),
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
                      // Donem ozeti uc satira indi. Onceden dort satirlik bir
                      // kart ve yedi satirlik bir test karti daha vardi;
                      // "gunun testi" ikisinde birden, iki farkli sayiyla
                      // listeleniyordu.
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
                            _InfoRow(
                              label: t.goalHitDays,
                              value: t.days(hedefTutan),
                            ),
                            Divider(color: palette.separator, height: 22),
                            _InfoRow(
                              label: t.quizCount,
                              value: '${quiz.count}',
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

/// Seviye seviye ilerleme ve üzerinde çalışılan seviyenin tahmini bitişi.
///
/// "8819 kelimeden 1240'ı" soyut kalıyor; "A1 %100, B1 %38" ise kullanıcıya
/// neyi başardığını gösteriyor. Tahmin son 14 günün ortalama hızından:
/// bitmemiş ilk seviye için "bu hızla X günde bitirirsin". Hesap ucuz ama
/// hedefi somutlaştırıyor.
class _LevelProgressCard extends ConsumerWidget {
  const _LevelProgressCard({required this.last30});

  final List<int> last30;

  /// Tahmin için gereken asgari hız: günde yarım kelimenin altında sayı
  /// yüzlerce güne çıkıyor ve motive etmek yerine caydırıyor.
  static const _minPace = 0.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final t = ref.watch(stringsProvider);
    final decks = ref.watch(levelDecksProvider);

    final last14 = last30.length > 14
        ? last30.sublist(last30.length - 14)
        : last30;
    final pace = last14.isEmpty ? 0.0 : last14.fold(0, (a, b) => a + b) / 14;

    // Üzerinde çalışılan seviye: bitmemiş ilk seviye.
    String? estimate;
    for (final deck in decks) {
      final progress = ref.watch(deckProgressProvider(deck.id));
      if (progress.isComplete) continue;
      if (pace >= _minPace) {
        final days = (progress.remaining / pace).ceil();
        estimate = days <= 2
            ? t.finishEstimateSoon.replaceFirst('{}', deck.titleOf(t))
            : t.finishEstimate
                  .replaceFirst('{}', deck.titleOf(t))
                  .replaceFirst('{}', '$days');
      }
      break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.levelProgressTitle, style: textTheme.titleSmall),
          const SizedBox(height: 12),
          for (final deck in decks) ...[
            _LevelBar(
              label: deck.titleOf(t),
              name: deck.subtitleOf(t),
              tint: deck.tint,
              progress: ref.watch(deckProgressProvider(deck.id)),
              completeLabel: t.levelComplete,
            ),
            const SizedBox(height: 11),
          ],
          Divider(color: palette.separator, height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.flagCheckered,
                size: 19,
                color: estimate == null ? palette.textTertiary : palette.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimate ?? t.paceNone,
                      style: textTheme.bodyMedium?.copyWith(
                        color: estimate == null
                            ? palette.textTertiary
                            : palette.textPrimary,
                      ),
                    ),
                    if (pace > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        t.paceLine.replaceFirst(
                          '{}',
                          pace.toStringAsFixed(1).replaceAll('.', ','),
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.label,
    required this.name,
    required this.tint,
    required this.progress,
    required this.completeLabel,
  });

  final String label;
  final String name;
  final Color tint;
  final DeckProgress progress;
  final String completeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final percent = (progress.ratio * 100).floor();

    return Row(
      children: [
        Container(
          width: 38,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    progress.isComplete
                        ? completeLabel
                        : '%$percent · ${progress.learned}/${progress.total}',
                    style: textTheme.labelSmall?.copyWith(
                      color: progress.isComplete
                          ? palette.learned
                          : palette.textTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 6,
                  backgroundColor: palette.track,
                  valueColor: AlwaysStoppedAnimation(
                    progress.isComplete ? palette.learned : tint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          Icon(icon, color: color, size: 21),
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

/// Hiç çalışma kaydı yokken gösterilen karşılama.
///
/// Sıfırlarla dolu kutular yerine ne olacağını anlatıyor: ekran boş değil,
/// "henüz" boş.
class _EmptyStats extends StatelessWidget {
  const _EmptyStats({required this.strings});

  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.accent.withValues(alpha: 0.20),
                  palette.learned.withValues(alpha: 0.14),
                ],
              ),
            ),
            child: Icon(
              PhosphorIconsRegular.chartLineUp,
              size: 50,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            strings.statsEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTypography.largeTitle(palette.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            strings.statsEmptyBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
