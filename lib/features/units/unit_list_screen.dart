import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/deck.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/study_unit.dart';
import '../../providers/library_providers.dart';
import '../../providers/unit_providers.dart';
import 'unit_detail_screen.dart';
import '../../providers/settings_provider.dart';

/// Bir destenin bölümleri. Bölümler kolaydan zora sıralı ve sırayla açılıyor.
class UnitListScreen extends ConsumerWidget {
  const UnitListScreen({required this.deck, super.key});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final units = ref.watch(deckUnitsProvider(deck.id));
    final progress = ref.watch(deckProgressProvider(deck.id));
    final passed = units.where((u) => u.passed).length;
    final s = ref.watch(stringsProvider);

    final appBar = AppBar(
      title: Text(
        deck.kind == DeckKind.level ? deck.subtitleOf(s) : deck.titleOf(s),
      ),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 28),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.separator),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: deck.tint.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(deck.icon, color: deck.tint, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$passed / ${units.length} ${s.unitsDone}',
                                  style: textTheme.labelLarge,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${progress.learned} / ${progress.total} '
                                  '${s.wordUnit(progress.total)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: palette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _UnitTile(
                        progress: units[index],
                        tint: deck.tint,
                        strings: s,
                        onTap: () => _open(context, units[index], s),
                      ),
                      childCount: units.length,
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

  void _open(BuildContext context, UnitProgress progress, Strings s) {
    if (!progress.unlocked) {
      Haptics.medium();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.unitLockedHint)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnitDetailScreen(deck: deck, unit: progress.unit),
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.progress,
    required this.tint,
    required this.strings,
    required this.onTap,
  });

  final UnitProgress progress;
  final Color tint;
  final Strings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final locked = !progress.unlocked;
    final color = locked ? palette.textTertiary : tint;

    return Pressable(
      onTap: onTap,
      haptic: !locked,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: progress.passed
                  ? tint.withValues(alpha: 0.5)
                  : palette.separator,
              width: progress.passed ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                Icon(Icons.lock_rounded, size: 22, color: color)
              else if (progress.passed)
                Icon(Icons.check_circle_rounded, size: 24, color: color)
              else
                Text(
                  '${progress.unit.index + 1}',
                  style: textTheme.headlineMedium?.copyWith(color: color),
                ),
              const SizedBox(height: 7),
              Text(
                locked
                    ? strings.locked
                    : '${strings.unit} ${progress.unit.index + 1}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 4,
                  backgroundColor: palette.track,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${progress.learned}/${progress.total}',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
