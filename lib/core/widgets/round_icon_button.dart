import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'bouncy_button.dart';

/// Anatomie du gros bouton (direction V1, section 4) : disque corail,
/// contour plum 4 dp, tranche coralDeep 12 dp qui disparait a l'appui,
/// icone plum. Variante verrouillee : brume + cadenas.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.color = AppColors.coral,
    this.edgeColor = AppColors.coralDeep,
    this.iconColor = AppColors.plum,
    this.size = AppSizes.homeButton,
  });

  /// Bouton principal 96 dp (Jouer, Aller, Suivant).
  const RoundIconButton.primary({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  }) : color = AppColors.coral,
       edgeColor = AppColors.coralDeep,
       iconColor = AppColors.plum,
       size = AppSizes.primary;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color color;
  final Color edgeColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      semanticLabel: semanticLabel,
      onTap: onTap,
      size: Size.square(size),
      child: ToyDisc(
        color: color,
        edgeColor: edgeColor,
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }
}

/// Disque "jouet" reutilisable (bouton, lieu de la carte).
class ToyDisc extends StatelessWidget {
  const ToyDisc({
    super.key,
    required this.color,
    required this.edgeColor,
    required this.child,
    this.ring,
  });

  final Color color;
  final Color edgeColor;
  final Widget child;

  /// Anneau soleil (nouveau, vient d'etre debloque).
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final down = isPressed(context);
    const edge = AppSizes.buttonEdge;
    return LayoutBuilder(
      builder: (context, c) {
        final side = c.biggest.shortestSide;
        final disc = side - edge;
        return SizedBox.square(
          dimension: side,
          child: Stack(
            children: [
              // Tranche (bas du bouton)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: disc,
                  decoration: BoxDecoration(
                    color: edgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.plum,
                      width: AppSizes.outline,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: AppMotion.press,
                left: 0,
                right: 0,
                top: down ? edge : 0,
                child: Container(
                  height: disc,
                  decoration: BoxDecoration(
                    color: down ? Color.lerp(color, edgeColor, .15) : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ring ?? AppColors.plum,
                      width: ring != null ? AppSizes.sunRing : AppSizes.outline,
                    ),
                    gradient: RadialGradient(
                      center: const Alignment(-.45, -.5),
                      radius: .9,
                      colors: [Color.lerp(color, Colors.white, .28)!, color],
                    ),
                  ),
                  child: ClipOval(child: Center(child: child)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
