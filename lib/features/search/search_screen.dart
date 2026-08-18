import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/settings_provider.dart';
import '../words/word_detail_screen.dart';

/// Sözlüğün tamamında arama.
///
/// "Öğrendiğim Kelimeler" ekranındaki arama yalnızca öğrenilen havuzda
/// çalışıyor; burası 8.992 kelimenin tamamını kapsıyor. Bir sözlük
/// uygulamasında kullanıcının aklına gelen kelimeyi bulabilmesi temel
/// beklenti.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  /// Sonuç sayısı üst sınırı. 8.992 kayıtta tek harflik aramada binlerce
  /// satır çizmek hem yavaş hem faydasız.
  static const _limit = 80;

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz klavye gelsin: arama tek adımda başlasın.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Baştan eşleşenler önce, içinde geçenler sonra.
  List<Word> _search(List<Word> all) {
    final needle = _query.trim().toLowerCase();
    if (needle.length < 2) return const [];

    final starts = <Word>[];
    final contains = <Word>[];
    for (final word in all) {
      final ru = word.russian.toLowerCase();
      final tr = word.turkish.toLowerCase();
      if (ru.startsWith(needle) || tr.startsWith(needle)) {
        starts.add(word);
        if (starts.length >= _limit) break;
      } else if (ru.contains(needle) ||
          tr.contains(needle) ||
          word.transliteration.toLowerCase().contains(needle)) {
        if (contains.length < _limit) contains.add(word);
      }
    }
    return [...starts, ...contains].take(_limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final learned = ref.watch(learnedProvider);
    final results = _search(ref.watch(wordRepositoryProvider).allWords);
    final short = _query.trim().length < 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.searchTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: s.searchAllHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      fillColor: palette.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.separator),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.separator),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: short
                      ? _Message(text: s.searchStart, palette: palette)
                      : results.isEmpty
                          ? _Message(
                              text: s.searchNoResult,
                              palette: palette,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              itemCount: results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final word = results[index];
                                return _ResultRow(
                                  word: word,
                                  learned: learned.contains(word.id),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WordDetailScreen(word: word),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                if (!short && results.length >= _limit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      s.searchTooMany,
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textTertiary),
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

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.textTertiary),
          ),
        ),
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.word,
    required this.learned,
    required this.onTap,
  });

  final Word word;
  final bool learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
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
                          word.accented,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: word.tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          word.level.label,
                          style: textTheme.bodySmall?.copyWith(
                            color: word.tint,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      if (learned) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: palette.learned,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.turkish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
