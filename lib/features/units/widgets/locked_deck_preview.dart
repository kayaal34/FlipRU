import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/deck.dart';
import '../../../data/models/word.dart';
import '../../../providers/settings_provider.dart';

/// Kilitli bir destenin önizlemesi.
///
/// Kullanıcıyı kapıda çevirmek yerine içeriyi bulanık gösteriyoruz: ilk kelime
/// net duruyor ki ne alacağını görsün, gerisi buzlu camın ardında.
class LockedDeckPreview extends ConsumerWidget {
  const LockedDeckPreview({
    required this.deck,
    required this.sample,
    required this.totalWords,
    required this.onUnlock,
    super.key,
  });

  final Deck deck;

  /// Net gösterilen örnek kelime.
  final Word? sample;
  final int totalWords;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);

    return Stack(
      children: [
        // Arka plan: bulanıklaştırılmış sahte bölüm ızgarası.
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                  children: [
                    for (var i = 0; i < 12; i++)
                      Container(
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.separator),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: textTheme.headlineMedium
                                ?.copyWith(color: deck.tint),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Okunabilirlik için yumuşak perde.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.canvas.withValues(alpha: 0.55),
                  palette.canvas.withValues(alpha: 0.94),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sample != null) ...[
                      Text(
                        s.deckSample,
                        style: textTheme.labelSmall
                            ?.copyWith(color: palette.textTertiary),
                      ),
                      const SizedBox(height: 10),
                      _SampleCard(word: sample!, tint: deck.tint),
                      const SizedBox(height: 26),
                    ],
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.star.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 27,
                        color: palette.star,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${deck.titleOf(s)} ${s.deckLockedTitle}',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${s.words(totalWords)} · ${s.deckLockedBody}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: () {
                        Haptics.light();
                        onUnlock();
                      },
                      child: Text(s.unlockWithPremium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.word, required this.tint});

  final Word word;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
        boxShadow: palette.ambientShadow,
      ),
      child: Column(
        children: [
          Text(
            word.accented,
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 6),
          Text(
            word.transliteration,
            style:
                textTheme.bodySmall?.copyWith(color: palette.textTertiary),
          ),
          const SizedBox(height: 10),
          Text(
            word.turkish,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: tint),
          ),
        ],
      ),
    );
  }
}
