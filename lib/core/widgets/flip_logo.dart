import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Açılış ekranındaki canlı logo.
///
/// Simgenin PNG hâli sabit duruyordu; burada aynı tasarım widget'larla
/// çiziliyor ve kartlar yer değiştiriyor: arkadaki TR öne geliyor, öndeki RU
/// arkaya gidiyor. Uygulamanın adı da zaten bu — "flip".
///
/// Renkler, ölçüler ve açılar `tool/make_icon.py` ile aynı; simge ve açılış
/// logosu birbirinden ayrışmasın.
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

  /// Kartların yörüngesi: yatayda bu kadar açılıyor, dikeyde bu kadar yay
  /// çiziyorlar. Yatay değer simgedeki kart aralığının aynısı.
  static const _spreadX = 0.185;
  static const _arcY = 0.155;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    // Açılış ekranının kendi giriş animasyonu (büyüme + solma) 1500 ms
    // sürüyor. Takas eskiden onun tam ortasına denk geliyordu; iki animasyon
    // aynı karelerde üst üste binince geçiş ağırlaşıyordu. Artık giriş
    // bittikten sonra başlıyor, ikisi hiç çakışmıyor.
    Future.delayed(const Duration(milliseconds: 800), () {
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
          // Kartlar her karede yeniden çiziliyor; arkadaki renk geçişinin
          // onlarla beraber yeniden boyanmasına gerek yok.
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_controller.value);
                // Derinlik: 0 tam önde, 1 tam arkada. RU önde başlayıp arkaya
                // geçiyor, TR arkada başlayıp öne geliyor.
                final trDepth = 1 - t;
                final ruDepth = t;
                final tr = _card(s, t, back: true);
                final ru = _card(s, t, back: false);
                return Stack(
                  alignment: Alignment.center,
                  // Derinliği büyük olan önce boyanır, yani arkada kalır.
                  // Kartların anahtarı olduğu için bu sıra değişimi onları
                  // yeniden kurmuyor; yalnızca boyama sırası değişiyor.
                  children: trDepth >= ruDepth
                      ? <Widget>[tr, ru]
                      : <Widget>[ru, tr],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Tek bir kart.
  ///
  /// [back] true ise TR kartı: sağdan başlar, üstten dolanıp sola geçer.
  /// false ise RU kartı: soldan başlar, alttan dolanıp sağa geçer.
  ///
  /// Eskiden ikisi de düz bir çizgide gidiyor ve tam ortada aynı noktada
  /// buluşuyordu: yarı saydam TR kartı o anda opak RU kartının üstüne biniyor,
  /// altındaki "RU" yazısı saydamlıktan sızdığı için renk bulanıyordu. Derinlik
  /// sırası da tam o karede değiştiği için göz bunu bir takılma gibi okuyordu.
  /// Yollar artık kesişmiyor: kartlar birbirinin etrafından dolanıyor ve sıra
  /// değişimi ikisinin en ayrık olduğu anda oluyor.
  Widget _card(double s, double t, {required bool back}) {
    // TR sağdan sola ve yukarıdan, RU soldan sağa ve aşağıdan.
    final dir = back ? 1.0 : -1.0;
    final theta = math.pi * t;
    final dx = dir * math.cos(theta) * s * _spreadX;
    // Yayın üstüne simgedeki küçük dikey kaçıklık ekleniyor.
    final dy = -dir * math.sin(theta) * s * _arcY - dir * s * 0.02;

    // Öndeki kart büyük, arkadaki küçük. Eskiden bu ters kuruluydu: başlangıçta
    // arkadaki TR kartı öndeki RU kartından büyük çiziliyordu.
    final depth = back ? 1 - t : t;
    final scale = 1.0 - 0.12 * depth;

    // Kartlar iki uçta simgedeki açılarında duruyor, yol boyunca düzleşiyor.
    final angle = (back ? 15.0 : -7.0) * math.pi / 180 * (1 - 2 * depth).abs();

    return Transform.translate(
      // Anahtar, yığındaki sıra değiştiğinde kartın kendi öğesinin korunmasını
      // sağlıyor. Anahtarsız hâlde Flutter sırayı konuma göre eşleştirdiği için
      // takas karesinde kartın rengi ve yazısı değişiyor, metin yeniden
      // yerleşiyordu — takılmanın bir sebebi de buydu.
      key: back ? const ValueKey('tr') : const ValueKey('ru'),
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: s * 0.35,
            height: s * 0.48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: back ? Colors.white.withValues(alpha: 0.59) : Colors.white,
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
                color: back ? Colors.white.withValues(alpha: 0.92) : _ruInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
