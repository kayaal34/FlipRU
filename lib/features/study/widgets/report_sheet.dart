import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/i18n/strings.dart';
import '../../../data/models/word.dart';
import '../../../data/models/word_report.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/settings_provider.dart';

/// Hatalı kelime bildirimi için alt sayfa.
///
/// Sözlük verisi otomatik derlendiği için hata kaçınılmaz; kullanıcının
/// bulduğunu iki dokunuşta bildirebilmesi gerekiyor.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref,
  Word word,
) async {
  final palette = context.palette;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: palette.surfaceRaised,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ReportSheet(word: word, ref: ref),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.word, required this.ref});

  final Word word;
  final WidgetRef ref;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static String _label(ReportReason reason, Strings s) => switch (reason) {
        ReportReason.translation => s.reportReasonTranslation,
        ReportReason.example => s.reportReasonExample,
        ReportReason.pronunciation => s.reportReasonPronunciation,
        ReportReason.other => s.reportReasonOther,
      };

  ReportReason? _reason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason;
    if (reason == null) return;
    Haptics.medium();
    widget.ref.read(reportProvider.notifier).add(
          WordReport(
            wordId: widget.word.id,
            russian: widget.word.russian,
            turkish: widget.word.turkish,
            reason: reason,
            note: _noteController.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.ref.read(stringsProvider).reportSaved),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final s = widget.ref.watch(stringsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        22 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
          const SizedBox(height: 18),
          Text(s.reportTitle, style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '${widget.word.accented} → ${widget.word.turkish}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          for (final reason in ReportReason.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Haptics.selection();
                  setState(() => _reason = reason);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: _reason == reason
                        ? palette.accent.withValues(alpha: 0.14)
                        : palette.surfaceSunken,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _reason == reason
                          ? palette.accent
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _reason == reason
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 19,
                        color: _reason == reason
                            ? palette.accent
                            : palette.textTertiary,
                      ),
                      const SizedBox(width: 11),
                      Text(_label(reason, s), style: textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: s.reportNote,
              hintStyle:
                  textTheme.bodyMedium?.copyWith(color: palette.textTertiary),
              filled: true,
              fillColor: palette.surfaceSunken,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _reason == null ? null : _submit,
            child: Text(s.reportSubmit),
          ),
        ],
      ),
    );
  }
}
