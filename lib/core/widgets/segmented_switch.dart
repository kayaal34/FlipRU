import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/haptics.dart';

/// iOS'un kayan segment kontrolü.
///
/// `CupertinoSlidingSegmentedControl` yerine kendi implementasyonumuz var;
/// böylece renkleri ve gölgeyi paletle birebir eşleyebiliyoruz.
class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(13),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutQuint,
                alignment: Alignment(
                  labels.length == 1
                      ? 0
                      : -1 + (2 * selectedIndex / (labels.length - 1)),
                  0,
                ),
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    // Seçili sekme sade beyaz bir hap: ekranda tek vurgu
                    // rengi kalsın, seçici onunla yarışmasın.
                    color: palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: -3,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i == selectedIndex) return;
                          Haptics.selection();
                          onChanged(i);
                        },
                        // Sistem yazı boyutu büyütüldüğünde uzun etiketler
                        // ("Tüm zamanlar") sabit yüksekliğe sığmayıp
                        // kırpılıyordu; kesmek yerine küçültüyoruz.
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: textTheme.labelLarge!.copyWith(
                                  fontSize: 15,
                                  color: i == selectedIndex
                                      ? palette.textPrimary
                                      : palette.textSecondary,
                                  fontWeight: i == selectedIndex
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                child: Text(labels[i], maxLines: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
