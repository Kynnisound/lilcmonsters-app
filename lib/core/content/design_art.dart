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
  static const phoneCompactLayout = designPhoneCompactLayout;

  /// Couleur des bandes de lagon autour du cadre (bord de l'illustration).
  static const mapLagoon = Color(0xFF3FC1B0);

  /// Selection (manifest.json > map.layout_selection, 27/10/2026) :
  /// hauteur <= 360 dp -> carte compacte ; sinon largeur / hauteur < 1,7
  /// -> carte tablette (16:10 compris) ; sinon carte telephone. Une
  /// disposition absente du manifeste est sautee.
  static const compactMaxHeight = 360.0;
  static const tabletMaxAspect = 1.7;
  static MapLayout layoutFor(
    Size screen, {
    MapLayout? tablet = tablet43Layout,
    MapLayout? compact = phoneCompactLayout,
  }) {
    if (screen.isEmpty) return phoneLayout;
    if (compact != null && screen.height <= compactMaxHeight) return compact;
    if (tablet != null && screen.aspectRatio < tabletMaxAspect) return tablet;
    return phoneLayout;
  }

  /// Lieux des cartes telephone et tablette : 140 dp a l'echelle 1,
  /// grandissent avec le decor, bornes 120 a 200 dp. Chaque disposition
  /// porte sa propre regle ([MapLayout.placeSize]) ; la compacte : 120 dp,
  /// bornes 100 a 200 dp, tap >= 96 dp.
  static const placeBox = 140.0;
  static const placeMin = 120.0;
  static const placeMax = 200.0;
  static double placeSize(double mapScale) =>
      (placeBox * mapScale).clamp(placeMin, placeMax);

  /// Zone de tap : cercle de 130/140 de la taille du lieu, centre.
  static const tapRatio = 130 / 140;

  /// Diametres des cercles de tap des lieux : [base] au plus, resserres
  /// pour laisser [spacing] dp entre deux cercles voisins (BUG-010 ; avec
  /// des diametres d_i <= distance - spacing pour chaque voisin, deux
  /// cercles sont toujours separes d'au moins [spacing]).
  ///
  /// [avoid] : zones de tap fixes (boutons du HUD), prioritaires ; un cercle
  /// reste a [spacing] dp au moins de chacune.
  static List<double> tapDiameters(
    List<Offset> centers,
    double base, {
    double spacing = 8,
    List<Rect> avoid = const [],
  }) => [
    for (var i = 0; i < centers.length; i++)
      [
        base,
        for (var j = 0; j < centers.length; j++)
          if (j != i) (centers[i] - centers[j]).distance - spacing,
        for (final r in avoid) 2 * (_distanceToRect(centers[i], r) - spacing),
      ].reduce(min),
  ];

  static double _distanceToRect(Offset c, Rect r) {
    final dx = max(max(r.left - c.dx, 0.0), c.dx - r.right);
    final dy = max(max(r.top - c.dy, 0.0), c.dy - r.bottom);
    return sqrt(dx * dx + dy * dy);
  }

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

  /// Ombres dessinees (plum a 85 %, 170 dp), affichees telles quelles.
  static String shadow(String monster) => '$_root/shadows/shadow_$monster.png';

  /// Pose en couleur du jeu d'ombres (v2, BUG-005) : meme cadrage que son
  /// ombre, construite depuis son alpha. Dans le jeu d'ombres, elle remplace
  /// toujours l'illustration `monsters/<nom>.webp` (sinon l'enfant ne relie
  /// plus l'ombre a son monstre).
  static String shadowColor(String monster) =>
      '$_root/shadows/color/$monster.png';
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
    this.placeBase = DesignArt.placeBox,
    this.placeMin = DesignArt.placeMin,
    this.placeMax = DesignArt.placeMax,
    this.minTap = 0,
  });

  /// Regle de taille des lieux (manifest.json > place_size).
  final double placeBase;
  final double placeMin;
  final double placeMax;

  /// Diametre minimal du cercle de tap (compacte : 96 dp).
  final double minTap;

  double placeSize(double mapScale) =>
      (placeBase * mapScale).clamp(placeMin, placeMax);

  /// Cercle de tap nominal d'un lieu de taille [place].
  double tapFor(double place) => max(minTap, place * DesignArt.tapRatio);

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
