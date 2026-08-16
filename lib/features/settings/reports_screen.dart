import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_palette.dart';
import '../../core/i18n/strings.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/word_report.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';

/// Kullanıcının bildirdiği hatalı kelimeler ve bunları bize gönderme yolu.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static String _reasonLabel(ReportReason reason, Strings s) => switch (reason) {
        ReportReason.translation => s.reportReasonTranslation,
        ReportReason.example => s.reportReasonExample,
        ReportReason.pronunciation => s.reportReasonPronunciation,
        ReportReason.other => s.reportReasonOther,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final reports = ref.watch(reportProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.reportsTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (reports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: t.reportsClear,
              onPressed: () {
                Haptics.medium();
                ref.read(reportProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: reports.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 46,
                        color: palette.textTertiary,
                      ),
                      const SizedBox(height: 18),
                      Text(t.reportsEmpty, style: textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                        t.reportsEmptyBody,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(15, 12, 8, 12),
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
                                    '${report.russian} → ${report.turkish}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _reasonLabel(report.reason, t),
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: palette.review),
                                  ),
                                  if (report.note.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      report.note,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: palette.textTertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: palette.textTertiary,
                              ),
                              tooltip: t.reportRemove,
                              onPressed: () => ref
                                  .read(reportProvider.notifier)
                                  .remove(report.wordId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
      bottomNavigationBar: reports.isEmpty
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
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: FilledButton(
                    onPressed: () async {
                      Haptics.light();
                      final text =
                          ref.read(reportProvider.notifier).asText();
                      await SharePlus.instance.share(
                        ShareParams(
                          text: text,
                          subject: 'FlipRU — hatalı kelime bildirimleri',
                        ),
                      );
                    },
                    child: Text('${t.reportsSend} (${reports.length})'),
                  ),
                ),
              ),
            ),
    );
  }
}
