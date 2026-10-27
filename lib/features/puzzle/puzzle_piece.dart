import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Affiche la portion [index] d'une image decoupee en [n] x [n].
class PuzzlePiece extends StatelessWidget {
  const PuzzlePiece({
    super.key,
    required this.image,
    required this.n,
    required this.index,
    required this.side,
    this.highlighted = false,
  });

  final String image;
  final int n;
  final int index;
  final double side;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final row = index ~/ n, col = index % n;
    double a(int k) => n == 1 ? 0 : -1 + 2 * k / (n - 1);
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.s),
        border: Border.all(
          color: highlighted ? AppColors.sun : AppColors.plum,
          width: highlighted ? AppSizes.sunRing : 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.s - 3),
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Align(
            alignment: Alignment(a(col), a(row)),
            widthFactor: 1 / n,
            heightFactor: 1 / n,
            child: Image.asset(
              image,
              width: side * n,
              height: side * n,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
