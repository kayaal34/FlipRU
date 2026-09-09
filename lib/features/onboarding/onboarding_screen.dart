import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../alphabet/alphabet_screen.dart';
import '../shell/app_shell.dart';

/// İlk açılış tanıtımı.
///
/// Üç sayfa: ne olduğu, alfabeyi bilip bilmediği, günlük hedef. Kaydırma
/// ve widget tanıtımı çıkarıldı — ilki kartın kendi ipucunda zaten yazıyor,
/// ikincisi kullanıcıdan bir karar istemiyordu.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = 3;

  /// Son sayfada "alfabeyle başla" seçilirse bitişte alfabe ekranı açılır.
  bool _startWithAlphabet = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    Haptics.light();
    if (_page + 1 >= _pages) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(onboardingDone: true));
    // Yonlendirmeyi bu ekran kendi context'iyle yapiyor. Onceden acilis
    // ekranindan gelen bir geri cagirma kullaniliyordu; o ekran bu noktada
    // coktan kapanmis oluyor ve olu bir context'e dokunuluyordu.
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
    // Alfabe, kabuğun üstüne açılıyor: geri tuşu kullanıcıyı ana ekrana
    // bırakıyor, alfabeyi atlamak için ayrı bir yol aramasına gerek kalmıyor.
    if (_startWithAlphabet) {
      navigator.push(MaterialPageRoute(builder: (_) => const AlphabetScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);
    final goal = ref.watch(settingsProvider.select((x) => x.dailyGoal));

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(s.onboardSkip),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _Slide(
                        icon: PhosphorIconsRegular.bookOpen,
                        tint: palette.accent,
                        title: s.onboardTitle1,
                        body: s.onboardBody1,
                      ),
                      _AlphabetSlide(
                        strings: s,
                        selected: _startWithAlphabet,
                        onSelect: (value) {
                          Haptics.selection();
                          setState(() => _startWithAlphabet = value);
                        },
                      ),
                      _GoalSlide(
                        strings: s,
                        selected: goal,
                        onSelect: (value) {
                          Haptics.selection();
                          ref
                              .read(settingsProvider.notifier)
                              .update((x) => x.copyWith(dailyGoal: value));
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? palette.accent : palette.track,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _next,
                    child: Text(
                      _page + 1 >= _pages ? s.onboardStart : s.onboardNext,
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
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 54, color: tint),
          ),
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.largeTitle(palette.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// İkinci sayfa: alfabeyi bilip bilmediğini sorar.
///
/// Yeni başlayan için alfabe ilk gün gereken tek şey; bilen için ise ana
/// ekranda sürekli duran bir kart fazlalık. Soruyu burada bir kez sormak
/// ikisini de memnun ediyor.
class _AlphabetSlide extends StatelessWidget {
  const _AlphabetSlide({
    required this.strings,
    required this.selected,
    required this.onSelect,
  });

  final Strings strings;
  final bool selected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.learned.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIconsRegular.textAa, size: 60, color: palette.learned),
          ),
          const SizedBox(height: 34),
          Text(
            strings.onboardTitleAlphabet,
            textAlign: TextAlign.center,
            style: AppTypography.largeTitle(palette.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            strings.onboardBodyAlphabet,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          _AlphabetChoice(
            label: strings.onboardAlphabetStart,
            selected: selected,
            onTap: () => onSelect(true),
          ),
          const SizedBox(height: 10),
          _AlphabetChoice(
            label: strings.onboardAlphabetSkip,
            selected: !selected,
            onTap: () => onSelect(false),
          ),
        ],
      ),
    );
  }
}

class _AlphabetChoice extends StatelessWidget {
  const _AlphabetChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.accent : palette.separator,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? PhosphorIconsRegular.radioButton
                  : PhosphorIconsRegular.circle,
              size: 21,
              color: selected ? palette.accent : palette.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üçüncü sayfa: günlük hedef. Hedefi baştan seçtirmek, ilk günden bir
/// tamamlama hissi veriyor; sonradan ayarlardan değiştirilebiliyor.
class _GoalSlide extends StatelessWidget {
  const _GoalSlide({
    required this.strings,
    required this.selected,
    required this.onSelect,
  });

  final Strings strings;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.star.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIconsRegular.flag, size: 54, color: palette.star),
          ),
          const SizedBox(height: 34),
          Text(
            strings.onboardTitle3,
            textAlign: TextAlign.center,
            style: AppTypography.largeTitle(palette.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            strings.onboardBody3,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final value in AppSettings.dailyGoalOptions)
                Pressable(
                  onTap: () => onSelect(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: value == selected
                          ? palette.accent
                          : palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: value == selected
                            ? palette.accent
                            : palette.separator,
                      ),
                    ),
                    child: Text(
                      '$value',
                      style: textTheme.titleMedium?.copyWith(
                        color: value == selected
                            ? Colors.white
                            : palette.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
