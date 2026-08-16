import 'package:flutter/material.dart';
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
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final learned = ref.watch(learnedProvider).length;
    final starred = ref.watch(starredProvider).length;
    final streak = ref.watch(streakProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.account),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                SettingsSection(
                  title: t.deleteOps,
                  footer: t.deleteOpsFooter,
                  children: [
                    SettingsRow(
                      title: t.clearStars,
                      subtitle: t.clearStarsSub,
                      icon: Icons.star_outline_rounded,
                      danger: true,
                      onTap: starred == 0
                          ? null
                          : () => _confirm(
                                context,
                                title: t.clearStars,
                                message: '$starred · ${t.clearStarsSub}',
                                onConfirm: () =>
                                    ref.read(starredProvider.notifier).clear(),
                                strings: t,
                              ),
                    ),
                    SettingsRow(
                      title: t.resetProgress,
                      subtitle: t.resetProgressSub,
                      icon: Icons.restart_alt_rounded,
                      danger: true,
                      onTap: learned == 0 && streak == 0
                          ? null
                          : () => _confirm(
                                context,
                                title: t.resetProgress,
                                message: '${t.words(learned)} · '
                                    '${t.days(streak)} · '
                                    '${t.resetProgressSub}',
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
                      icon: Icons.settings_backup_restore_rounded,
                      danger: true,
                      onTap: () => _confirm(
                        context,
                        title: t.resetSettings,
                        message: t.resetSettingsSub,
                        onConfirm:
                            ref.read(settingsProvider.notifier).reset,
                        strings: t,
                      ),
                    ),
                    SettingsRow(
                      title: t.deleteAll,
                      subtitle: t.deleteAllSub,
                      icon: Icons.delete_forever_rounded,
                      danger: true,
                      onTap: () => _confirm(
                        context,
                        title: t.deleteAll,
                        message: t.deleteAllSub,
                        confirmLabel: t.deleteAll,
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
                const SizedBox(height: 24),
                Text(
                  t.uninstallNote,
                  textAlign: TextAlign.center,
                  style:
                      textTheme.bodySmall?.copyWith(color: palette.textTertiary),
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
  }) async {
    final palette = context.palette;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: palette.review),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    strings.irreversible,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.review),
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
            style: TextButton.styleFrom(foregroundColor: palette.review),
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
