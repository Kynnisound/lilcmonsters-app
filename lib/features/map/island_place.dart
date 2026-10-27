import 'package:flutter/material.dart';

import '../../core/content/monsters.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/l10n/strings.dart';
import '../../core/router/routes.dart';

/// Comment on entre dans un lieu.
enum PlaceAccess {
  /// Gratuit, ouvert.
  free,

  /// Gratuit mais a debloquer en jouant (ilots).
  unlockable,

  /// Apercu gratuit, contenu complet dans le pass (phase 3).
  premium,

  /// Derriere la porte parentale (liens externes).
  parental,
}

/// Lieu de l'ile : position relative sur la carte (paysage), guide,
/// pictogramme, ambiance.
enum IslandPlace {
  cave(
    Routes.cave,
    S.cave,
    Offset(.13, .30),
    Monster.dottie,
    Icons.palette_rounded,
    PlaceAccess.premium,
    feature: PremiumFeature.coloring,
    artId: 'cave',
    iconArt: 'cave_palette',
  ),
  beach(
    Routes.beach,
    S.beach,
    Offset(.17, .76),
    Monster.pip,
    Icons.music_note_rounded,
    PlaceAccess.free,
    artId: 'beach',
    iconArt: 'beach_shell',
  ),
  forest(
    Routes.forest,
    S.forest,
    Offset(.36, .42),
    Monster.zib,
    Icons.search_rounded,
    PlaceAccess.premium,
    feature: PremiumFeature.fullMonsterHunt,
    artId: 'forest',
    iconArt: 'forest_magnifier',
  ),
  library(
    Routes.library,
    S.library,
    Offset(.53, .74),
    Monster.fuzzle,
    Icons.auto_stories_rounded,
    PlaceAccess.premium,
    feature: PremiumFeature.audioBooks,
    artId: 'library',
    iconArt: 'library_book',
  ),
  lighthouse(
    Routes.lighthouse,
    S.lighthouse,
    Offset(.62, .24),
    Monster.bitsy,
    Icons.play_arrow_rounded,
    PlaceAccess.parental,
    artId: 'lighthouse',
    iconArt: 'lighthouse_play',
  ),
  shadows(
    Routes.shadows,
    S.shadows,
    Offset(.79, .50),
    Monster.bitsy,
    Icons.flashlight_on_rounded,
    PlaceAccess.unlockable,
    artId: 'shadow',
    iconArt: 'shadow_lantern',
  ),
  puzzle(
    Routes.puzzle,
    S.puzzle,
    Offset(.91, .80),
    Monster.fuzzle,
    Icons.extension_rounded,
    PlaceAccess.unlockable,
    artId: 'islets',
    iconArt: 'islets_puzzle',
  );

  const IslandPlace(
    this.route,
    this.label,
    this.position,
    this.guide,
    this.icon,
    this.access, {
    this.feature,
    required this.artId,
    required this.iconArt,
  });

  final String route;
  final String label;
  final Offset position;
  final Monster guide;
  final IconData icon;
  final PlaceAccess access;
  final PremiumFeature? feature;

  /// Identifiants des assets de Margaux (lib/core/content/design_art.dart).
  final String artId;
  final String iconArt;
}
