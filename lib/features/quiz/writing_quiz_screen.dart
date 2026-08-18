import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/cyrillic_keyboard.dart';
import '../../core/widgets/quiz_result_view.dart';
import '../../data/models/word.dart';
import '../../providers/quiz_stats_provider.dart';
import '../../providers/settings_provider.dart';

/// Yazma pratiği.
///
/// Çoktan seçmeli test tanımayı ölçüyor: doğru karşılık ekranda duruyor,
/// kullanıcı yalnızca seçiyor. Burada kelimeyi baştan kurmak gerekiyor —
/// Türkçe anlamı veriliyor, Rusçası harf harf yazılıyor. Yazılışı
/// hatırlamadan yapılamaz.
///
/// Boşluk ve tire kutulara hazır geliyor; kullanıcı yalnızca harfleri yazıyor.
class WritingQuizScreen extends ConsumerStatefulWidget {
  const WritingQuizScreen({
    required this.title,
    required this.words,
    super.key,
  });

  final String title;
  final List<Word> words;

  @override
  ConsumerState<WritingQuizScreen> createState() => _WritingQuizScreenState();
}

class _WritingQuizScreenState extends ConsumerState<WritingQuizScreen> {
  /// Kullanıcıdan beklenmeyen, hazır gelen karakterler.
  static bool _isSeparator(String ch) => ch == ' ' || ch == '-';

  final _random = Random();

  late List<Word> _questions = widget.words;
  int _index = 0;
  int _correct = 0;
  final _wrong = <Word>[];

  /// Kutulara yazılanlar. Ayraçlar baştan dolu.
  late List<String?> _slots;

  /// Joker'in açtığı kutular; geri silme bunlara dokunmuyor.
  var _revealed = <int>{};

  bool _checked = false;
  bool _wasCorrect = false;

  Word get _word => _questions[_index];
  String get _answer => _word.russian.toLowerCase();

  /// Harf beklenen kutuların sırası.
  List<int> get _letterSlots => [
    for (var i = 0; i < _answer.length; i++)
      if (!_isSeparator(_answer[i])) i,
  ];

  /// Joker en fazla harflerin yarısını açabilir; yoksa kelimeyi o çözer.
  int get _jokerLimit => max(1, _letterSlots.length ~/ 2);

  bool get _jokerAvailable =>
      !_checked &&
      _revealed.length < _jokerLimit &&
      _letterSlots.any((i) => _slots[i] == null);

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _slots = [
      for (var i = 0; i < _answer.length; i++)
        if (_isSeparator(_answer[i])) _answer[i] else null,
    ];
    _revealed = {};
    _checked = false;
    _wasCorrect = false;
  }

  void _type(String letter) {
    final bos = _letterSlots.where((i) => _slots[i] == null);
    if (bos.isEmpty) return;
    setState(() => _slots[bos.first] = letter);
    // Son kutu dolunca kendiliğinden kontrol ediliyor; ayrıca bir "kontrol et"
    // düğmesine bastırmak alıştırmayı yavaşlatıyordu.
    if (_letterSlots.every((i) => _slots[i] != null)) _check();
  }

  void _backspace() {
    final dolu = _letterSlots
        .where((i) => _slots[i] != null && !_revealed.contains(i))
        .toList();
    if (dolu.isEmpty) return;
    setState(() => _slots[dolu.last] = null);
  }

  void _joker() {
    final kapali = _letterSlots.where((i) => _slots[i] == null).toList();
    if (kapali.isEmpty) return;
    final secilen = kapali[_random.nextInt(kapali.length)];
    Haptics.light();
    setState(() {
      _slots[secilen] = _answer[secilen];
      _revealed.add(secilen);
    });
    if (_letterSlots.every((i) => _slots[i] != null)) _check();
  }

  void _check() {
    final dogru = _slots.map((s) => s ?? '').join() == _answer;
    if (dogru) {
      Haptics.medium();
      _correct++;
    } else {
      Haptics.heavy();
      _wrong.add(_word);
    }
    setState(() {
      _checked = true;
      _wasCorrect = dogru;
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      ref.read(quizStatsProvider.notifier).record(_correct, _questions.length);
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _reset();
    });
  }

  void _retryWrong() {
    setState(() {
      _questions = List.of(_wrong);
      _wrong.clear();
      _index = 0;
      _correct = 0;
      _reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    if (_questions.isEmpty || _index >= _questions.length) {
      return QuizResultView(
        title: widget.title,
        correct: _correct,
        total: _questions.length,
        accent: palette.accent,
        strings: s,
        wrong: _wrong,
        onRetryWrong: _wrong.isEmpty ? null : _retryWrong,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_index + 1) / _questions.length,
                    minHeight: 5,
                    backgroundColor: palette.track,
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${s.quizProgress} ${_index + 1} / '
                        '${_questions.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      _JokerChip(
                        label: s.joker,
                        enabled: _jokerAvailable,
                        onTap: _joker,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '$_correct ${s.quizCorrect}',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.learned,
                        ),
                      ),
                    ],
                  ),
                  // Soru blogu bos alanin ortasinda duruyor; tepeye
                  // yaslandiginda kutularla klavye arasi bos kaliyordu.
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              s.writingPrompt,
                              style: textTheme.bodyMedium?.copyWith(
                                color: palette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _word.turkish,
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.letters(_letterSlots.length),
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _Slots(
                              answer: _answer,
                              slots: _slots,
                              revealed: _revealed,
                              checked: _checked,
                              correct: _wasCorrect,
                            ),
                            if (_checked && !_wasCorrect) ...[
                              const SizedBox(height: 16),
                              Text(
                                _word.accented.isEmpty
                                    ? _word.russian
                                    : _word.accented,
                                style: textTheme.titleLarge?.copyWith(
                                  color: palette.learned,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _word.transliteration,
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_checked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          child: Text(
                            _index + 1 >= _questions.length
                                ? s.seeResult
                                : s.nextQuestion,
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CyrillicKeyboard(
                        onLetter: _type,
                        onBackspace: _backspace,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Harf kutuları.
///
/// Kutu sayısı kelimenin kaç harfli olduğunu zaten gösteriyor; üstteki sayı
/// bakmadan saymak zorunda kalmasın diye var.
class _Slots extends StatelessWidget {
  const _Slots({
    required this.answer,
    required this.slots,
    required this.revealed,
    required this.checked,
    required this.correct,
  });

  final String answer;
  final List<String?> slots;
  final Set<int> revealed;
  final bool checked;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    // Uzun kelimelerde kutular küçülüyor; en uzun kayıt 20 harf.
    final genis = answer.length > 12 ? 26.0 : 34.0;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 6,
      children: [
        for (var i = 0; i < answer.length; i++)
          if (answer[i] == ' ')
            SizedBox(width: genis * 0.5, height: genis * 1.25)
          else
            Container(
              width: genis,
              height: genis * 1.25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked
                    ? (correct ? palette.learnedSoft : palette.reviewSoft)
                    : (revealed.contains(i)
                          ? palette.accentSoft
                          : palette.surface),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: checked
                      ? (correct ? palette.learned : palette.review)
                      : (slots[i] != null ? palette.accent : palette.separator),
                ),
              ),
              child: Text(
                slots[i] ?? '',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: genis > 30 ? 20 : 16,
                  color: checked
                      ? (correct ? palette.learned : palette.review)
                      : palette.textPrimary,
                ),
              ),
            ),
      ],
    );
  }
}

/// Joker: rastgele bir harfi açar.
class _JokerChip extends StatelessWidget {
  const _JokerChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_rounded, size: 16, color: palette.star),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.star),
            ),
          ],
        ),
      ),
    );
  }
}
