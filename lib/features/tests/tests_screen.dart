import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/deck.dart';
import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../learned/learned_screen.dart';
import '../starred/starred_screen.dart';
import '../../providers/writing_test_providers.dart';
import 'writing_tests_screen.dart';
import 'level_test_units_screen.dart';

/// Testler sekmesi: kullanıcının kendini ölçebileceği bütün yollar.
/// Bir testin acilmasi icin gereken en az ogrenilmis kelime sayisi.
///
/// Onceden dortdu; dort kelimeyle kurulan test bir bolumun bes soruluk
/// parcasi kadar bile degil, olcmuyor. Bir bolum 20 kelime, esik de o.
const _minLearned = 20;

class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final repository = ref.watch(wordRepositoryProvider);
    final starredIds = ref.watch(starredProvider);
    final t = ref.watch(stringsProvider);

    final starred = repository.allWords
        .where((w) => starredIds.contains(w.id))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text(
                  t.testsTitle,
                  style: AppTypography.largeTitle(palette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(t.testsSubtitle, style: textTheme.bodyMedium),
                const SizedBox(height: 22),

                // Pratik yollari kare izgarada; kareler kucuk tutuldu ki
                // seviye testleri de ayni ekranda gorunsun. Gunun testi
                // burada degil ana ekrandaki gunluk hedefler kutusunda.
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _TestTile(
                      icon: PhosphorIconsRegular.keyboard,
                      tint: palette.star,
                      title: t.writingTest,
                      subtitle: t.writingTestSub,
                      enabled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WritingTestsScreen(
                            direction: WritingDirection.trToRu,
                          ),
                        ),
                      ),
                    ),
                    _TestTile(
                      icon: PhosphorIconsRegular.translate,
                      tint: palette.review,
                      title: t.writingTestRu,
                      subtitle: t.writingTestRuSub,
                      enabled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WritingTestsScreen(
                            direction: WritingDirection.ruToTr,
                          ),
                        ),
                      ),
                    ),
                    // Bu ikisi teste degil listeye gidiyor: once kelimelerini
                    // gormek, aramak, dinlemek isteniyor. Test o listelerin
                    // basligindaki oynat dugmesinde.
                    _TestTile(
                      icon: PhosphorIconsFill.checkCircle,
                      tint: palette.learned,
                      title: t.myLearned,
                      subtitle: t.learnedListSub,
                      enabled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LearnedScreen(),
                        ),
                      ),
                    ),
                    _TestTile(
                      icon: PhosphorIconsFill.star,
                      tint: palette.star,
                      title: t.starredTitle,
                      subtitle: starred.isEmpty
                          ? t.starredEmptyHint
                          : t.starredTestSub,
                      enabled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StarredScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
                Text(
                  t.levelTests,
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final deck in ref.watch(levelDecksProvider))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LevelTestRow(deck: deck),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _LevelTestRow extends ConsumerWidget {
  const _LevelTestRow({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final words = ref.watch(deckWordsProvider(deck.id));
    final learned = ref.watch(learnedProvider);
    final t = ref.watch(stringsProvider);

    final known = words.where((w) => learned.contains(w.id)).toList();

    // Test yalnizca ogrenilmis kelimeleri sorar — bilmedigin seyden sinava
    // girmek ogretici degil.
    final pool = known;
    final enabled = pool.length >= _minLearned;

    return _TestCard(
      badge: deck.level?.label,
      icon: deck.icon,
      tint: deck.tint,
      title: '${deck.titleOf(t)} · ${deck.subtitleOf(t)}',
      subtitle: known.length < _minLearned
          ? t.levelTestNeed
          : '${known.length} ${t.levelTestKnown}',
      enabled: enabled,
      compact: true,
      // Dogrudan teste girmek yerine bolum listesine gidiyoruz: B2'de 2.500
      // kelimeyi tek testte sormak ogretici degil.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LevelTestUnitsScreen(deck: deck)),
      ),
      trailing: Text(
        '${known.length}/${words.length}',
        style: textTheme.bodySmall?.copyWith(color: palette.textTertiary),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.compact = false,
    this.trailing,
    this.badge,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;
  final Widget? trailing;

  /// Seviye rozetinde ikon yerine kodu gosteriyoruz (A1, B2…).
  ///
  /// Ikon seti burada 1–5 arasi numarali kareler veriyordu; hem cirkindi hem
  /// de seviye adiyla ilgisi yoktu. Ana ekrandaki deste kartlariyla ayni dili
  /// konussun diye kodun kendisi yaziliyor.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final active = enabled;

    return Pressable(
      onTap: () {
        if (!enabled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(subtitle)));
          return;
        }
        onTap();
      },
      child: Opacity(
        opacity: active ? 1 : 0.72,
        child: Container(
          padding: EdgeInsets.all(compact ? 13 : 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            border: Border.all(color: palette.separator),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: badge == null
                    ? Icon(icon, color: tint, size: compact ? 19 : 22)
                    : Text(
                        badge!,
                        style: textTheme.labelLarge?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13 : 15,
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              const SizedBox(width: 4),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 24,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pratik ekranının kare kartı.
///
/// Satır hâlinde her seçenek aynı ağırlıkta ve uzun bir liste oluyordu;
/// kare düzen dördünü tek bakışta gösteriyor.
class _TestTile extends StatelessWidget {
  const _TestTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: () {
        if (!enabled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(subtitle)));
          return;
        }
        onTap();
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.separator),
          ),
          // Alt yazi yok: kare kartta iki satir aciklama hem tasiyordu hem
          // de kartlari buyutuyordu. Basliklar zaten kendini anlatiyor,
          // kapali durumun gerekcesi dokununca bildirimde cikiyor.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 21),
              ),
              const Spacer(),
              // Flexible: buyuk yazi olceginde bile tasmak yerine kirpiliyor.
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(height: 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
