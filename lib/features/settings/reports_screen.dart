import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/i18n/strings.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/word_report.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';

/// Kullanıcının bildirdiği hatalı kelimeler.
///
/// Bildirimler kaydedildikleri anda gönderiliyor; bu ekran gidemeyenler
/// için ikinci bir şans. Ekran açıldığında da sessizce yeniden deniyor,
/// çoğu zaman kullanıcının hiçbir şeye dokunması gerekmiyor.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  static String _reasonLabel(ReportReason reason, Strings s) =>
      switch (reason) {
        ReportReason.translation => s.reportReasonTranslation,
        ReportReason.example => s.reportReasonExample,
        ReportReason.pronunciation => s.reportReasonPronunciation,
        ReportReason.other => s.reportReasonOther,
      };

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Ekran acilirken bekleyenleri sessizce dene: agi olan kullanici
    // dugmeyi hic gormeden isi bitmis oluyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(reportProvider.notifier).pending.isNotEmpty) _send();
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final gonderilen = await ref.read(reportProvider.notifier).flush();
    if (!mounted) return;
    setState(() => _sending = false);

    final t = ref.read(stringsProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(gonderilen > 0 ? t.reportsSendOk : t.reportsSendFail),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final reports = ref.watch(reportProvider);
    final t = ref.watch(stringsProvider);
    final bekleyen = reports.where((r) => !r.sent).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.reportsTitle),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (reports.isNotEmpty)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trash),
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
                        PhosphorIconsRegular.flag,
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${report.russian} → '
                                          '${report.turkish}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.titleMedium,
                                        ),
                                      ),
                                      if (report.sent) ...[
                                        const SizedBox(width: 7),
                                        Icon(
                                          PhosphorIconsFill.checkCircle,
                                          size: 15,
                                          color: palette.learned,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ReportsScreen._reasonLabel(report.reason, t),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: palette.review,
                                    ),
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
                                PhosphorIconsRegular.x,
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
                  // Bekleyen yoksa dugme yerine tek satirlik bir onay:
                  // basacak bir sey birakmak "acaba gitti mi?" sorusunu
                  // dogurur.
                  child: bekleyen == 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIconsFill.checkCircle,
                              size: 18,
                              color: palette.learned,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.reportsAllSent,
                              style: textTheme.bodyMedium?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        )
                      : FilledButton(
                          onPressed: _sending
                              ? null
                              : () {
                                  Haptics.light();
                                  _send();
                                },
                          child: _sending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Text(t.reportsSending),
                                  ],
                                )
                              : Text('${t.reportsSend} ($bekleyen)'),
                        ),
                ),
              ),
            ),
    );
  }
}
