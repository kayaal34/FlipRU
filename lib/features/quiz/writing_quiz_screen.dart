import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
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
/// Yazma telefonun kendi klavyesiyle: kutuların üzerinde görünmez bir metin
/// alanı duruyor, basılan harfi alıp kutulara dağıtıyor. Alan boşken de geri
/// silme tuşunun haber verebilmesi için içinde görünmez bir karakter tutuluyor.
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

  /// Metin alanında hep duran görünmez karakter.
  ///
  /// Alan tamamen boş olsaydı geri silme tuşuna basıldığında metin değişmez,
  /// bizim de haberimiz olmazdı.
  static const _sentinel = '​';

  final _random = Random();
  final _controller = TextEditingController(text: _sentinel);
  final _focus = FocusNode();

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

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
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

  /// Klavyeden gelen değişikliği harf ya da silme olarak yorumlar.
  void _onChanged(String value) {
    if (_checked) {
      _resetField();
      return;
    }
    if (value.length > _sentinel.length) {
      for (final ch in value.substring(_sentinel.length).split('')) {
        _type(ch.toLowerCase());
      }
    } else if (value.length < _sentinel.length) {
      _backspace();
    }
    _resetField();
  }

  void _resetField() {
    _controller.value = const TextEditingValue(
      text: _sentinel,
      selection: TextSelection.collapsed(offset: _sentinel.length),
    );
  }

  void _type(String letter) {
    if (_isSeparator(letter)) return;
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
    // Cevap verilince klavye kapanıyor: doğru yazılış ve "sonraki soru"
    // düğmesi klavyenin arkasında kalmasın.
    _focus.unfocus();
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
    _focus.requestFocus();
  }

  void _retryWrong() {
    setState(() {
      _questions = List.of(_wrong);
      _wrong.clear();
      _index = 0;
      _correct = 0;
      _reset();
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    // Klavye zaten aciksa "Klavyeyi ac" dugmesi yer israfi.
    final klavyeAcik = MediaQuery.viewInsetsOf(context).bottom > 0;

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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 22),
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
                          const SizedBox(height: 22),
                          Stack(
                            children: [
                              _Slots(
                                answer: _answer,
                                slots: _slots,
                                revealed: _revealed,
                                checked: _checked,
                                correct: _wasCorrect,
                              ),
                              // Telefonun kendi klavyesini açan görünmez alan;
                              // kutulara dokunmak klavyeyi açıyor.
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0,
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focus,
                                    autofocus: true,
                                    onChanged: _onChanged,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    showCursor: false,
                                    textCapitalization: TextCapitalization.none,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.deny(
                                        RegExp(r'\s'),
                                      ),
                                    ],
                                    decoration: const InputDecoration.collapsed(
                                      hintText: '',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_checked && !_wasCorrect) ...[
                            const SizedBox(height: 18),
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
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: _checked
                          ? FilledButton(
                              onPressed: _next,
                              child: Text(
                                _index + 1 >= _questions.length
                                    ? s.seeResult
                                    : s.nextQuestion,
                              ),
                            )
                          : klavyeAcik
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              onPressed: _focus.requestFocus,
                              icon: const Icon(
                                Icons.keyboard_rounded,
                                size: 19,
                              ),
                              label: Text(s.writingOpenKeyboard),
                            ),
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
/// Kelime parçaları alt alta yazılıyor. "добрый день" ya da "по-дружески" tek
/// satıra sıkıştırılınca kutular birbirine giriyor, satır ortadan kırılıyor ve
/// kelimenin nerede bittiği okunmuyordu. Hem boşluk hem tire satır ayırıyor;
/// tire, ait olduğu satırın sonunda görünüyor.
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

  /// (parçanın başladığı indeks, parça, parçadan sonraki ayraç)
  List<(int, String, String?)> get _parts {
    final out = <(int, String, String?)>[];
    var buf = StringBuffer();
    var basi = 0;
    for (var i = 0; i < answer.length; i++) {
      final ch = answer[i];
      if (ch == ' ' || ch == '-') {
        out.add((basi, buf.toString(), ch));
        buf = StringBuffer();
        basi = i + 1;
      } else {
        buf.write(ch);
      }
    }
    out.add((basi, buf.toString(), null));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final parcalar = _parts;

    // Kutu boyu en uzun parçaya göre; en uzun kayıt 20 harf.
    final enUzun = parcalar.fold<int>(
      0,
      (a, p) => p.$2.length > a ? p.$2.length : a,
    );
    final genis = enUzun > 12 ? 27.0 : 34.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (basi, parca, ayrac) in parcalar)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 6,
              children: [
                for (var k = 0; k < parca.length; k++)
                  _Slot(
                    letter: slots[basi + k],
                    width: genis,
                    revealed: revealed.contains(basi + k),
                    checked: checked,
                    correct: correct,
                  ),
                // Tire kelimenin parçası; satırın sonunda duruyor.
                if (ayrac == '-')
                  Text(
                    '-',
                    style: textTheme.titleLarge?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.letter,
    required this.width,
    required this.revealed,
    required this.checked,
    required this.correct,
  });

  final String? letter;
  final double width;
  final bool revealed;
  final bool checked;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: width,
      height: width * 1.25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked
            ? (correct ? palette.learnedSoft : palette.reviewSoft)
            : (revealed ? palette.accentSoft : palette.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: checked
              ? (correct ? palette.learned : palette.review)
              : (letter != null ? palette.accent : palette.separator),
        ),
      ),
      child: Text(
        letter ?? '',
        style: textTheme.titleLarge?.copyWith(
          fontSize: width > 30 ? 20 : 16,
          color: checked
              ? (correct ? palette.learned : palette.review)
              : palette.textPrimary,
        ),
      ),
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
