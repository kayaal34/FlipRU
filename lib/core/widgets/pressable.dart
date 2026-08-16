import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// Dokunulduğunda hafifçe küçülen sarmalayıcı.
///
/// iOS'taki "press state" hissini verir; Material'in dalga efektini
/// kullanmadığımız için (splashFactory: NoSplash) tüm dokunmatik geri bildirim
/// bu widget üzerinden sağlanır.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.haptic = true,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) Haptics.light();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 140),
          child: widget.child,
        ),
      ),
    );
  }
}
