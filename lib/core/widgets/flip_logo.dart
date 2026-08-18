import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Açılış ekranındaki canlı logo.
///
/// Simgenin PNG hâli sabit duruyordu; burada aynı tasarım widget'larla
/// çiziliyor ve kartlar yer değiştiriyor: arkadaki TR öne geliyor, öndeki RU
/// arkaya gidiyor. Uygulamanın adı da zaten bu — "flip".
///
/// Renkler `tool/make_icon.py` ile aynı; simge ve açılış logosu birbirinden
/// ayrışmasın.
class FlipLogo extends StatefulWidget {
  const FlipLogo({this.size = 124, super.key});

  final double size;

  @override
  State<FlipLogo> createState() => _FlipLogoState();
}

class _FlipLogoState extends State<FlipLogo>
    with SingleTickerProviderStateMixin {
  static const _bgTop = Color(0xFF635BFF);
  static const _bgMid = Color(0xFF8B5CF6);
  static const _bgBottom = Color(0xFFEC4899);
  static const _ruInk = Color(0xFF5B3CDC);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    // Bir kez dönüp duruyor: açılış ekranı zaten kısa, sürekli dönen bir
    // animasyon huzursuz görünüyor.
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(s * 0.24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(s * 0.24),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // 0 -> 1 arasında kartlar yer değiştiriyor.
              final t = Curves.easeInOutCubic.transform(_controller.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Derinlik sırası ortada değişiyor: t < 0.5 iken TR arkada.
                  if (t < 0.5) ...[
                    _card(s, t, back: true),
                    _card(s, t, back: false),
                  ] else ...[
                    _card(s, t, back: false),
                    _card(s, t, back: true),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Tek bir kart.
  ///
  /// [back] true ise TR kartı: sağdan başlayıp sola geçiyor. false ise RU
  /// kartı: soldan sağa. İkisi de yol boyunca hafifçe küçülüp büyüyor, böylece
  /// öne/arkaya gitme hissi oluşuyor.
  Widget _card(double s, double t, {required bool back}) {
    // TR sağdan sola, RU soldan sağa.
    final from = back ? 1.0 : -1.0;
    final shift = from * (1 - 2 * t);
    final dx = shift * s * 0.185;

    // Ortada küçülüp kenarlarda büyüyor: derinlik hissi.
    final depth = back ? t : 1 - t;
    final scale = 0.9 + 0.1 * (1 - depth);
    final angle = (back ? 15.0 : -7.0) * math.pi / 180 * (1 - 2 * depth).abs();

    return Transform.translate(
      offset: Offset(dx, back ? -s * 0.02 : s * 0.02),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: s * 0.35,
            height: s * 0.48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: back
                  ? Colors.white.withValues(alpha: 0.59)
                  : Colors.white,
              borderRadius: BorderRadius.circular(s * 0.06),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: s * 0.06,
                  offset: Offset(0, s * 0.02),
                ),
              ],
            ),
            child: Text(
              back ? 'TR' : 'RU',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: s * 0.13,
                color: back
                    ? Colors.white.withValues(alpha: 0.92)
                    : _ruInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
