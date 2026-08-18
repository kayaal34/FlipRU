import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../core/i18n/strings.dart';
import '../../data/models/premium.dart';
import '../../providers/premium_provider.dart';
import '../../providers/settings_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  PremiumPlan _selected = PremiumPlan.yearly;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final premium = ref.watch(premiumProvider);
    final s = ref.watch(stringsProvider);
    final benefits = [
      (Icons.all_inclusive_rounded, s.benefitAllWords, s.benefitAllWordsSub),
      (Icons.lock_open_rounded, s.benefitOpenAll, s.benefitOpenAllSub),
      (Icons.format_quote_rounded, s.benefitSentences, s.benefitSentencesSub),
      (Icons.quiz_rounded, s.benefitTests, s.benefitTestsSub),
      (Icons.lightbulb_rounded, s.benefitHints, s.benefitHintsSub),
      (Icons.category_rounded, s.benefitThemes, s.benefitThemesSub),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.premiumTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (premium.isActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.learnedSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.learned),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: palette.learned,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${s.premiumActive} · '
                            '${premium.remainingDays} ${s.premiumDaysLeft}',
                            style: textTheme.titleMedium
                                ?.copyWith(color: palette.learned),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.accent,
                          Color.lerp(palette.accent, palette.star, 0.5)!,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.premiumHeadline,
                          style: textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.premiumSub,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                for (final (icon, title, subtitle) in benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(icon, size: 19, color: palette.accent),
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
                                style: textTheme.bodySmall
                                    ?.copyWith(color: palette.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                // Mağaza bağlanana kadar fiyat ve satın alma düğmesi
                // gösterilmiyor: karşılığı olmayan bir satın alma sunmak
                // Play politikasına aykırı. Ayrıcalıklar yukarıda anlatılıyor,
                // burada yalnızca "yakında" deniyor.
                if (!kBillingConnected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surfaceSunken,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 20,
                          color: palette.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.premiumSoon,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: palette.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  for (final plan in PremiumPlan.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PlanTile(
                        plan: plan,
                        strings: s,
                        selected: _selected == plan,
                        onTap: () {
                          Haptics.selection();
                          setState(() => _selected = plan);
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _purchase(context, s),
                    child: Text('${_planLabel(plan: _selected, strings: s)} · '
                        '${_selected.price}'),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _restore(context, s),
                    child: Text(s.restorePurchase),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.renewNote,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gerçek satın alma akışı henüz bağlı değil.
  ///
  /// Kullanıcıdan para alacak bir düğmenin çalışıyormuş gibi davranması
  /// kabul edilemez; mağaza ürünleri tanımlanana kadar durumu açıkça
  /// söylüyoruz.
  Future<void> _purchase(BuildContext context, Strings s) async {
    Haptics.light();
    await _notice(context, s.paymentPendingTitle, s.paymentPendingBody, s);
  }

  /// Abonelik kullanıcının mağaza hesabına bağlı olduğu için uygulamada hesap
  /// açmaya gerek yok: yeni cihazda aynı mağaza hesabıyla giriş yapıp buradan
  /// geri yüklemek yeterli.
  Future<void> _restore(BuildContext context, Strings s) async {
    Haptics.light();
    await _notice(context, s.restoreTitle, s.restoreBody, s);
  }

  Future<void> _notice(
    BuildContext context,
    String title,
    String body,
    Strings s,
  ) async {
    final palette = context.palette;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.understood),
          ),
        ],
      ),
    );
  }

  String _planLabel({required PremiumPlan plan, required Strings strings}) =>
      switch (plan) {
        PremiumPlan.monthly => strings.planMonthly,
        PremiumPlan.quarterly => strings.planQuarterly,
        PremiumPlan.yearly => strings.planYearly,
      };
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.strings,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlan plan;
  final Strings strings;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.accent : palette.separator,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 21,
              color: selected ? palette.accent : palette.textTertiary,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        switch (plan) {
                          PremiumPlan.monthly => strings.planMonthly,
                          PremiumPlan.quarterly => strings.planQuarterly,
                          PremiumPlan.yearly => strings.planYearly,
                        },
                        style: textTheme.titleMedium,
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.learned.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${plan.badge!} ${strings.discount}',
                            style: textTheme.labelSmall
                                ?.copyWith(color: palette.learned),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.perMonth} ${strings.perMonth}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: palette.textTertiary),
                  ),
                ],
              ),
            ),
            Text(plan.price, style: textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
