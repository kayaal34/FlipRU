import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/app_settings.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/settings_provider.dart';
import 'session_summary_screen.dart';
import 'widgets/flashcard.dart';
import 'widgets/report_sheet.dart';
import 'widgets/study_action_bar.dart';

/// Tek bir çalışma seansı.
///
/// Kelime listesi dışarıdan verilir ve seans boyunca sabit kalır (anlık
/// görüntü). Böylece kullanıcı çalışırken yıldız değiştirse bile deste
/// altından kaymaz.
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({
    required this.title,
    required this.words,
    this.accent,
    super.key,
  });

  final String title;
  final List<Word> words;
  final Color? accent;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  late final AppSettings _settings = ref.read(settingsProvider);
  late final List<Word> _words = _prepareDeck();

  /// Karışık yönde her kartın hangi yüzle başlayacağı; seans boyunca sabit
  /// kalması gerekiyor, yoksa kart her yeniden çizimde yön değiştirir.
  late final List<bool> _reversedFlags = _prepareDirections();

  /// Verilen kararların sırası; "geri al" bu yığından okur.
  final List<_SwipeRecord> _history = [];

  int _topIndex = 0;
  bool _isFlipped = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSpeak());
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  /// Ayarlara göre seansın kartlarını hazırlar.
  List<Word> _prepareDeck() {
    final learned = ref.read(learnedProvider);
    var list = [...widget.words];

    if (_settings.hideLearned) {
      final remaining =
          list.where((word) => !learned.contains(word.id)).toList();
      // Deste tamamen öğrenilmişse boş ekran yerine tekrar çalıştır.
      if (remaining.isNotEmpty) list = remaining;
    }
    if (_settings.shuffle) list.shuffle();

    final size = _settings.sessionSize;
    if (size > 0 && list.length > size) {
      list = list.sublist(0, size);
    }
    return list;
  }

  List<bool> _prepareDirections() {
    return [
      for (var i = 0; i < _words.length; i++)
        switch (_settings.direction) {
          StudyDirection.ruToTr => false,
          StudyDirection.trToRu => true,
        },
    ];
  }

  void _maybeAutoSpeak() {
    if (!_settings.autoSpeak || _topIndex >= _words.length) return;
    // Türkçe yüzle başlayan kartta Rusçayı okumak cevabı vermek olur.
    if (_reversedFlags[_topIndex]) return;
    _speak(_words[_topIndex].russian);
  }

  int get _learnedCount => _history.where((r) => r.learned).length;
  int get _reviewCount => _history.length - _learnedCount;

  void _speak(String text) =>
      ref.read(speechServiceProvider).speak(text);

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection d) {
    final word = _words[previousIndex];
    final learned = d == CardSwiperDirection.right;
    final wasLearned = ref.read(learnedProvider).contains(word.id);

    final learnedNotifier = ref.read(learnedProvider.notifier);
    learned
        ? learnedNotifier.markLearned(word.id)
        : learnedNotifier.markForReview(word.id);

    Haptics.medium();
    setState(() {
      _history.add(
        _SwipeRecord(word: word, learned: learned, wasLearned: wasLearned),
      );
      _isFlipped = false;
      _topIndex = currentIndex ?? previousIndex;
    });
    _maybeAutoSpeak();
    return true;
  }

  bool _onUndo(int? previousIndex, int currentIndex, CardSwiperDirection d) {
    if (_history.isEmpty) return false;

    // Kalıcı ilerlemeyi kararın öncesindeki hâline geri sar.
    final record = _history.removeLast();
    final learnedNotifier = ref.read(learnedProvider.notifier);
    record.wasLearned
        ? learnedNotifier.markLearned(record.word.id)
        : learnedNotifier.markForReview(record.word.id);

    Haptics.selection();
    setState(() {
      _isFlipped = false;
      _topIndex = currentIndex;
    });
    return true;
  }

  Future<void> _finish() async {
    if (_isFinishing || !mounted) return;
    _isFinishing = true;
    Haptics.heavy();

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionSummaryScreen(
          deckTitle: widget.title,
          accent: widget.accent,
          learnedWords: [
            for (final r in _history)
              if (r.learned) r.word,
          ],
          reviewWords: [
            for (final r in _history)
              if (!r.learned) r.word,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: _EmptyDeckState(
          palette: palette,
          strings: ref.watch(stringsProvider),
        ),
      );
    }

    final starred = ref.watch(starredProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _StudyHeader(
                  title: widget.title,
                  current: math.min(_history.length + 1, _words.length),
                  total: _words.length,
                  strings: ref.watch(stringsProvider),
                  learned: _learnedCount,
                  review: _reviewCount,
                  progress: _history.length / _words.length,
                  accent: widget.accent ?? palette.accent,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _words.length,
                    numberOfCardsDisplayed: math.min(3, _words.length),
                    isLoop: false,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    backCardOffset: const Offset(0, 30),
                    scale: 0.94,
                    // Paket bu değeri dokümantasyonun aksine piksel olarak
                    // karşılaştırıyor; 80px kararlı bir sürükleme demek.
                    threshold: 80,
                    maxAngle: 18,
                    duration: const Duration(milliseconds: 260),
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(horizontal: true),
                    onSwipe: _onSwipe,
                    onUndo: _onUndo,
                    onEnd: _finish,
                    cardBuilder: (context, index, horizontalOffset, _) {
                      final word = _words[index];
                      final isTop = index == _topIndex;
                      return Flashcard(
                        key: ValueKey(word.id),
                        strings: ref.watch(stringsProvider),
                        word: word,
                        isFlipped: isTop && _isFlipped,
                        isStarred: starred.contains(word.id),
                        reversed: _reversedFlags[index],
                        showTransliteration: _settings.showTransliteration,
                        showStressMarks: _settings.showStressMarks,
                        // Arka kartlara paket zaten 0 gönderiyor.
                        dragPercent: horizontalOffset / 100,
                        onFlip: () => setState(() => _isFlipped = !_isFlipped),
                        onStarToggle: () {
                          final added = ref
                              .read(starredProvider.notifier)
                              .toggle(word.id);
                          added ? Haptics.medium() : Haptics.light();
                        },
                        onSpeak: _speak,
                        onReport: () => showReportSheet(context, ref, word),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: StudyActionBar(
                    canUndo: _history.isNotEmpty,
                    isFlipped: _isFlipped,
                    onUndo: _swiperController.undo,
                    onFlip: () => setState(() => _isFlipped = !_isFlipped),
                    onReview: () =>
                        _swiperController.swipe(CardSwiperDirection.left),
                    onLearned: () =>
                        _swiperController.swipe(CardSwiperDirection.right),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeRecord {
  const _SwipeRecord({
    required this.word,
    required this.learned,
    required this.wasLearned,
  });

  final Word word;

  /// Bu kaydırmada verilen karar.
  final bool learned;

  /// Kaydırmadan önceki kalıcı durum; "geri al" buraya döner.
  final bool wasLearned;
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.title,
    required this.current,
    required this.total,
    required this.learned,
    required this.review,
    required this.progress,
    required this.accent,
    required this.strings,
    required this.onClose,
  });

  final String title;
  final int current;
  final int total;
  final int learned;
  final int review;
  final double progress;
  final Color accent;
  final Strings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: onClose,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$current / $total ${strings.wordsCounter}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textTertiary),
                    ),
                  ],
                ),
              ),
              // Sol taraftaki butonla simetri kurmak için görünmez denge.
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Tally(
                count: learned,
                color: palette.learned,
                icon: Icons.check_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: palette.track,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Tally(
                count: review,
                color: palette.review,
                icon: Icons.refresh_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({
    required this.count,
    required this.color,
    required this.icon,
  });

  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.light();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.separator),
        ),
        child: Icon(icon, size: 24, color: palette.textPrimary),
      ),
    );
  }
}

class _EmptyDeckState extends StatelessWidget {
  const _EmptyDeckState({required this.palette, required this.strings});

  final AppPalette palette;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_outlined,
              size: 54,
              color: palette.textTertiary,
            ),
            const SizedBox(height: 18),
            Text(strings.deckEmpty, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              strings.deckEmptyHint,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
