import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'settings_provider.dart';

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Gün gün öğrenilen kelime sayısı.
///
/// Yalnızca son 120 gün saklanıyor; seri hesabı için fazlası gerekmiyor ve
/// tercih dosyası şişmiyor.
class DailyProgressNotifier extends Notifier<Map<String, int>> {
  static const _key = 'daily_progress';
  static const _keepDays = 120;

  @override
  Map<String, int> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries) entry.key: entry.value as int,
    };
  }

  /// Bir kelime ilk kez "öğrendim" işaretlendiğinde çağrılır.
  void record({int delta = 1}) {
    final key = _dayKey(DateTime.now());
    final next = {...state, key: (state[key] ?? 0) + delta};
    if (next[key]! < 0) next[key] = 0;
    _persist(next);
  }

  void clear() => _persist(const {});

  void _persist(Map<String, int> value) {
    final cutoff = DateTime.now().subtract(const Duration(days: _keepDays));
    final pruned = {
      for (final entry in value.entries)
        if (DateTime.tryParse(entry.key)?.isAfter(cutoff) ?? false)
          entry.key: entry.value,
    };
    state = pruned;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, json.encode(pruned));
  }
}

final dailyProgressProvider =
    NotifierProvider<DailyProgressNotifier, Map<String, int>>(
  DailyProgressNotifier.new,
);

/// Uygulamanın açıldığı günler. Seri (streak) buradan hesaplanıyor:
/// kullanıcı bir gün hiç girmezse seri sıfırlanır.
class VisitNotifier extends Notifier<Set<String>> {
  static const _key = 'visit_days';
  static const _keepDays = 400;

  @override
  Set<String> build() {
    final stored = ref.read(sharedPreferencesProvider).getStringList(_key);
    return {...?stored};
  }

  /// Uygulama her açıldığında çağrılır.
  void recordToday() {
    final key = _dayKey(DateTime.now());
    if (state.contains(key)) return;

    final cutoff = DateTime.now().subtract(const Duration(days: _keepDays));
    final next = {
      for (final day in {...state, key})
        if (DateTime.tryParse(day)?.isAfter(cutoff) ?? false) day,
    };
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next.toList());
  }

  void clear() {
    state = const {};
    ref.read(sharedPreferencesProvider).setStringList(_key, const []);
  }
}

final visitProvider =
    NotifierProvider<VisitNotifier, Set<String>>(VisitNotifier.new);

/// Kesintisiz giriş serisi.
final streakProvider = Provider<int>((ref) {
  final visits = ref.watch(visitProvider);
  if (visits.isEmpty) return 0;

  var streak = 0;
  var cursor = DateTime.now();
  // Bugün henüz girilmemişse dünden saymaya başla; gün bitmeden seri bozulmaz.
  if (!visits.contains(_dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  while (visits.contains(_dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
});

/// İstatistik ekranı için haftalık / aylık toplamlar.
@immutable
class LearningStats {
  const LearningStats({
    required this.last7,
    required this.last30,
    required this.thisWeek,
    required this.thisMonth,
    required this.bestDay,
    required this.activeDays,
  });

  /// Son 7 ve 30 günün gün gün sayıları (en eski → en yeni).
  final List<int> last7;
  final List<int> last30;

  final int thisWeek;
  final int thisMonth;
  final int bestDay;
  final int activeDays;
}

final learningStatsProvider = Provider<LearningStats>((ref) {
  final history = ref.watch(dailyProgressProvider);
  final now = DateTime.now();

  List<int> window(int days) => [
        for (var i = days - 1; i >= 0; i--)
          history[_dayKey(now.subtract(Duration(days: i)))] ?? 0,
      ];

  final week = window(7);
  final month = window(30);

  return LearningStats(
    last7: week,
    last30: month,
    thisWeek: week.fold(0, (a, b) => a + b),
    thisMonth: month.fold(0, (a, b) => a + b),
    bestDay: history.values.fold(0, (a, b) => b > a ? b : a),
    activeDays: history.values.where((v) => v > 0).length,
  );
});

@immutable
class DailySummary {
  const DailySummary({
    required this.today,
    required this.goal,
    required this.streak,
  });

  final int today;
  final int goal;

  /// Hedefin tutturulduğu ardışık gün sayısı.
  final int streak;

  double get ratio => goal == 0 ? 0 : (today / goal).clamp(0.0, 1.0);
  bool get goalReached => today >= goal;
  int get remaining => (goal - today).clamp(0, goal);
}

final dailySummaryProvider = Provider<DailySummary>((ref) {
  final history = ref.watch(dailyProgressProvider);
  final goal = ref.watch(settingsProvider.select((s) => s.dailyGoal));
  final now = DateTime.now();
  final today = history[_dayKey(now)] ?? 0;

  // Bugün hedefe ulaşılmadıysa seri henüz bozulmuş sayılmaz; gün bitene kadar
  // dünden geriye doğru sayıyoruz.
  var streak = 0;
  var cursor = today >= goal ? now : now.subtract(const Duration(days: 1));
  while (true) {
    final count = history[_dayKey(cursor)] ?? 0;
    if (count < goal || goal == 0) break;
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return DailySummary(today: today, goal: goal, streak: streak);
});
