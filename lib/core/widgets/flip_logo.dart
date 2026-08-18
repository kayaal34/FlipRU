import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Açılış ekranındaki canlı logo.
///
/// Kartlar yerinde duruyor, kendi eksenlerinde dönüyor: her kartın arka
/// yüzünde öteki dil var. Uygulamanın yaptığı iş de tam olarak bu — kart
/// çevirmek. Dönüş gerçek perspektifle yapılıyor, sahte ölçek büyütmesiyle
/// değil; kart dönerken doğal olarak kısalıp uzuyor.
///
/// Kartların yeri hiç değişmediği için kompozisyon her an simgeyle aynı
/// kalıyor ve iki kartın üst üste binmesi diye bir sorun oluşmuyor.
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

  /// Kartların simgedeki yerleri. Öndeki kart merkeze daha yakın; ikisi bir
  /// parça üst üste biniyor, deste hissini veren şey bu.
  static const _backX = 0.185;
  static const _frontX = -0.115;

  /// Perspektifin gücü. Büyütülürse dönüş abartılı, sıfırlanırsa kart düz bir
  /// dikdörtgen gibi ezilerek döner.
  static const _perspective = 0.0016;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// Öndeki kart önce dönüyor, arkadaki biraz sonra. İkisinin aynı anda
  /// dönmesi mekanik duruyordu; bu kayma sahneye ritim veriyor.
  late final Animation<double> _frontFlip = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.52, curve: Curves.easeInOutCubic),
  );

  late final Animation<double> _backFlip = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.10, 0.62, curve: Curves.easeInOutCubic),
  );

  /// Dönüş bittikten sonra yüzeyin üstünden geçen ışık şeridi.
  late final Animation<double> _sheen = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.58, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    // Açılış ekranının kendi giriş animasyonu (büyüme + solma) 1500 ms
    // sürüyor. Kartların dönüşü onunla aynı karelerde çalışmasın diye giriş
    // bittikten sonra başlıyor.
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
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sıra sabit: yarı saydam kart hep arkada, opak kart hep
                    // önde. Yer değiştirmedikleri için sıra hiç değişmiyor.
                    _card(s, _backFlip.value, back: true),
                    _card(s, _frontFlip.value, back: false),
                    _lightSweep(s, _sheen.value),
                  ],
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
  /// [flip] 0'dan 1'e giderken kart kendi dikey ekseninde yarım tur atıyor.
  /// Yarıyı geçince arka yüz görünür; oradaki yazı ayna görüntüsü olmasın diye
  /// yüz bir tur daha çevriliyor.
  ///
  /// Kartın rengi yerine bağlı, harfi ise dönüşe: arkadaki kart hep yarı
  /// saydam kalıyor, üstündeki yazı TR'den RU'ya geçiyor. Böylece diziliş
  /// simgeyle aynı kalırken iki dil yer değiştirmiş oluyor.
  Widget _card(double s, double flip, {required bool back}) {
    final angle = math.pi * flip;
    final showFront = math.cos(angle) >= 0;
    final letter = back
        ? (showFront ? 'TR' : 'RU')
        : (showFront ? 'RU' : 'TR');

    final transform = Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateY(showFront ? angle : angle + math.pi);

    return Transform.translate(
      offset: Offset(
        s * (back ? _backX : _frontX),
        s * (back ? -0.02 : 0.02),
      ),
      child: Transform.rotate(
        angle: (back ? 15.0 : -7.0) * math.pi / 180,
        child: Transform(
          transform: transform,
          alignment: Alignment.center,
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
              letter,
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

  /// Yüzeyin üstünden bir kez geçen ışık şeridi.
  ///
  /// Kartlar durduktan sonra geliyor ve kenardan girip kenardan çıkıyor;
  /// köşeleri kırpan [ClipRRect] sayesinde başlangıç ve bitişte görünmüyor.
  Widget _lightSweep(double s, double t) {
    return Positioned(
      left: (-0.45 + 1.9 * t) * s,
      top: -s * 0.35,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.32,
          child: Container(
            width: s * 0.26,
            height: s * 1.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.24),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
