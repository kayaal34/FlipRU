import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/premium_provider.dart';
import '../../providers/quiz_stats_provider.dart';
import '../../providers/unit_providers.dart';
import '../premium/premium_screen.dart';
import '../../providers/settings_provider.dart';

/// Çoktan seçmeli test.
///
/// Kartla çalışmak "hatırladım mı?" sorusunu kullanıcının kendisine sorduruyor;
/// test ise bunu ölçüyor. Çeldiriciler aynı seviyeden seçiliyor ki zorluk
/// gerçekçi olsun.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    required this.title,
    required this.words,
    this.accent,
    this.questionCount = 15,
    this.unitId,
    super.key,
  });

  final String title;
  final List<Word> words;
  final Color? accent;
  final int questionCount;

  /// Bölüm testiyse: bütün sorular doğru cevaplanınca bu bölüm geçilmiş
  /// sayılır ve sonraki bölümün kilidi açılır. Yanlışı olan kullanıcı
  /// "Yanlışlarına dön" ile eksiklerini kapatıp bölümü açabilir.
  final String? unitId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _random = Random();
  late final List<_Question> _questions = _build();

  int _index = 0;
  int _correct = 0;

  /// Yanlis cevaplanan kelimeler. Test sonunda "Yanlislarina don" bu listeyi
  /// yeni bir tur olarak aciyor.
  final _wrong = <Word>[];
  String? _picked;
  bool _revealed = false;

  List<_Question> _build() {
    final repository = ref.read(wordRepositoryProvider);

    // Tek/iki harfli edat ve bağlaçlar (а, в, и, с, у) çoktan seçmeli soru
    // olarak anlamsız: bağlam olmadan şıklar birbirinden ayırt edilemiyor.
    var pool = widget.words.where((w) => w.russian.length > 2).toList();
    if (pool.length < 4) pool = [...widget.words];
    pool.shuffle(_random);

    final count = min(widget.questionCount, pool.length);

    return [
      for (final word in pool.take(count))
        () {
          final distractors = repository.randomDistractors(word, 3, _random);
          final options = [word, ...distractors]..shuffle(_random);
          return _Question(word: word, options: options);
        }(),
    ];
  }

  void _pick(Word option) {
    if (_revealed) return;
    final question = _questions[_index];
    final isCorrect = option.turkish == question.word.turkish;

    isCorrect ? Haptics.medium() : Haptics.heavy();
    setState(() {
      _picked = option.turkish;
      _revealed = true;
      if (isCorrect) {
        _correct++;
      } else {
        _wrong.add(question.word);
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _finish();
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _revealed = false;
    });
  }

  void _finish() {
    // Test sonucu istatistiklere yazılıyor.
    ref.read(quizStatsProvider.notifier).record(_correct, _questions.length);

    final unitId = widget.unitId;
    if (unitId == null || _questions.isEmpty) return;
    // Tam puan sarti: bolumu gecmek icin her soruyu dogru bilmek gerekiyor.
    if (_correct == _questions.length) {
      ref.read(passedUnitsProvider.notifier).markPassed(unitId);
      _unlockedUnit = true;
    }
  }

  bool _unlockedUnit = false;

  /// İpucu: yanlış şıklardan ikisini eler. Premium özelliği.
  void _useHint() {
    if (_revealed || _hintUsed) return;
    final question = _questions[_index];
    final wrong = question.options
        .where((o) => o.turkish != question.word.turkish)
        .toList()
      ..shuffle(_random);

    Haptics.light();
    setState(() {
      _hintUsed = true;
      _eliminated = wrong.take(2).map((o) => o.turkish).toSet();
    });
  }

  bool _hintUsed = false;
  Set<String> _eliminated = const {};

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = widget.accent ?? palette.accent;
    final s = ref.watch(stringsProvider);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              s.quizNotEnough,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    if (_index >= _questions.length) {
      return _QuizResult(
        title: widget.title,
        correct: _correct,
        total: _questions.length,
        accent: tint,
        unlockedUnit: _unlockedUnit,
        strings: s,
        wrong: _wrong,
        // Yanlislari tekrar ederken de bolum kimligi tasiniyor: hepsini
        // dogru yapan kullanici bolumu acabilsin.
        onRetryWrong: _wrong.isEmpty
            ? null
            : () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      title: widget.title,
                      words: List.of(_wrong),
                      accent: widget.accent,
                      questionCount: _wrong.length,
                      unitId: widget.unitId,
                    ),
                  ),
                ),
      );
    }

    final question = _questions[_index];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_index + 1) / _questions.length,
                          minHeight: 6,
                          backgroundColor: palette.track,
                          valueColor: AlwaysStoppedAnimation(tint),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${s.quizProgress} ${_index + 1} / '
                            '${_questions.length}',
                            style: textTheme.bodySmall
                                ?.copyWith(color: palette.textTertiary),
                          ),
                          Row(
                            children: [
                              _HintButton(
                                used: _hintUsed,
                                disabled: _revealed,
                                onTap: _useHint,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$_correct ${s.quizCorrect}',
                                style: textTheme.bodySmall
                                    ?.copyWith(color: palette.learned),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          s.quizQuestion,
                          style: textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          question.word.accented,
                          textAlign: TextAlign.center,
                          style: textTheme.displayLarge?.copyWith(
                            fontSize:
                                question.word.russian.length > 13 ? 30 : 38,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question.word.transliteration,
                          style: textTheme.bodySmall
                              ?.copyWith(color: palette.textTertiary),
                        ),
                        const SizedBox(height: 28),
                        for (final option in question.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OptionTile(
                              label: option.turkish,
                              state: _stateOf(option, question),
                              onTap: () => _pick(option),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (_revealed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: tint),
                      onPressed: _next,
                      child: Text(
                        _index + 1 >= _questions.length
                            ? s.seeResult
                            : s.nextQuestion,
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

  _OptionState _stateOf(Word option, _Question question) {
    if (!_revealed) {
      return _eliminated.contains(option.turkish)
          ? _OptionState.dimmed
          : _OptionState.idle;
    }
    if (option.turkish == question.word.turkish) return _OptionState.correct;
    if (option.turkish == _picked) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

class _Question {
  const _Question({required this.word, required this.options});

  final Word word;
  final List<Word> options;
}

/// İpucu düğmesi. Premium değilse ödeme ekranına yönlendirir.
class _HintButton extends ConsumerWidget {
  const _HintButton({
    required this.used,
    required this.disabled,
    required this.onTap,
  });

  final bool used;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final premium = ref.watch(isPremiumProvider);
    final spent = used || disabled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: spent
          ? null
          : () {
              if (!premium) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
                return;
              }
              onTap();
            },
      child: Opacity(
        opacity: spent ? 0.4 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              premium ? Icons.lightbulb_rounded : Icons.lock_rounded,
              size: 16,
              color: palette.star,
            ),
            const SizedBox(width: 4),
            Text(
              ref.watch(stringsProvider).hint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: palette.star),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final (background, border, foreground, icon) = switch (state) {
      _OptionState.idle => (
          palette.surface,
          palette.separator,
          palette.textPrimary,
          null,
        ),
      _OptionState.correct => (
          palette.learnedSoft,
          palette.learned,
          palette.learned,
          Icons.check_circle_rounded,
        ),
      _OptionState.wrong => (
          palette.reviewSoft,
          palette.review,
          palette.review,
          Icons.cancel_rounded,
        ),
      _OptionState.dimmed => (
          palette.surface,
          palette.separator,
          palette.textTertiary,
          null,
        ),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: border,
            width: state == _OptionState.idle ? 1 : 1.6,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(color: foreground),
              ),
            ),
            if (icon != null) Icon(icon, size: 20, color: foreground),
          ],
        ),
      ),
    );
  }
}

class _QuizResult extends StatelessWidget {
  const _QuizResult({
    required this.title,
    required this.correct,
    required this.total,
    required this.accent,
    required this.strings,
    required this.wrong,
    this.unlockedUnit = false,
    this.onRetryWrong,
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
