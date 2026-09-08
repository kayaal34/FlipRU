import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../data/alphabet_data.dart';
import '../../data/models/alphabet_letter.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_provider.dart';

/// Arayüz dili Türkçeyse Kiril, Rusçaysa Türk alfabesini öğretir.
///
/// Yön ayarına değil arayüz diline bakıyoruz: öğrenilecek alfabe her zaman
/// kullanıcının bilmediği alfabe.
class AlphabetScreen extends ConsumerWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);
    final language = ref.watch(settingsProvider).language;
    final teachesCyrillic = language == AppLanguage.tr;
    final letters = teachesCyrillic ? russianAlphabet : turkishAlphabet;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.alphabetTitle),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      s.alphabetIntro(letters.length),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.textTertiary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: letters.length,
                      (context, index) => _LetterTile(
                        letter: letters[index],
                        onTap: () => _openDetail(
                          context,
                          ref,
                          letters[index],
                          teachesCyrillic,
                        ),
                      ),
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

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    AlphabetLetter letter,
    bool teachesCyrillic,
  ) {
    Haptics.selection();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LetterSheet(
        letter: letter,
        teachesCyrillic: teachesCyrillic,
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter, required this.onTap});

  final AlphabetLetter letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.separator),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              letter.pair,
              style: AppTypography.hero(palette.textPrimary)
                  .copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              letter.sound,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: palette.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterSheet extends ConsumerWidget {
  const _LetterSheet({required this.letter, required this.teachesCyrillic});

  final AlphabetLetter letter;
  final bool teachesCyrillic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    // Öğretilen alfabenin dili neyse örnek kelime o dilde seslendirilir.
    final ttsLanguage = teachesCyrillic ? 'ru-RU' : 'tr-TR';

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.separator,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  letter.pair,
                  style: AppTypography.hero(palette.textPrimary)
                      .copyWith(fontSize: 44),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(letter.name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${s.alphabetSound}: ${letter.sound}',
                        style: textTheme.bodySmall
                            ?.copyWith(color: palette.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (letter.note != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surfaceSunken,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  letter.note!,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Text(
              s.alphabetExample,
              style: textTheme.labelSmall?.copyWith(
                color: palette.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(letter.example, style: textTheme.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        letter.meaning,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: palette.textTertiary),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () async {
                    Haptics.selection();
                    final messenger = ScaffoldMessenger.of(context);
                    final spoke = await ref
                        .read(speechServiceProvider)
                        .speak(letter.example, language: ttsLanguage);
                    if (spoke) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          s.ttsMissing(teachesCyrillic ? 'Rusça' : 'Türkçe'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
