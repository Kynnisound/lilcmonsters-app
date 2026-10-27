import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Cadenas (ilot ou contenu non debloque).
class PadlockBadge extends StatelessWidget {
  const PadlockBadge({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => _Badge(
    size: size,
    color: AppColors.mist,
    icon: Icons.lock_rounded,
    iconColor: AppColors.plum,
  );
}

/// Couronne (contenu du pass payant).
class CrownBadge extends StatelessWidget {
  const CrownBadge({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => _Badge(
    size: size,
    color: AppColors.sun,
    icon: Icons.workspace_premium_rounded,
    iconColor: AppColors.plum,
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.size,
    required this.color,
    required this.icon,
    this.iconColor = Colors.white,
  });
  final double size;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.plum, width: 3),
    ),
    child: Icon(icon, size: size * 0.55, color: iconColor),
  );
}
