import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/word.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/settings_provider.dart';
import '../words/word_detail_screen.dart';

/// Öğrenilen kelimelerin listesi.
///
/// Testler sekmesindeki "Öğrendiğim Kelimeler" bu havuzdan karışık soru
/// soruyor; burası ise testsiz hâli — kullanıcı ne öğrendiğini görsün,
/// aradığını bulsun. Arama yalnızca bu havuzda çalışıyor: 8.992 kelimenin
/// tamamında arama ayrı bir iş, burada istenen "öğrendiklerim içinde ara".
class LearnedScreen extends ConsumerStatefulWidget {
  const LearnedScreen({super.key});

  @override
  ConsumerState<LearnedScreen> createState() => _LearnedScreenState();
}

class _LearnedScreenState extends ConsumerState<LearnedScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Rusça, okunuş ve Türkçe karşılık üzerinden süzer.
  List<Word> _filter(List<Word> words) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return words;
    return [
      for (final word in words)
        if (word.russian.toLowerCase().contains(needle) ||
            word.turkish.toLowerCase().contains(needle) ||
            word.transliteration.toLowerCase().contains(needle))
          word,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final learnedIds = ref.watch(learnedProvider);
    final all = ref.watch(wordRepositoryProvider).allWords;

    final learned = [
      for (final word in all)
        if (learnedIds.contains(word.id)) word,
    ];
    final shown = _filter(learned);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myLearned),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: learned.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    s.learnedEmpty,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: TextField(
                          controller: _controller,
                          onChanged: (value) => setState(() => _query = value),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: s.searchLearned,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Row(
                          children: [
                            Text(
                              s.words(shown.length),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: palette.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: shown.isEmpty
                            ? Center(
                                child: Text(
                                  s.searchNoResult,
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: palette.textTertiary),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 28),
                                itemCount: shown.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) => _LearnedRow(
                                  word: shown[index],
                                  onOpen: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WordDetailScreen(word: shown[index]),
                                    ),
                                  ),
                                  onSpeak: () => ref
                                      .read(speechServiceProvider)
                                      .speak(shown[index].russian),
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

class _LearnedRow extends StatelessWidget {
  const _LearnedRow({
    required this.word,
    required this.onOpen,
    required this.onSpeak,
  });

  final Word word;
  final VoidCallback onOpen;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
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
                  Text(word.accented, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    word.turkish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    word.transliteration,
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.volume_up_rounded,
                size: 21,
                color: palette.textTertiary,
              ),
              onPressed: onSpeak,
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
