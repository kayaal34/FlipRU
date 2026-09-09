import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/alphabet_letter.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_provider.dart';

/// Bir harf grubunun dersi: önce harfler tek tek, sonra kısa bir sınav.
///
/// Izgara hâlindeki tablo öğretmiyordu; burada harfler azar azar geliyor ve
/// grubun sonunda hemen ölçülüyor. Sınav geçilince ders tamamlanmış sayılır.
class AlphabetLessonScreen extends ConsumerStatefulWidget {
  const AlphabetLessonScreen({
    required this.groupKey,
    required this.title,
    required this.letters,
    required this.ttsLanguage,
    super.key,
  });

  final String groupKey;
  final String title;
  final List<AlphabetLetter> letters;
  final String ttsLanguage;

  @override
  ConsumerState<AlphabetLessonScreen> createState() =>
      _AlphabetLessonScreenState();
}

class _AlphabetLessonScreenState extends ConsumerState<AlphabetLessonScreen> {
  /// Önce tanıtım kartları, sonra sınav.
  bool _quizPhase = false;
  int _index = 0;

  late final List<AlphabetLetter> _questions = _buildQuestions();
  String? _picked;

  List<AlphabetLetter> _buildQuestions() {
    // Kısa gruplarda her harf sorulur, uzun gruplarda sekiz soru yeter.
    final pool = [...widget.letters]..shuffle();
    return pool.take(math.min(8, pool.length)).toList();
  }

  void _speak(String text) {
    ref.read(speechServiceProvider).speak(text, language: widget.ttsLanguage);
  }

  void _next() {
    Haptics.light();
    if (_index + 1 < widget.letters.length) {
      setState(() => _index++);
      return;
    }
    setState(() {
      _quizPhase = true;
      _index = 0;
    });
  }

  /// Doğru şıkkın yanına aynı gruptan üç çeldirici.
  List<String> _optionsFor(AlphabetLetter letter) {
    final others = [
      for (final l in widget.letters)
        if (l.sound != letter.sound) l.sound,
    ]..shuffle(math.Random(letter.upper.codeUnitAt(0)));
    return [letter.sound, ...others.take(3)]
      ..shuffle(math.Random(letter.upper.codeUnitAt(0) * 7));
  }

  void _answer(AlphabetLetter question, String option) {
    if (_picked != null) return;
    Haptics.medium();
    setState(() => _picked = option);
  }

  void _advanceQuiz() {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _picked = null;
      });
      return;
    }
    // Dersi tamamlanmış say ve listeye dön.
    ref
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(alphabetDone: {...s.alphabetDone, widget.groupKey}),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _quizPhase ? _buildQuiz(s) : _buildLearn(s),
          ),
        ),
      ),
    );
  }

  Widget _buildLearn(Strings s) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final letter = widget.letters[_index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          _StepBar(value: (_index + 1) / widget.letters.length),
          const Spacer(),
          Text(
            letter.pair,
            style: AppTypography.hero(
              palette.textPrimary,
            ).copyWith(fontSize: 92),
          ),
          const SizedBox(height: 10),
          Text(
            '${s.alphabetSound}: ${letter.sound}',
            style: textTheme.titleMedium?.copyWith(color: palette.accent),
          ),
          if (letter.note != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surfaceSunken,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                letter.note!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Pressable(
            onTap: () {
              Haptics.selection();
              _speak(letter.example);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.separator),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsRegular.speakerHigh,
                    size: 20,
                    color: palette.accent,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(letter.example, style: textTheme.titleMedium),
                      Text(
                        letter.meaning,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: _next,
            child: Text(
              _index + 1 < widget.letters.length
                  ? s.onboardNext
                  : s.alphabetToQuiz,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(Strings s) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final question = _questions[_index];
    final options = _optionsFor(question);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          _StepBar(value: (_index + 1) / _questions.length),
          const SizedBox(height: 26),
          Text(
            s.alphabetQuizPrompt,
            style: textTheme.bodyMedium?.copyWith(color: palette.textTertiary),
          ),
          const SizedBox(height: 18),
          Text(
            question.pair,
            style: AppTypography.hero(
              palette.textPrimary,
            ).copyWith(fontSize: 76),
          ),
          const SizedBox(height: 30),
          for (final option in options) ...[
            _QuizOption(
              label: option,
              state: _picked == null
                  ? _OptionState.idle
                  : option == question.sound
                  ? _OptionState.correct
                  : option == _picked
                  ? _OptionState.wrong
                  : _OptionState.idle,
              onTap: () => _answer(question, option),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          if (_picked != null)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: _advanceQuiz,
              child: Text(
                _index + 1 < _questions.length ? s.nextQuestion : s.finish,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        backgroundColor: palette.track,
        valueColor: AlwaysStoppedAnimation(palette.accent),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _QuizOption extends StatelessWidget {
  const _QuizOption({
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

    final (border, background) = switch (state) {
      _OptionState.correct => (
        palette.learned,
        palette.learned.withValues(alpha: 0.14),
      ),
      _OptionState.wrong => (
        palette.review,
        palette.review.withValues(alpha: 0.14),
      ),
      _OptionState.idle => (palette.separator, palette.surface),
    };

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(color: palette.textPrimary),
        ),
      ),
    );
  }
}
