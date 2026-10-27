import 'dart:math';
import 'dart:ui';

import 'design_map_layouts.g.dart';

/// Assets illustres de Margaux Verany, v1 du 27/10/2026 : VERSION DE TRAVAIL,
/// non validee par David. Sources : design/assets/ (README.md et
/// manifest.json), copiees dans assets/images/{map,places,icons}/.
///
/// Tous les chemins et coordonnees sont ici. Retour arriere sans toucher au
/// code : `--dart-define=DESIGN_ART_V1=false` (ile vectorielle, disques des
/// guides et icones Material). Retour definitif : passer [enabled] a false,
/// retirer les trois dossiers de pubspec.yaml et de assets/images/.
abstract final class DesignArt {
  static const enabled = bool.fromEnvironment(
    'DESIGN_ART_V1',
    defaultValue: true,
  );

  static const _root = 'assets/images';

  // Carte : dispositions generees depuis manifest.json
  // (tool/sync_design_manifest.py -> design_map_layouts.g.dart).
  static const phoneLayout = designPhoneLayout;
  static const tablet43Layout = designTablet43Layout;

  /// Couleur des bandes de lagon autour du cadre (bord de l'illustration).
  static const mapLagoon = Color(0xFF3FC1B0);

  /// Bascule sur la carte tablette quand largeur / hauteur < 1,7 (valide
  /// par Margaux le 27/10/2026, 16:10 compris), si elle existe ; sinon la
  /// carte telephone.
  static const tabletMaxAspect = 1.7;
  static MapLayout layoutFor(
    Size screen, {
    MapLayout? tablet = tablet43Layout,
  }) {
    if (tablet == null || screen.isEmpty) return phoneLayout;
    return screen.aspectRatio < tabletMaxAspect ? tablet : phoneLayout;
  }

  /// Lieux : 140 dp a l'echelle 1 de la carte, grandissent avec le decor,
  /// bornes 120 a 200 dp (cible tactile = boite entiere).
  static const placeBox = 140.0;
  static const placeMin = 120.0;
  static const placeMax = 200.0;
  static double placeSize(double mapScale) =>
      (placeBox * mapScale).clamp(placeMin, placeMax);

  /// Zone de tap : cercle de 130/140 de la taille du lieu, centre.
  static const tapRatio = 130 / 140;

  /// Hauteur du guide (Fuzzle) a l'echelle 1, debout sur son emplacement.
  static const guideHeight = 84.0;

  // Lieux : boite 140 dp, cadenas deja dessine sur la version verrouillee.
  static String place(String id, {required bool locked}) =>
      '$_root/places/place_${id}_${locked ? 'locked' : 'unlocked'}.png';

  // Icones dessinees (objets, contour plum).
  static String icon(String id) => '$_root/icons/icon_$id.png';
  static const _icons = '$_root/icons';
  static const home = '$_icons/icon_home.png';
  static const back = '$_icons/icon_back.png';
  static const soundOn = '$_icons/icon_sound_on.png';
  static const soundOff = '$_icons/icon_sound_off.png';
  static const parentalGate = '$_icons/icon_parental_gate.png';
  static const padlock = '$_icons/icon_padlock.png';
  static const padlockBadge = '$_icons/icon_padlock_badge.png';
  static const beachShell = '$_icons/icon_beach_shell.png';
}

/// Disposition d'une carte illustree (cadre en dp, lieux, guide, HUD).
class MapLayout {
  const MapLayout({
    required this.image,
    required this.frame,
    required this.spots,
    required this.hud,
    this.guideFoot,
    this.safeWidth,
  });

  final String image;
  final Size frame;

  /// Centres des lieux en dp du cadre, par identifiant d'asset.
  final Map<String, Offset> spots;

  /// Zone reservee au HUD (son, entree parents), en dp du cadre.
  final Rect hud;
  final Offset? guideFoot;

  /// Largeur utile qui doit toujours tenir a l'ecran (sinon : cover pur).
  final double? safeWidth;

  /// Echelle cover, reduite si besoin pour garder [safeWidth] visible.
  double scaleFor(Size screen) {
    final cover = max(screen.width / frame.width, screen.height / frame.height);
    final safe = safeWidth;
    return safe == null ? cover : min(cover, screen.width / safe);
  }
}
