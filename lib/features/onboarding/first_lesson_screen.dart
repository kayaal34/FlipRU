import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../../providers/settings_provider.dart';
import '../alphabet/alphabet_screen.dart';
import '../quiz/quiz_screen.dart';
import '../shell/app_shell.dart';
import '../study/widgets/flashcard.dart';
import '../study/widgets/study_action_bar.dart';

/// Tanıtımın ardından el ele yapılan ilk ders.
///
/// Tanıtım uygulamayı anlatıyordu ama ilk dakikada hiçbir şey öğretmiyordu.
/// Burada kullanıcı üç kelimeyi gerçek kartlarla çalışıyor ve her adımda
/// ne yapacağı söyleniyor: dokun, sağa kaydır, sola kaydır. Ardından aynı üç
/// kelimeden kısa bir test geliyor. Ana ekrana, öğrenilmiş kelimeleri ve
/// başlamış bir seriyle varıyor.
///
/// Yanlış yöne kaydırmak ya da karta bakmadan geçmek iptal ediliyor ve
/// banner doğru hareketi söylüyor. Her an "Atla" ile ana ekrana geçilebilir.
class FirstLessonScreen extends ConsumerStatefulWidget {
  const FirstLessonScreen({this.openAlphabetAfter = false, super.key});

  /// Tanıtımda "alfabeyle başla" seçildiyse ders bitince alfabe açılır.
  final bool openAlphabetAfter;

  @override
  ConsumerState<FirstLessonScreen> createState() => _FirstLessonScreenState();
}

enum _Phase { cards, quizIntro, done }

class _FirstLessonScreenState extends ConsumerState<FirstLessonScreen> {
  /// привет, спасибо, дом: tanıdık, kısa ve farklı türden üç kelime.
  static const _ids = ['w00000', 'w00002', 'w00026'];

  final _swiper = CardSwiperController();
  late final List<Word> _words = _pickWords();
  late final AppSettings _settings = ref.read(settingsProvider);

  _Phase _phase = _Phase.cards;

  /// 0: karta dokun, 1: sağa kaydır, 2: sola kaydır, 3: serbest.
  int _step = 0;
  bool _flipped = false;
  int _top = 0;

  /// Yanlış hamlede kısa süre gösterilen uyarı.
  String? _nudge;

  List<Word> _pickWords() {
    final all = ref.read(wordRepositoryProvider).allWords;
    final byId = {for (final w in all) w.id: w};
    final picked = [
      for (final id in _ids)
        if (byId[id] != null) byId[id]!,
    ];
    if (picked.length == _ids.length) return picked;
    // Veri değişip kimlikler kaydıysa ilk A1 kelimelerine düş.
    return all.where((w) => w.level == WordLevel.a1).take(3).toList();
  }

  @override
  void dispose() {
    _swiper.dispose();
    super.dispose();
  }

  void _showNudge(String text) {
    Haptics.heavy();
    setState(() => _nudge = text);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _nudge == text) setState(() => _nudge = null);
    });
  }

  void _flip() {
    Haptics.light();
    setState(() {
      _flipped = !_flipped;
      _nudge = null;
      if (_step == 0 && _flipped) _step = 1;
    });
  }

  /// Bu adımda hangi yöne kaydırılabilir.
  ///
  /// Kart kütüphanesi `onSwipe` false dönünce kartı önce ekrandan uçurup
  /// sonra geri zıplatıyor; bu sert duruyordu. Onun yerine yanlış yön en
  /// baştan kapalı: yanlış yöne çekilen kart yumuşakça yerine dönüyor ve
  /// [_onPointerUp] uyarıyı gösteriyor.
  ///
  /// Kütüphane izin verilen yönü yalnızca ilk kurulumda okuyor. Bu yüzden
  /// kaydırıcı [_swiperKey] değişince yeniden kuruluyor; anahtar yalnızca
  /// bir kart uçup gittikten sonra değiştiği için görsel bir sıçrama yok.
  /// "Önce karta dokun" adımı ise kütüphanenin her an okuduğu `isDisabled`
  /// ile kilitleniyor; kart o adımda da aynı kaydırıcıda kalıyor ki
  /// çevirme animasyonu kesilmesin.
  AllowedSwipeDirection get _allowed => switch (_step) {
    0 || 1 => const AllowedSwipeDirection.only(right: true),
    2 => const AllowedSwipeDirection.only(left: true),
    _ => const AllowedSwipeDirection.symmetric(horizontal: true),
  };

  String get _swiperKey => switch (_step) {
    0 || 1 => 'right',
    2 => 'left',
    _ => 'both',
  };

  /// Adım bu yöne izin vermiyorsa ne yapılması gerektiğini söyler.
  String? _wrongMoveHint(bool right) {
    final s = ref.read(stringsProvider);
    return switch (_step) {
      0 => s.tutFlipFirst,
      1 when !right => s.tutWrongRight,
      2 when right => s.tutWrongLeft,
      _ => null,
    };
  }

  double? _dragStartX;

  void _onPointerUp(PointerUpEvent event) {
    final start = _dragStartX;
    _dragStartX = null;
    if (start == null) return;
    final dx = event.position.dx - start;
    // Kısa dokunuşlar kart çevirme; yalnızca belirgin kaydırmalara bak.
    if (dx.abs() < 60) return;
    final hint = _wrongMoveHint(dx > 0);
    if (hint != null) _showNudge(hint);
  }

  /// Alttaki düğmeler de aynı kurala uysun.
  void _buttonSwipe(CardSwiperDirection direction) {
    final hint = _wrongMoveHint(direction == CardSwiperDirection.right);
    if (hint != null) {
      _showNudge(hint);
      return;
    }
    _swiper.swipe(direction);
  }

  bool _onSwipe(int previous, int? current, CardSwiperDirection direction) {
    final right = direction == CardSwiperDirection.right;
    final learned = ref.read(learnedProvider.notifier);
    final word = _words[previous];
    right ? learned.markLearned(word.id) : learned.markForReview(word.id);

    Haptics.medium();
    setState(() {
      _step++;
      _flipped = false;
      _nudge = null;
      _top = current ?? previous;
    });
    return true;
  }

  Future<void> _startQuiz() async {
    Haptics.light();
    final s = ref.read(stringsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          title: s.tutQuizName,
          words: _words,
          questionCount: _words.length,
          kind: 'tutorial',
        ),
      ),
    );
    if (mounted) setState(() => _phase = _Phase.done);
  }

  void _goHome() {
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(softRoute(const AppShell()), (_) => false);
    if (widget.openAlphabetAfter) {
      navigator.push(MaterialPageRoute(builder: (_) => const AlphabetScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);

    // Geri tuşu dersi atlamak demek: tanıtım ekranı arkada yok, uygulamadan
    // çıkmak yerine ana ekrana gidilsin.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: palette.canvas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.tutTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        // Bitişte "Atla" kaybolurken yer zıplamasın diye
                        // kaldırılmıyor, soluyor.
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _phase == _Phase.done ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: _phase == _Phase.done,
                            child: TextButton(
                              onPressed: _goHome,
                              child: Text(s.tutSkip),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dersin neresinde olduğunu gösteren adım çubuğu: üç kart,
                  // test, bitiş.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _StepIndicator(
                      current: switch (_phase) {
                        _Phase.cards => _step.clamp(0, 3) < 2 ? 0 : _step - 1,
                        _Phase.quizIntro => 3,
                        _Phase.done => 4,
                      },
                      total: 5,
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 520),
                      reverseDuration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      // Aşamalar arasında solma + hafif yükselme + ölçek:
                      // sert bir kesme yerine sahne değişimi gibi.
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.97,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                      ),
                      child: switch (_phase) {
                        _Phase.cards => _buildCards(context),
                        _Phase.quizIntro => _InfoPanel(
                          key: const ValueKey('quiz'),
                          icon: PhosphorIconsRegular.exam,
                          tint: palette.accent,
                          title: s.tutQuizTitle,
                          body: s.tutQuizBody,
                          button: s.tutQuizStart,
                          onPressed: _startQuiz,
                        ),
                        _Phase.done => _InfoPanel(
                          key: const ValueKey('done'),
                          icon: PhosphorIconsFill.fire,
                          tint: palette.star,
                          badge: '${ref.watch(streakProvider)}',
                          pulse: true,
                          title: s.tutDoneTitle,
                          body: s.tutDoneBody,
                          button: s.tutDoneStart,
                          onPressed: _goHome,
                        ),
                      },
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

  Widget _buildCards(BuildContext context) {
    final s = ref.watch(stringsProvider);

    // Yönerge kartın üzerinde duruyor: hareketi gösteren el ve kısa bir
    // etiket. Üstte ayrı bir bantta yazmak kullanıcının gözünü karttan
    // kaçırıyordu.
    final (_Gesture gesture, String text) = switch (_step) {
      0 => (_Gesture.tap, s.tutTap),
      1 => (_Gesture.right, s.tutRight),
      2 => (_Gesture.left, s.tutLeft),
      _ => (_Gesture.both, s.tutFree),
    };

    return Column(
      key: const ValueKey('cards'),
      children: [
        Expanded(
          // Kartlar ekrana alttan süzülerek geliyor.
          child: _Entrance(
            delay: const Duration(milliseconds: 120),
            offset: 0.08,
            child: Listener(
              onPointerDown: (e) => _dragStartX = e.position.dx,
              onPointerUp: _onPointerUp,
              child: CardSwiper(
                key: ValueKey(_swiperKey),
                initialIndex: _top,
                isDisabled: _step == 0,
                controller: _swiper,
                cardsCount: _words.length,
                numberOfCardsDisplayed: _words.length - _top,
                isLoop: false,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                backCardOffset: const Offset(0, 30),
                scale: 0.94,
                threshold: 80,
                maxAngle: 18,
                duration: const Duration(milliseconds: 260),
                allowedSwipeDirection: _allowed,
                onSwipe: _onSwipe,
                onEnd: () => setState(() => _phase = _Phase.quizIntro),
                cardBuilder: (context, index, horizontalOffset, _) {
                  final word = _words[index];
                  final isTop = index == _top;
                  final card = Flashcard(
                    key: ValueKey(word.id),
                    strings: s,
                    word: word,
                    isFlipped: isTop && _flipped,
                    isStarred: false,
                    reversed: _settings.direction == StudyDirection.trToRu,
                    showTransliteration: true,
                    showStressMarks: _settings.showStressMarks,
                    showTurkishTranslit: _settings.language == AppLanguage.ru,
                    dragPercent: horizontalOffset / 100,
                    onFlip: _flip,
                    onStarToggle: () {},
                    onSpeak: (text, language) => ref
                        .read(speechServiceProvider)
                        .speak(text, language: language),
                    onReport: () {},
                  );
                  if (!isTop) return card;
                  // Yönerge üstteki kartın üzerinde; kart sürüklendikçe
                  // soluyor ve kartla birlikte uçup gidiyor. Dokunuşları
                  // engellemesin diye IgnorePointer içinde.
                  final drag = (horizontalOffset.abs() / 60).clamp(0.0, 1.0);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      card,
                      Align(
                        alignment: const Alignment(0, 0.62),
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 1 - drag,
                            child: _CoachMark(
                              gesture: gesture,
                              label: _nudge ?? text,
                              warning: _nudge != null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: StudyActionBar(
            canUndo: false,
            isFlipped: _flipped,
            onUndo: () {},
            onFlip: _flip,
            onReview: () => _buttonSwipe(CardSwiperDirection.left),
            onLearned: () => _buttonSwipe(CardSwiperDirection.right),
          ),
        ),
      ],
    );
  }
}

enum _Gesture { tap, right, left, both }

/// Kartın üzerinde, yapılacak hareketi canlandıran yönerge.
///
/// Dokunma adımında atan bir halka ve el; kaydırma adımlarında gösterdiği
/// yöne süzülüp kaybolan bir el. Altında kısa bir etiket var; yanlış
/// hamlede etiket kırmızıya dönüp ne yapılacağını söylüyor.
class _CoachMark extends StatefulWidget {
  const _CoachMark({
    required this.gesture,
    required this.label,
    required this.warning,
  });

  final _Gesture gesture;
  final String label;
  final bool warning;

  @override
  State<_CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<_CoachMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final tint = widget.warning ? palette.review : palette.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 72,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _glyph(tint),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.warning ? palette.review : const Color(0xE6171722),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              widget.label,
              key: ValueKey(widget.label),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glyph(Color tint) {
    final v = _controller.value;
    switch (widget.gesture) {
      case _Gesture.tap:
        // Parmak iner (küçülür), halka dışa yayılıp söner.
        final press = v < 0.3 ? Curves.easeOut.transform(v / 0.3) : 1.0;
        final ring = v < 0.3 ? 0.0 : Curves.easeOut.transform((v - 0.3) / 0.7);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 0.6 + 0.9 * ring,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tint.withValues(alpha: 0.28 * (1 - ring)),
                ),
              ),
            ),
            Transform.scale(
              scale: 1 - 0.14 * press + 0.14 * ring,
              child: Icon(PhosphorIconsFill.handTap, size: 46, color: tint),
            ),
          ],
        );
      case _Gesture.right:
      case _Gesture.left:
        final dir = widget.gesture == _Gesture.right ? 1.0 : -1.0;
        // El merkezin gerisinden başlayıp gösterdiği yöne süzülür; sonda
        // solup başa döner. Arkasında giderek uzayan bir iz var.
        final move = Curves.easeInOut.transform(v.clamp(0.0, 0.8) / 0.8);
        final fade = v < 0.1
            ? v / 0.1
            : v > 0.8
            ? (1 - (v - 0.8) / 0.2)
            : 1.0;
        final x = dir * (-44 + 88 * move);
        return Opacity(
          opacity: fade.clamp(0.0, 1.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(dir * (-44 + 44 * move), 0),
                child: Container(
                  width: 88 * move + 1,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: dir > 0
                          ? [
                              tint.withValues(alpha: 0),
                              tint.withValues(alpha: 0.55),
                            ]
                          : [
                              tint.withValues(alpha: 0.55),
                              tint.withValues(alpha: 0),
                            ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(x, 0),
                child: Icon(
                  dir > 0
                      ? PhosphorIconsFill.handSwipeRight
                      : PhosphorIconsFill.handSwipeLeft,
                  size: 46,
                  color: tint,
                ),
              ),
            ],
          ),
        );
      case _Gesture.both:
        // İki ok sırayla iki yana esniyor: "istediğin yöne".
        final swing = Curves.easeInOut.transform(v < 0.5 ? v * 2 : (1 - v) * 2);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(-10 * swing, 0),
              child: Icon(
                PhosphorIconsBold.arrowLeft,
                size: 30,
                color: palette.review,
              ),
            ),
            const SizedBox(width: 14),
            Icon(PhosphorIconsFill.handGrabbing, size: 40, color: tint),
            const SizedBox(width: 14),
            Transform.translate(
              offset: Offset(10 * swing, 0),
              child: Icon(
                PhosphorIconsBold.arrowRight,
                size: 30,
                color: palette.learned,
              ),
            ),
          ],
        );
    }
  }

  AppPalette get palette => context.palette;
}

/// Yumuşak sayfa geçişi: yeni sayfa hafifçe büyüyerek belirir.
///
/// Varsayılan Material geçişi ilk derste ve ana ekrana dönüşte sert bir
/// kayma gibi duruyordu; burada solma + çok hafif ölçek var.
Route<T> softRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 560),
  reverseTransitionDuration: const Duration(milliseconds: 320),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
);

/// Çocuğunu [delay] sonra alttan süzülerek ve belirerek gösterir.
class _Entrance extends StatefulWidget {
  const _Entrance({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 0.12,
  });

  final Widget child;
  final Duration delay;

  /// Başlangıç kayması, çocuğun yüksekliğine oranla.
  final double offset;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0, widget.offset),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Üstteki ince adım çubuğu; geçilen adımlar dolarak ilerliyor.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: i <= current ? 1 : 0),
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: palette.track,
                  valueColor: AlwaysStoppedAnimation(
                    i == current ? palette.accent : palette.learned,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bitiş ekranındaki ikonun etrafında yavaşça atan hale.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        // Kutu sabit boyutta. Önceden halka büyüdükçe kutu da büyüyordu ve
        // alttaki başlıkla düğmeyi her atışta aşağı itip geri zıplatıyordu.
        return SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Dışa doğru büyüyüp sönen halka; yerleşimi etkilemiyor.
              Transform.scale(
                scale: 1 + 0.38 * t,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.35 * (1 - t)),
                      width: 2,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Test öncesi ve bitiş ekranı: ikon, başlık, açıklama, tek düğme.
///
/// Öğeler sırayla geliyor: önce ikon yaylanarak büyüyor, ardından başlık,
/// açıklama ve düğme kısa aralıklarla alttan süzülüyor.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
    this.badge,
    this.pulse = false,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;

  /// Bitiş ekranında ikonun altında seri sayısı.
  final String? badge;

  /// İkonun etrafında atan hale (bitiş ekranı).
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final circle = Container(
      width: 116,
      height: 116,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.22),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: badge == null ? 54 : 44, color: tint),
          if (badge != null)
            Text(
              badge!,
              style: textTheme.titleLarge?.copyWith(color: tint, height: 1.1),
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  // İkon: yaylanarak büyüyor.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    // Tek, hafif bir taşma: elasticOut birkaç kez
                    // sallanıyordu ve tedirgin duruyordu.
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: pulse ? _Pulse(color: tint, child: circle) : circle,
                  ),
                  const SizedBox(height: 30),
                  _Entrance(
                    delay: const Duration(milliseconds: 180),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.largeTitle(palette.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Entrance(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Entrance(
                delay: const Duration(milliseconds: 460),
                offset: 0.3,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: () {
                    Haptics.medium();
                    onPressed();
                  },
                  child: Text(button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
