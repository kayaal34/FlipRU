import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/deck.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../study/study_screen.dart';
import '../words/word_detail_screen.dart';
import '../../providers/settings_provider.dart';

/// Yıldızlanan kelimelerin listesi.
///
/// Doğrudan çalışma ekranına atlamak yerine önce liste gösteriyoruz: kullanıcı
/// neyi kaydettiğini görüp gözden geçirebilsin, gerekirse listeden çıkarsın.
class StarredScreen extends ConsumerWidget {
  const StarredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final words = ref.watch(deckWordsProvider(Deck.starred.id));
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.starredTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: words.isEmpty
            ? _EmptyState(palette: palette, strings: s)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    itemCount: words.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _StarredRow(
                      word: words[index],
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordDetailScreen(word: words[index]),
                        ),
                      ),
                      onUnstar: () {
                        Haptics.light();
                        ref
                            .read(starredProvider.notifier)
                            .toggle(words[index].id);
                      },
                      strings: s,
                      onSpeak: (text) =>
                          ref.read(speechServiceProvider).speak(text),
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: words.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: palette.canvas,
                border: Border(top: BorderSide(color: palette.separator)),
              ),
              // `Center` yerine `heightFactor: 1` olan Align: Scaffold alt
              // çubuğu gevşek (loose) yükseklik kısıtıyla ölçtüğü için düz bir
              // Center tüm ekranı kaplayıp gövdeyi örtüyordu.
              child: Align(
                alignment: Alignment.center,
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.star,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudyScreen(
                          title: Deck.starred.titleOf(s),
                          words: words,
                          accent: palette.star,
                        ),
                      ),
                    ),
                    child: Text(
                      '${s.studyAll} (${words.length})',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _StarredRow extends StatelessWidget {
  const _StarredRow({
    required this.strings,
    required this.word,
    required this.onOpen,
    required this.onUnstar,
    required this.onSpeak,
  });

  final Strings strings;
  final Word word;
  final VoidCallback onOpen;
  final VoidCallback onUnstar;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.light();
        onOpen();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.separator),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          word.russian,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: word.tint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          word.level.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: word.tint,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    word.turkish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: palette.textTertiary,
              ),
              tooltip: strings.pronunciation,
              onPressed: () {
                Haptics.light();
                onSpeak(word.russian);
              },
            ),
            IconButton(
              icon: Icon(Icons.star_rounded, size: 22, color: palette.star),
              tooltip: strings.starRemove,
              onPressed: onUnstar,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette, required this.strings});

  final AppPalette palette;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.star.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_outline_rounded,
                size: 38,
                color: palette.star,
              ),
            ),
            const SizedBox(height: 22),
            Text(strings.starredScreenEmpty, style: textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              strings.starredScreenEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
