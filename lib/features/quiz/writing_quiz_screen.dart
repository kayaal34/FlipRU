import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/quiz_result_view.dart';
import '../../data/models/word.dart';
import '../../providers/quiz_stats_provider.dart';
import '../../providers/unit_providers.dart';
import '../../providers/settings_provider.dart';

/// Yazma pratiği.
///
/// Çoktan seçmeli test tanımayı ölçüyor: doğru karşılık ekranda duruyor,
/// kullanıcı yalnızca seçiyor. Burada kelimeyi baştan kurmak gerekiyor —
/// Türkçe anlamı veriliyor, Rusçası harf harf yazılıyor.
///
/// Klavye uygulamanın kendi klavyesi ve tüm alfabeyi değil, yalnızca o
/// kelimenin harfleri ile birkaç çeldirici harfi gösteriyor. İki sebeple:
/// telefonda Rusça klavye kurulu olmayabilir (Android'de uygulama sistem
/// klavyesinin dilini seçemez), ve 33 harf arasından harf aramak alıştırmayı
/// yavaşlatıyor. Ölçtüğümüz şey yazma hızı değil, kelimenin yazılışı.
class WritingQuizScreen extends ConsumerStatefulWidget {
  const WritingQuizScreen({
    required this.title,
    required this.words,
    this.testId,
    super.key,
  });

  final String title;
  final List<Word> words;

  /// Yazma testinden gelindiyse testin kimliği.
  ///
  /// Tamamı doğru cevaplanınca test geçilmiş sayılıyor ve sonraki test
  /// açılıyor; bölüm testlerindeki kuralın aynısı.
  final String? testId;

  @override
  ConsumerState<WritingQuizScreen> createState() => _WritingQuizScreenState();
}

class _WritingQuizScreenState extends ConsumerState<WritingQuizScreen> {
  static const _alphabet = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';

  /// Kullanıcıdan beklenmeyen, hazır gelen karakterler.
  static bool _isSeparator(String ch) => ch == ' ' || ch == '-';

  final _random = Random();

  late List<Word> _questions = widget.words;
  int _index = 0;
  int _correct = 0;
  final _wrong = <Word>[];

  /// Kutulara yazılanlar. Ayraçlar baştan dolu.
  late List<String?> _slots;

  /// Klavyede gösterilen harfler: cevabın harfleri + çeldiriciler, karışık.
  late List<String> _keys;

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

  int get _jokerLeft => _jokerLimit - _revealed.length;

  bool get _jokerAvailable =>
      !_checked && _jokerLeft > 0 && _letterSlots.any((i) => _slots[i] == null);

  /// Harfin cevapta kaç kez geçtiği. Çeldiricilerde sıfır.
  int _needed(String letter) =>
      _answer.split('').where((ch) => ch == letter).length;

  /// Harfin kutulara kaç kez konduğu.
  ///
  /// Ayraçlar klavyede yer almadığı için burada yalnızca harfler sorulur.
  int _used(String letter) => _slots.where((s) => s == letter).length;

  /// Tuş tükendi mi: harf kullanılabileceği kadar kullanıldıysa soluyor.
  bool _spent(String letter) => _used(letter) >= max(1, _needed(letter));

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
    _keys = _buildKeys();
  }

  /// Klavye harfleri.
  ///
  /// Cevabın harfleri mutlaka var; üstüne çeldirici ekleniyor ki kelime
  /// klavyeye bakarak çözülemesin. Dörtlü satırlar hâlinde diziliyor, varsayılan
  /// üç satır (on iki tuş); harfi çok olan kelimelerde satır ekleniyor.
  List<String> _buildKeys() {
    final gerekli = <String>{
      for (final ch in _answer.split(''))
        if (!_isSeparator(ch)) ch,
    };
    final hedef = min(20, max(12, ((gerekli.length + 6) / 4).ceil() * 4));

    final havuz = _alphabet.split('')..removeWhere(gerekli.contains);
    havuz.shuffle(_random);

    final tuslar = [...gerekli, ...havuz.take(hedef - gerekli.length)];
    return tuslar..shuffle(_random);
  }

  void _type(String letter) {
    if (_checked) return;
    final bos = _letterSlots.where((i) => _slots[i] == null);
    if (bos.isEmpty) return;
    Haptics.light();
    setState(() => _slots[bos.first] = letter);
  }

  void _backspace() {
    if (_checked) return;
    final dolu = _letterSlots
        .where((i) => _slots[i] != null && !_revealed.contains(i))
        .toList();
    if (dolu.isEmpty) return;
    Haptics.light();
    setState(() => _slots[dolu.last] = null);
  }

  void _joker() {
    final kapali = _letterSlots.where((i) => _slots[i] == null).toList();
    if (kapali.isEmpty) return;
    final secilen = kapali[_random.nextInt(kapali.length)];
    Haptics.medium();
    setState(() {
      _slots[secilen] = _answer[secilen];
      _revealed.add(secilen);
    });
  }

  /// Cevabı gönderir.
  ///
  /// Son kutu dolunca kendiliğinden kontrol etmiyoruz: kullanıcı yanlış bir
  /// harfe bastığında düzeltme şansı olmadan yanlış sayılıyordu. Boş ya da
  /// eksik gönderilirse yanlış kabul edilip doğrusu gösteriliyor.
  void _submit() {
    if (_checked) return;
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
      ref
          .read(quizStatsProvider.notifier)
          .record(_correct, _questions.length, kind: 'writing');
      final testId = widget.testId;
      if (testId != null && _correct == _questions.length) {
        ref.read(passedUnitsProvider.notifier).markPassed(testId);
        _unlockedTest = true;
      }
      setState(() => _index = _questions.length);
      return;
    }
    setState(() {
      _index++;
      _reset();
    });
  }

  bool _unlockedTest = false;

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
        unlockedUnit: _unlockedTest,
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
            constraints: const BoxConstraints(maxWidth: 480),
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
                      Text(
                        '$_correct ${s.quizCorrect}',
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.learned,
                        ),
                      ),
                    ],
                  ),
                  // Kelime yukarida, kutular ondan belirgin bir bosluk sonra:
                  // ikisi bitisik durunca soru ile cevap alani ayrisamiyordu.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 18),
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
                          const SizedBox(height: 46),
                          _Slots(
                            answer: _answer,
                            slots: _slots,
                            revealed: _revealed,
                            checked: _checked,
                            correct: _wasCorrect,
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
                          const SizedBox(height: 16),
                        ],
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
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _Keyboard(
                        keys: _keys,
                        needed: _needed,
                        spent: _spent,
                        onLetter: _type,
                        onBackspace: _backspace,
                        onSubmit: _submit,
                        onJoker: _jokerAvailable ? _joker : null,
                        jokerLeft: _jokerLeft,
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

    // Kutu boyu en uzun parçanın ekrana sığmasına göre.
    //
    // Sabit genişlikteyken 13 harfli bir kelimede son kutu tek başına alt
    // satıra düşüyordu; artık satır daralıyor, kelime tek satırda kalıyor.
    final enUzun = parcalar.fold<int>(
      0,
      (a, p) => p.$2.length > a ? p.$2.length : a,
    );
    final alan = MediaQuery.sizeOf(context).width - 40;
    final genis = ((alan - (enUzun - 1) * 5) / enUzun).clamp(20.0, 34.0);

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

/// Kelimeye özel klavye: dörtlü satırlar, altta üç eşit kontrol tuşu.
class _Keyboard extends StatelessWidget {
  const _Keyboard({
    required this.keys,
    required this.needed,
    required this.spent,
    required this.onLetter,
    required this.onBackspace,
    required this.onSubmit,
    required this.onJoker,
    required this.jokerLeft,
  });

  static const _columns = 4;

  final List<String> keys;
  final int Function(String) needed;
  final bool Function(String) spent;
  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback? onJoker;
  final int jokerLeft;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var satir = 0; satir * _columns < keys.length; satir++)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                for (var s = 0; s < _columns; s++)
                  Expanded(
                    child: satir * _columns + s < keys.length
                        ? Builder(
                            builder: (_) {
                              final harf = keys[satir * _columns + s];
                              final kac = needed(harf);
                              return _Key(
                                label: harf,
                                // "x2": harf iki kez gerekiyorsa bir kez
                                // yazip gectigini sanmasin.
                                badge: kac >= 2 ? '×$kac' : null,
                                dim: spent(harf),
                                height: 48,
                                onTap: () => onLetter(harf),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        // Harf takimi ile kontrol tuslari arasinda belirgin bir bosluk:
        // ayni blok gibi gorununce yanlislikla gonder tusuna basiliyordu.
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _Key(
                icon: Icons.backspace_outlined,
                tint: palette.review,
                onTap: onBackspace,
              ),
            ),
            Expanded(
              child: _Key(
                icon: Icons.lightbulb_rounded,
                tint: palette.star,
                badge: '$jokerLeft',
                onTap: onJoker,
              ),
            ),
            Expanded(
              child: _Key(
                icon: Icons.check_rounded,
                tint: palette.learned,
                onTap: onSubmit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.onTap,
    this.label,
    this.icon,
    this.tint,
    this.badge,
    this.dim = false,
    this.height = 52,
  });

  final String? label;
  final IconData? icon;
  final Color? tint;
  final String? badge;
  final bool dim;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final aktif = onTap != null;
    final renk = tint ?? palette.textPrimary;

    return Opacity(
      opacity: aktif ? (dim ? 0.32 : 1) : 0.35,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint == null
                ? palette.surface
                : renk.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: tint == null
                  ? palette.separator
                  : renk.withValues(alpha: 0.45),
            ),
          ),
          child: icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 21, color: renk),
                    if (badge != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        badge!,
                        style: textTheme.labelLarge?.copyWith(color: renk),
                      ),
                    ],
                  ],
                )
              // Harf ve "×2" yan yana. Once kose yazisiydi ama tuslar
              // kuculunce harfin uzerine biniyor, okunmuyordu.
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label!,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 21,
                        color: renk,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 3),
                      Text(
                        badge!,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
