import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'island_place.dart';

/// Decor de la carte : lagon, ile principale, grotte, foret, phare et deux
/// ilots, peints par-dessus l'illustration de la mer (Scenes.map). Le
/// lagon devient un voile translucide quand l'illustration est presente.
class IslandPainter extends CustomPainter {
  IslandPainter(this.t, {this.seaVeil = 1});

  /// Phase de la houle (0..1), boucle lente.
  final double t;

  /// Opacite du lagon peint (1 : opaque, sans illustration dessous).
  final double seaVeil;

  Offset _at(Size s, IslandPlace p) =>
      Offset(p.position.dx * s.width, p.position.dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.foam.withValues(alpha: seaVeil * .6),
            AppColors.lagoon.withValues(alpha: seaVeil),
          ],
          stops: const [0, .55],
        ).createShader(rect),
    );

    // Houle : arcs lents et peu contrastes.
    final wave = Paint()
      ..color = AppColors.foam.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rng = Random(11);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = size.height * (.2 + rng.nextDouble() * .8);
      final dx = 8 * sin(2 * pi * (t + i / 18));
      final p = Path()
        ..moveTo(x + dx, y)
        ..quadraticBezierTo(x + dx + 12, y - 8, x + dx + 24, y)
        ..quadraticBezierTo(x + dx + 36, y + 8, x + dx + 48, y);
      canvas.drawPath(p, wave);
    }

    final outline = Paint()
      ..color = AppColors.plum
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.outline;
    final shore = Paint()..color = AppColors.foam;
    final sand = Paint()..color = AppColors.sand;
    final grass = Paint()..color = AppColors.forestLight;

    // Ile principale.
    final w = size.width, h = size.height;
    final island = Path()
      ..moveTo(w * .04, h * .55)
      ..cubicTo(w * .02, h * .18, w * .25, h * .06, w * .45, h * .12)
      ..cubicTo(w * .62, h * .05, w * .72, h * .2, w * .70, h * .45)
      ..cubicTo(w * .69, h * .7, w * .62, h * .96, w * .42, h * .95)
      ..cubicTo(w * .25, h * .97, w * .06, h * .93, w * .04, h * .55)
      ..close();
    canvas.drawPath(island.shift(const Offset(0, 6)), shore);
    canvas.drawPath(island, sand);
    final inner = Path()
      ..moveTo(w * .12, h * .45)
      ..cubicTo(w * .14, h * .2, w * .4, h * .15, w * .5, h * .28)
      ..cubicTo(w * .6, h * .38, w * .58, h * .6, w * .44, h * .62)
      ..cubicTo(w * .3, h * .66, w * .1, h * .62, w * .12, h * .45)
      ..close();
    canvas.drawPath(inner, grass);
    canvas.drawPath(island, outline);

    // Foret : arbres ronds autour du lieu.
    final f = _at(size, IslandPlace.forest);
    final tree = Paint()..color = AppColors.dottie;
    final moss = Paint()..color = AppColors.moss;
    for (final o in const [
      Offset(-90, -30),
      Offset(85, -40),
      Offset(-70, 55),
      Offset(95, 35),
      Offset(10, -85),
    ]) {
      canvas.drawCircle(f + o + const Offset(0, 8), 26, moss);
      canvas.drawCircle(f + o, 26, tree);
    }

    // Grotte : rocher violet.
    final c = _at(size, IslandPlace.cave);
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 10), width: 190, height: 140),
      Paint()..color = AppColors.caveViolet,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 170, height: 120),
      Paint()..color = AppColors.caveViolet2,
    );

    // Ilots (puzzle, ombres) et rocher du phare.
    for (final p in [
      IslandPlace.puzzle,
      IslandPlace.shadows,
      IslandPlace.lighthouse,
    ]) {
      final o = _at(size, p);
      final r = Rect.fromCenter(
        center: o + const Offset(0, 22),
        width: 170,
        height: 90,
      );
      canvas.drawOval(r.shift(const Offset(0, 6)), shore);
      canvas.drawOval(r, sand);
      canvas.drawOval(r, outline);
    }
  }

  @override
  bool shouldRepaint(IslandPainter old) => old.t != t || old.seaVeil != seaVeil;
}
