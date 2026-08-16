import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// Çözülen bir testin sonucu.
@immutable
class QuizResult {
  const QuizResult({
    required this.correct,
    required this.total,
    required this.at,
  });

  final int correct;
  final int total;
  final DateTime at;

  double get ratio => total == 0 ? 0 : correct / total;

  Map<String, Object> toMap() => {
        'c': correct,
        't': total,
        'at': at.toIso8601String(),
      };

  factory QuizResult.fromMap(Map<String, Object?> map) => QuizResult(
        correct: map['c'] as int? ?? 0,
        total: map['t'] as int? ?? 0,
        at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime(2026),
      );
}

/// Çözülen testlerin geçmişi.
///
/// Yalnızca son 100 test tutuluyor; istatistik için fazlası gerekmiyor ve
/// tercih dosyası şişmiyor.
class QuizStatsNotifier extends Notifier<List<QuizResult>> {
  static const _key = 'quiz_results';
  static const _keep = 100;

  @override
  List<QuizResult> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    final decoded = json.decode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        QuizResult.fromMap(
          (item as Map<String, dynamic>).cast<String, Object?>(),
        ),
    ];
  }

  void record(int correct, int total) {
    if (total == 0) return;
    final next = [
      ...state,
      QuizResult(correct: correct, total: total, at: DateTime.now()),
    ];
    _persist(next.length > _keep ? next.sublist(next.length - _keep) : next);
  }

  void clear() => _persist(const []);

  void _persist(List<QuizResult> value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(
          _key,
          json.encode([for (final r in value) r.toMap()]),
        );
  }
}

final quizStatsProvider =
    NotifierProvider<QuizStatsNotifier, List<QuizResult>>(
  QuizStatsNotifier.new,
);

@immutable
class QuizSummary {
  const QuizSummary({
    required this.count,
    required this.correct,
    required this.answered,
    required this.bestRatio,
    required this.lastRatio,
  });

  final int count;
  final int correct;
  final int answered;
  final double bestRatio;
  final double lastRatio;

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

final quizSummaryProvider = Provider<QuizSummary>((ref) {
  final results = ref.watch(quizStatsProvider);
  if (results.isEmpty) {
    return const QuizSummary(
      count: 0,
      correct: 0,
      answered: 0,
      bestRatio: 0,
      lastRatio: 0,
    );
  }

  var correct = 0;
  var answered = 0;
  var best = 0.0;
  for (final result in results) {
    correct += result.correct;
    answered += result.total;
    if (result.ratio > best) best = result.ratio;
  }

  return QuizSummary(
    count: results.length,
    correct: correct,
    answered: answered,
    bestRatio: best,
    lastRatio: results.last.ratio,
  );
});
