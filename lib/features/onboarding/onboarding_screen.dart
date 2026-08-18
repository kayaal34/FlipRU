import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../shell/app_shell.dart';

/// İlk açılış tanıtımı.
///
/// Önceden kullanıcı doğrudan ana ekrana düşüyordu: kart çevirmenin,
/// kaydırmanın ve bölüm mantığının nasıl işlediğini kimse anlatmıyordu.
/// Üç sayfa — ne olduğu, nasıl çalıştığı, günlük hedef — sonra uygulama.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = 3;

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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
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
                        icon: Icons.menu_book_rounded,
                        tint: palette.accent,
                        title: s.onboardTitle1,
                        body: s.onboardBody1,
                      ),
                      _Slide(
                        icon: Icons.swipe_rounded,
                        tint: palette.learned,
                        title: s.onboardTitle2,
                        body: s.onboardBody2,
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
            child: Icon(Icons.flag_rounded, size: 54, color: palette.star),
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
