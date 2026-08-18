import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/haptics.dart';

/// Uygulama içi Kiril klavyesi.
///
/// Sistem klavyesine güvenemiyoruz: Türkiye'deki bir telefonda Rusça klavye
/// kurulu olmayabilir ve o durumda kullanıcı cevabı fiziksel olarak yazamaz.
/// Klavye burada olunca yazma pratiği her telefonda çalışıyor.
///
/// Harfler ЙЦУКЕН yerine alfabetik dizili. ЙЦУКЕН gerçek hayatta karşılaşılan
/// düzen ama kas hafızası olmayan biri harfi ararken kayboluyor; burada ölçülen
/// şey yazma hızı değil kelimenin yazılışını hatırlamak, o yüzden bulunabilirlik
/// öncelikli.
class CyrillicKeyboard extends StatelessWidget {
  const CyrillicKeyboard({
    required this.onLetter,
    required this.onBackspace,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final bool enabled;

  static const _rows = <String>[
    'абвгдеёжзий',
    'клмнопрстуф',
    'хцчшщъыьэюя',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows) ...[
          Row(
            children: [
              for (final letter in row.split(''))
                Expanded(
                  child: _Key(
                    label: letter,
                    enabled: enabled,
                    onTap: () => onLetter(letter),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 132,
              child: _Key(
                icon: Icons.backspace_outlined,
                enabled: enabled,
                tint: palette.review,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.enabled,
    required this.onTap,
    this.label,
    this.icon,
    this.tint,
  });

  final String? label;
  final IconData? icon;
  final bool enabled;
  final Color? tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final color = tint ?? palette.textPrimary;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                Haptics.light();
                onTap();
              }
            : null,
        child: Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: palette.separator),
          ),
          child: icon != null
              ? Icon(icon, size: 20, color: color)
              : Text(
                  label!,
                  style: textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
