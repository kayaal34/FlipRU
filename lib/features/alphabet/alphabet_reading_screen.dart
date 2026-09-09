import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_provider.dart';

/// Harfleri öğrendikten sonraki ödül: gerçek kelimeleri okuma.
///
/// Alfabenin karşılığı, tabloyu ezberlemek değil "okuyabiliyorum" anı.
/// Kelimeler veri setinden geliyor ve okunduğunda anlamı zaten tanıdık
/// olanlar seçiliyor — öğrenci harfleri sökerek anlamı kendi buluyor.
class AlphabetReadingScreen extends ConsumerStatefulWidget {
  const AlphabetReadingScreen({required this.teachesCyrillic, super.key});

  /// Kiril ogretiliyorsa Rusca kelimeler okunur, Turk alfabesi
  /// ogretiliyorsa Turkce kelimeler.
  final bool teachesCyrillic;

  @override
  ConsumerState<AlphabetReadingScreen> createState() =>
      _AlphabetReadingScreenState();
}

/// Okunduğunda anlaşılan alıntı kelimeler. Veri setinde bulunmayan olursa
/// sessizce atlanıyor.
const _cyrillicWords = <String>[
  'ресторан',
  'такси',
  'банк',
  'парк',
  'спорт',
  'музыка',
  'театр',
  'метро',
  'телефон',
  'футбол',
  'автобус',
  'доктор',
  'класс',
  'кино',
];

/// Kiril okuruna tanidik gelen Turkce kelimeler.
const _latinWords = <String>[
  'telefon',
  'taksi',
  'doktor',
  'restoran',
  'futbol',
  'müzik',
  'banka',
  'park',
  'spor',
  'metro',
  'otel',
  'kafe',
  'bilet',
  'festival',
];

class _AlphabetReadingScreenState extends ConsumerState<AlphabetReadingScreen> {
  final Set<String> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final words = ref.watch(wordRepositoryProvider).allWords;
    final cyrillic = widget.teachesCyrillic;

    final items = [
      for (final target in cyrillic ? _cyrillicWords : _latinWords)
        for (final w in words)
          if ((cyrillic ? w.russian : w.turkish) == target) w,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.alphabetReadTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  s.alphabetReadIntro,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textTertiary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                for (final word in items) ...[
                  Pressable(
                    onTap: () {
                      Haptics.selection();
                      setState(() => _revealed.add(word.id));
                      ref
                          .read(speechServiceProvider)
                          .speak(
                            cyrillic ? word.russian : word.turkish,
                            language: cyrillic ? 'ru-RU' : 'tr-TR',
                          );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
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
                                Text(
                                  cyrillic
                                      ? (word.accented.isEmpty
                                            ? word.russian
                                            : word.accented)
                                      : word.turkish,
                                  style: AppTypography.hero(
                                    palette.textPrimary,
                                  ).copyWith(fontSize: 30),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _revealed.contains(word.id)
                                      ? (cyrillic ? word.turkish : word.russian)
                                      : s.alphabetReadTapHint,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _revealed.contains(word.id)
                                        ? palette.learned
                                        : palette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.volume_up_rounded,
                            size: 21,
                            color: palette.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: () {
                    ref
                        .read(settingsProvider.notifier)
                        .update(
                          (x) => x.copyWith(
                            alphabetDone: {
                              ...x.alphabetDone,
                              '${cyrillic ? 'ru' : 'tr'}:read',
                            },
                          ),
                        );
                    Navigator.of(context).pop(true);
                  },
                  child: Text(s.finish),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
