import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/settings_provider.dart';
import '../../providers/writing_test_providers.dart';
import '../quiz/writing_quiz_screen.dart';

/// Yazma testlerinin listesi.
///
/// Testler kolaydan zora sıralı ve bölüm testlerindeki kuralla açılıyor:
/// bir testi tamamı doğru olacak şekilde geçmeden sonraki açılmıyor.
class WritingTestsScreen extends ConsumerWidget {
  const WritingTestsScreen({super.key});

  void _ac(BuildContext context, WidgetRef ref, WritingTest test) {
    final s = ref.read(stringsProvider);
    if (!test.unlocked) {
      Haptics.medium();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.unitLockedHint)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WritingQuizScreen(
          title: '${s.writingTest} ${test.index}',
          words: test.words,
          testId: test.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final testler = ref.watch(writingTestsProvider);
    final gecilen = testler.where((t) => t.passed).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.writingTest),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Container(
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
                          color: palette.star.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.keyboard_rounded,
                          color: palette.star,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.writingTestsDone(gecilen, testler.length),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.writingTestsSub,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: palette.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final test in testler)
                      _TestKutusu(
                        test: test,
                        onTap: () => _ac(context, ref, test),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestKutusu extends ConsumerWidget {
  const _TestKutusu({required this.test, required this.onTap});

  final WritingTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = ref.watch(stringsProvider);
    final kilitli = !test.unlocked;
    final renk = kilitli
        ? palette.textTertiary
        : (test.passed ? palette.learned : palette.star);

    return Pressable(
      onTap: onTap,
      haptic: !kilitli,
      child: Opacity(
        opacity: kilitli ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: test.passed ? renk : palette.separator,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (kilitli)
                Icon(Icons.lock_rounded, size: 22, color: renk)
              else if (test.passed)
                Icon(Icons.check_circle_rounded, size: 24, color: renk)
              else
                Text(
                  '${test.index}',
                  style: textTheme.displaySmall?.copyWith(
                    fontSize: 26,
                    color: renk,
                  ),
                ),
              const SizedBox(height: 5),
              Text(
                kilitli ? s.locked : s.words(test.words.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall
                    ?.copyWith(color: palette.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
