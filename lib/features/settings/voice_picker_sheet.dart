import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/pressable.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_provider.dart';

/// Cihazdaki seslerden birini seçtirir; her satır dokununca dinlenebilir.
///
/// Uygulama kendi ses dosyalarını taşımıyor, telefonun seslendirme motorunu
/// kullanıyor. Motorlar genelde aynı dil için birden çok konuşmacı sunuyor
/// (`-network` olanlar internet ister ama daha doğal); varsayılanı kabul
/// etmek yerine kullanıcıya seçtirmek en ucuz kalite artışı.
class VoicePickerSheet extends ConsumerStatefulWidget {
  const VoicePickerSheet({
    required this.language,
    required this.title,
    super.key,
  });

  final String language;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required String language,
    required String title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoicePickerSheet(language: language, title: title),
    );
  }

  @override
  ConsumerState<VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends ConsumerState<VoicePickerSheet> {
  List<String>? _voices;

  bool get _isRussian => widget.language.startsWith('ru');

  /// Önizleme cümlesi: tek kelime yerine cümle, tınıyı daha iyi duyuruyor.
  String get _sample =>
      _isRussian ? 'Здравствуйте, как ваши дела?' : 'Merhaba, nasılsın?';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ref
        .read(speechServiceProvider)
        .voicesFor(widget.language);
    if (!mounted) return;
    setState(() => _voices = list);
  }

  String get _selected => _isRussian
      ? ref.watch(settingsProvider).ruVoice
      : ref.watch(settingsProvider).trVoice;

  void _select(String name) {
    Haptics.selection();
    ref
        .read(settingsProvider.notifier)
        .update(
          (s) => _isRussian
              ? s.copyWith(ruVoice: name)
              : s.copyWith(trVoice: name),
        );
    ref.read(speechServiceProvider)
      ..setPreferredVoice(widget.language, name)
      ..speak(_sample, language: widget.language, voiceOverride: name);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final t = ref.watch(stringsProvider);
    final voices = _voices;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const SizedBox(height: 18),
            Text(widget.title, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              t.voicePickerHint,
              style: textTheme.bodySmall?.copyWith(
                color: palette.textTertiary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (voices == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (voices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  t.voiceNone,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: voices.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _VoiceTile(
                        label: t.voiceDefault,
                        selected: _selected.isEmpty,
                        onTap: () => _select(''),
                      );
                    }
                    final name = voices[index - 1];
                    return _VoiceTile(
                      label: t.voiceNumbered(index),
                      selected: _selected == name,
                      onTap: () => _select(name),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surfaceSunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? palette.accent : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? palette.accent : palette.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: textTheme.titleSmall)),
            Icon(
              Icons.volume_up_rounded,
              size: 19,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
