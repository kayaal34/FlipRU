import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/i18n/strings.dart';
import '../../providers/daily_provider.dart';
import '../../providers/library_providers.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/unit_providers.dart';
import 'widgets/settings_tiles.dart';

/// Hesap ve veri yönetimi.
///
/// Geri alınamayan işlemler ana ayar listesinden ayrıldı: kullanıcı yanlışlıkla
/// dokunup ilerlemesini silmesin.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learned = ref.watch(learnedProvider).length;
    final starred = ref.watch(starredProvider).length;
    final streak = ref.watch(streakProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.account),
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // Sifirlamalar sade satirlar.
                //
                // Dordu birden kirmiziydi; ekran bastan asagi uyari gibi
                // duruyordu ve kirmizi hicbir seyi ayirt etmiyordu. Kirmizi
                // artik yalnizca en asagidaki tek islemde — telefonun kendi
                // ayarlarinda da, diger uygulamalarda da boyle.
                SettingsSection(
                  title: t.myData,
                  footer: t.deleteOpsFooter,
                  children: [
                    SettingsRow(
                      title: t.clearStars,
                      subtitle: t.clearStarsSub,
                      icon: PhosphorIconsRegular.star,
                      onTap: starred == 0
                          ? null
                          : () => _confirm(
                              context,
                              title: t.clearStars,
                              message: '$starred · ${t.clearStarsSub}',
                              confirmLabel: t.confirmClear,
                              onConfirm: () =>
                                  ref.read(starredProvider.notifier).clear(),
                              strings: t,
                            ),
                    ),
                    SettingsRow(
                      title: t.resetProgress,
                      subtitle: t.resetProgressSub,
                      icon: PhosphorIconsRegular.arrowClockwise,
                      onTap: learned == 0 && streak == 0
                          ? null
                          : () => _confirm(
                              context,
                              title: t.resetProgress,
                              message:
                                  '${t.words(learned)} · '
                                  '${t.days(streak)} · '
                                  '${t.resetProgressSub}',
                              confirmLabel: t.confirmReset,
                              onConfirm: () {
                                ref.read(learnedProvider.notifier).clear();
                                ref
                                    .read(dailyProgressProvider.notifier)
                                    .clear();
                                ref.read(visitProvider.notifier).clear();
                                ref.read(passedUnitsProvider.notifier).clear();
                              },
                              strings: t,
                            ),
                    ),
                    SettingsRow(
                      title: t.resetSettings,
                      subtitle: t.resetSettingsSub,
                      icon: PhosphorIconsRegular.arrowCounterClockwise,
                      onTap: () => _confirm(
                        context,
                        title: t.resetSettings,
                        message: t.resetSettingsSub,
                        confirmLabel: t.confirmReset,
                        onConfirm: ref.read(settingsProvider.notifier).reset,
                        strings: t,
                      ),
                    ),
                  ],
                ),

                // Geri donusu olmayan tek islem, kendi basina ve kirmizi.
                SettingsSection(
                  footer: t.uninstallNote,
                  children: [
                    SettingsRow(
                      title: t.deleteAll,
                      subtitle: t.deleteAllSub,
                      icon: PhosphorIconsFill.trash,
                      danger: true,
                      onTap: () => _confirm(
                        context,
                        title: t.deleteAll,
                        message: t.deleteAllSub,
                        confirmLabel: t.confirmDelete,
                        danger: true,
                        onConfirm: () {
                          ref.read(learnedProvider.notifier).clear();
                          ref.read(starredProvider.notifier).clear();
                          ref.read(dailyProgressProvider.notifier).clear();
                          ref.read(visitProvider.notifier).clear();
                          ref.read(passedUnitsProvider.notifier).clear();
                          ref.read(reportProvider.notifier).clear();
                          ref.read(settingsProvider.notifier).reset();
                        },
                        strings: t,
                      ),
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

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required Strings strings,
    String? confirmLabel,
    bool danger = false,
  }) async {
    final palette = context.palette;
    // "Geri alinamaz" her isleme dogru ama kirmizi degil: uyari rengi her
    // yerdeyse hicbir yerde ise yaramiyor.
    final uyariRengi = danger ? palette.review : palette.textTertiary;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.warningCircle,
                  size: 18,
                  color: uyariRengi,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    strings.irreversible,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: uyariRengi),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: danger ? palette.review : palette.accent,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel ?? strings.confirmDelete),
          ),
        ],
      ),
    );
    if (approved ?? false) {
      Haptics.medium();
      onConfirm();
    }
  }
}
