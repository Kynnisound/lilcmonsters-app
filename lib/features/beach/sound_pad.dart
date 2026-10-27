import 'package:flutter/material.dart';

import '../../core/audio/sound_effect.dart';
import '../../core/content/design_art.dart';
import '../../core/content/monsters.dart';
import '../../core/theme/app_tokens.dart';

/// Une pastille du bac a sable : un monstre (note) ou un objet de plage.
class SoundPadData {
  const SoundPadData({
    required this.id,
    required this.label,
    required this.effect,
    required this.color,
    this.monster,
    this.icon,
    this.iconAsset,
  });

  final String id;
  final String label;
  final SoundEffect effect;
  final Color color;
  final Monster? monster;
  final IconData? icon;

  /// Icone dessinee (assets de Margaux), prioritaire sur [icon].
  final String? iconAsset;
}

final beachPads = <SoundPadData>[
  for (final m in Monster.values)
    SoundPadData(
      id: m.name,
      label: 'Chanson de ${m.displayName}',
      effect: m.note,
      color: m.color,
      monster: m,
    ),
  // Objets de plage : bruitages de Shada (assets/audio/beach/).
  const SoundPadData(
    id: 'wave',
    label: 'Vague',
    effect: SoundEffect.beachWave,
    color: AppColors.lagoon,
    icon: Icons.waves_rounded,
  ),
  const SoundPadData(
    id: 'seagull',
    label: 'Mouette',
    effect: SoundEffect.beachSeagull,
    color: AppColors.sky,
    icon: Icons.flutter_dash_rounded,
  ),
  const SoundPadData(
    id: 'shell',
    label: 'Coquillage',
    effect: SoundEffect.beachShell,
    color: AppColors.peach,
    icon: Icons.spa_rounded,
    iconAsset: DesignArt.enabled ? DesignArt.beachShell : null,
  ),
  const SoundPadData(
    id: 'bubbles',
    label: 'Bulles',
    effect: SoundEffect.beachBubbles,
    color: AppColors.foam,
    icon: Icons.bubble_chart_rounded,
  ),
  const SoundPadData(
    id: 'sand',
    label: 'Sable',
    effect: SoundEffect.beachSand,
    color: AppColors.sand,
    icon: Icons.grain_rounded,
  ),
];
