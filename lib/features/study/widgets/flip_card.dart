import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Y ekseni etrafında perspektifli 3B dönme animasyonu.
///
/// Kontrollü bir bileşendir: dönme durumunu [showBack] ile üst widget yönetir.
/// Böylece yeni bir karta geçildiğinde kartın ön yüze dönmesi tek satırla
/// halledilebiliyor.
class FlipCard extends StatefulWidget {
  const FlipCard({
    required this.front,
    required this.back,
    required this.showBack,
    this.duration = const Duration(milliseconds: 460),
    super.key,
  });

  final Widget front;
  final Widget back;
  final bool showBack;
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.showBack ? 1 : 0,
  );

  late final Animation<double> _turn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBack != oldWidget.showBack) {
      widget.showBack ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _turn,
      builder: (context, _) {
        final angle = _turn.value * math.pi;
        final isBackVisible = angle > math.pi / 2;

        // Dönüşün ortasında kartı hafifçe küçültmek derinlik hissi veriyor.
        final scale = 1 - 0.05 * math.sin(angle);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0011) // perspektif
          ..rotateY(angle)
          ..scaleByDouble(scale, scale, 1, 1);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: isBackVisible
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.back,
                )
              : widget.front,
        );
      },
    );
  }
}
