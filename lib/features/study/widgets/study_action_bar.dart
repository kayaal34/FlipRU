import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/settings_provider.dart';

/// Kart destesinin altındaki aksiyon satırı.
///
/// Kaydırma zaten mümkün ama bazı kullanıcılar (özellikle tek elle çalışanlar)
/// butonları tercih ediyor; ayrıca "geri al" yalnızca buradan erişilebilir.
class StudyActionBar extends ConsumerWidget {
  const StudyActionBar({
    required this.onReview,
    required this.onLearned,
    required this.onFlip,
    required this.onUndo,
    required this.canUndo,
    required this.isFlipped,
    super.key,
  });

  final VoidCallback onReview;
  final VoidCallback onLearned;
  final VoidCallback onFlip;
  final VoidCallback onUndo;
  final bool canUndo;
  final bool isFlipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final s = ref.watch(stringsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.undo_rounded,
          size: 46,
          iconSize: 20,
          color: palette.textSecondary,
          background: palette.surface,
          enabled: canUndo,
          onTap: onUndo,
          tooltip: s.undo,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.refresh_rounded,
          size: 64,
          iconSize: 29,
          color: palette.review,
          background: palette.surface,
          onTap: onReview,
          tooltip: s.badgeReview,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: isFlipped ? Icons.flip_to_front_rounded : Icons.flip_rounded,
          size: 52,
          iconSize: 22,
          color: palette.accent,
          background: palette.surface,
          onTap: onFlip,
          tooltip: s.flip,
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: Icons.check_rounded,
          size: 64,
          iconSize: 31,
          color: palette.learned,
          background: palette.surface,
          onTap: onLearned,
          tooltip: s.markLearned,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.color,
    required this.background,
    required this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltip;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final opacity = widget.enabled ? 1.0 : 0.35;

    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled
          ? () {
              Haptics.light();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.background,
              shape: BoxShape.circle,
              border: Border.all(color: palette.separator),
              boxShadow: palette.ambientShadow,
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.color,
            ),
          ),
        ),
      ),
    );

    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}
