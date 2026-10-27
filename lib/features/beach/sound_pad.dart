import 'package:flutter/material.dart';

import '../../core/audio/sound_effect.dart';
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
  });

  final String id;
  final String label;
  final SoundEffect effect;
  final Color color;
  final Monster? monster;
  final IconData? icon;
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
  const SoundPadData(
    id: 'wave',
    label: 'Vague',
    effect: SoundEffect.wave,
    color: AppColors.lagoon,
    icon: Icons.waves_rounded,
  ),
  const SoundPadData(
    id: 'drum',
    label: 'Tambour',
    effect: SoundEffect.drum,
    color: AppColors.sunset,
    icon: Icons.circle,
  ),
  const SoundPadData(
    id: 'shell',
    label: 'Coquillage',
    effect: SoundEffect.pop,
    color: AppColors.sand,
    icon: Icons.bubble_chart_rounded,
  ),
  const SoundPadData(
    id: 'star',
    label: 'Etoile de mer',
    effect: SoundEffect.chime,
    color: AppColors.sun,
    icon: Icons.star_rounded,
  ),
];
