import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Recompense douce (spec section 6) : quelques etincelles autour d'un
/// point, une seule fois, lentes, sans flash ni confettis plein ecran.
class Celebration extends StatefulWidget {
  const Celebration({super.key});

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.t4,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _SparklesPainter(AppMotion.soft.transform(_c.value)),
        size: Size.infinite,
      ),
    ),
  );
}

class _SparklesPainter extends CustomPainter {
  _SparklesPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (.18 + .14 * t);
    final fill = Paint()..color = AppColors.sun.withValues(alpha: 1 - t);
    final stroke = Paint()
      ..color = AppColors.plum.withValues(alpha: (1 - t) * .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 7; i++) {
      final a = -pi / 2 + i * 2 * pi / 7;
      final o = center + Offset(cos(a), sin(a)) * radius;
      final path = _star(o, 10 + 6 * sin(t * pi));
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  Path _star(Offset c, double r) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * .45;
      final a = -pi / 2 + k * pi / 5;
      final o = c + Offset(cos(a) * rr, sin(a) * rr);
      k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.t != t;
}
