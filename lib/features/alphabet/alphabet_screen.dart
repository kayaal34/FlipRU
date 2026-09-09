import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
import 'alphabet_lesson_screen.dart';
import 'alphabet_reading_screen.dart';

/// Arayüz dili Türkçeyse Kiril, Rusçaysa Türk alfabesini öğretir.
///
/// Yön ayarına değil arayüz diline bakıyoruz: öğrenilecek alfabe her zaman
/// kullanıcının bilmediği alfabe.
///
/// Ekran bir ders listesi: harfler zorluk grubuna bölünmüş, her grubun
/// sonunda kısa bir sınav, en sonda gerçek kelime okuma var. Bütün harflerin
/// ızgarası referans olarak altta duruyor.
class AlphabetScreen extends ConsumerWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final language = ref.watch(settingsProvider).language;
    final teachesCyrillic = language == AppLanguage.tr;
    final letters = teachesCyrillic ? russianAlphabet : turkishAlphabet;

    return Scaffold(
      appBar: AppBar(title: Text(s.alphabetTitle), centerTitle: false),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: _LessonList(
                      letters: letters,
                      teachesCyrillic: teachesCyrillic,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      s.alphabetAllLetters(letters.length),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.palette.textTertiary,
                        letterSpacing: 0.6,
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
      builder: (_) =>
          _LetterSheet(letter: letter, teachesCyrillic: teachesCyrillic),
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
              style: AppTypography.hero(
                palette.textPrimary,
              ).copyWith(fontSize: 24),
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
                  style: AppTypography.hero(
                    palette.textPrimary,
                  ).copyWith(fontSize: 44),
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
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textTertiary,
                        ),
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
                  icon: const Icon(PhosphorIconsRegular.speakerHigh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Üç harf grubu + okuma adımı. Tamamlananlar işaretli görünüyor.
class _LessonList extends ConsumerWidget {
  const _LessonList({required this.letters, required this.teachesCyrillic});

  final List<AlphabetLetter> letters;
  final bool teachesCyrillic;

  List<AlphabetLetter> _of(LetterGroup group) => [
    for (final l in letters)
      if (l.group == group) l,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final done = ref.watch(settingsProvider).alphabetDone;
    final ttsLanguage = teachesCyrillic ? 'ru-RU' : 'tr-TR';

    // Anahtarlar alfabeye gore ayri: Kiril'i ogrenmek Turk alfabesini
    // ogrenmis saymamali.
    final prefix = teachesCyrillic ? 'ru' : 'tr';
    final lessons = <(String, String, String, List<AlphabetLetter>)>[
      (
        'same',
        s.alphabetGroupSame,
        s.alphabetGroupSameSub,
        _of(LetterGroup.same),
      ),
      (
        'trap',
        s.alphabetGroupTrap,
        s.alphabetGroupTrapSub,
        _of(LetterGroup.trap),
      ),
      (
        'fresh',
        s.alphabetGroupFresh,
        s.alphabetGroupFreshSub,
        _of(LetterGroup.fresh),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (key, title, subtitle, group) in lessons)
          if (group.isNotEmpty) ...[
            _LessonCard(
              title: title,
              subtitle: subtitle,
              badge: group.map((l) => l.upper).join(' '),
              done: done.contains('$prefix:$key'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AlphabetLessonScreen(
                    groupKey: '$prefix:$key',
                    title: title,
                    letters: group,
                    ttsLanguage: ttsLanguage,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        _LessonCard(
          title: s.alphabetReadTitle,
          subtitle: s.alphabetReadSub,
          badge: null,
          done: done.contains('read'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  AlphabetReadingScreen(teachesCyrillic: teachesCyrillic),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.done,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: done ? palette.learned : palette.separator),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done
                    ? palette.learned.withValues(alpha: 0.16)
                    : palette.surfaceSunken,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                done ? PhosphorIconsBold.check : PhosphorIconsRegular.graduationCap,
                size: 20,
                color: done ? palette.learned : palette.textTertiary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      badge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 24,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
