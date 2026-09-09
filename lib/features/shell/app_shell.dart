import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../tests/tests_screen.dart';
import '../../providers/settings_provider.dart';

/// Uygulamanın üç ana sekmesi.
///
/// İstatistik ayrı bir sekmeydi ama haftada bir açılan bir ekran için alt
/// menüde yer tutmak pahalıydı; ana ekrandaki seri rozetine taşındı.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  /// (secili, secili degil) ciftleri.
  ///
  /// Phosphor'un ayni cizimi hem dolu hem cizgi halde veriyor; secili sekme
  /// dolu olunca hangi sekmede oldugun hapa bakmadan da anlasiliyor.
  static const _tabIcons = [
    (PhosphorIconsFill.house, PhosphorIconsRegular.house),
    (PhosphorIconsFill.graduationCap, PhosphorIconsRegular.graduationCap),
    (PhosphorIconsFill.gearSix, PhosphorIconsRegular.gearSix),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);
    final labels = [s.tabHome, s.tabTests, s.tabSettings];

    return Scaffold(
      // IndexedStack sekme değişiminde kaydırma konumunu koruyor.
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          TestsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          // Sert cizgi yerine yumusak bir yukselti: menu icerigin uzerinde
          // duruyormus gibi duruyor.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, -6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tab = constraints.maxWidth / _tabIcons.length;
                const pillW = 64.0;
                const pillH = 36.0;
                return Stack(
                  children: [
                    // Secili sekmenin arkasindaki hap, sekmeler arasinda
                    // kayiyor. Ayni hareket ana ekrandaki seviye/tema
                    // secicisinde de var; menu ondan ayri bir dil konusmasin.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutQuint,
                      left: tab * _index + (tab - pillW) / 2,
                      top: 7,
                      width: pillW,
                      height: pillH,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _tabIcons.length; i++)
                          Expanded(
                            child: _NavItem(
                              filled: _tabIcons[i].$1,
                              outlined: _tabIcons[i].$2,
                              label: labels[i],
                              selected: _index == i,
                              onTap: () {
                                if (_index == i) return;
                                Haptics.selection();
                                setState(() => _index = i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.filled,
    required this.outlined,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData filled;
  final IconData outlined;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.textTertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Secili simge bir tik buyuyor; hap ile birlikte sekmenin secildigi
          // tek bakista anlasiliyor.
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? filled : outlined,
                key: ValueKey(selected),
                size: 26,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 5),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: color,
              fontSize: 12,
              letterSpacing: 0.1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
