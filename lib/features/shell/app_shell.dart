import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/stats_screen.dart';
import '../tests/tests_screen.dart';
import '../../providers/settings_provider.dart';

/// Uygulamanın dört ana sekmesi.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabIcons = [
    (Icons.home_rounded, Icons.home_outlined),
    (Icons.quiz_rounded, Icons.quiz_outlined),
    (Icons.insights_rounded, Icons.insights_outlined),
    (Icons.tune_rounded, Icons.tune_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);
    final labels = [s.tabHome, s.tabTests, s.tabStats, s.tabSettings];

    return Scaffold(
      // IndexedStack sekme değişiminde kaydırma konumunu koruyor.
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          TestsScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.separator)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
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
          Icon(selected ? filled : outlined, size: 23, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10.5,
                  letterSpacing: 0.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
