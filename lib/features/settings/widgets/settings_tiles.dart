import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/haptics.dart';

/// iOS ayarlar listesindeki gruplanmış bölüm.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.children,
    this.title,
    this.footer,
    super.key,
  });

  /// Boş bırakılabilir: tek başına duran bir satırın üstünde başlık
  /// tekrarı gürültü oluyor.
  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title == null)
          const SizedBox(height: 26)
        else
          Padding(
            // Büyük harfli küçük etiket yerine sade grup başlığı: ana
            // ekrandaki "Bugün" ile aynı dil.
            padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
            child: Text(title!, style: textTheme.titleMedium),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Divider(height: 1, color: palette.separator),
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 9, 6, 0),
            child: Text(
              footer!,
              style: textTheme.bodySmall?.copyWith(color: palette.textTertiary),
            ),
          ),
      ],
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 10, 11),
      child: Row(
        children: [
          if (icon != null) ...[
            SettingsIconBox(icon: icon!),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            activeTrackColor: palette.accent,
            onChanged: (next) {
              Haptics.selection();
              onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

/// Seçenekleri yan yana rozet olarak gösteren satır.
class SettingsOptions<T> extends StatelessWidget {
  const SettingsOptions({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                SettingsIconBox(icon: icon!),
                const SizedBox(width: 13),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.bodyLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                _OptionChip(
                  label: labelOf(option),
                  selected: option == selected,
                  onTap: () {
                    Haptics.selection();
                    onChanged(option);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.textPrimary : palette.surfaceSunken,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? palette.canvas : palette.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Sağ tarafında değer/ok olan, dokunulabilir satır.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.onTap,
    this.danger = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final color = danger ? palette.review : palette.textPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              Haptics.light();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surfaceSunken,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: danger ? color : palette.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(color: color),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            if (onTap != null && !danger) ...[
              const SizedBox(width: 4),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 20,
                color: palette.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ayar satırlarının solundaki yumuşak kutulu ikon.
class SettingsIconBox extends StatelessWidget {
  const SettingsIconBox({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: palette.textSecondary),
    );
  }
}
