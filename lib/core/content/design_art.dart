import 'dart:ui';

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

  // Carte (manifest.json > map).
  static const map = '$_root/map/map_island_morning.png';

  /// Cadre de la carte en dp (BoxFit.cover sur telephone).
  static const mapFrame = Size(812, 375);

  /// Largeur utile (recadrage 16:9 du manifeste, tous les lieux dedans).
  /// Sur un ecran plus etroit (tablette 4:3), la carte est reduite pour que
  /// cette largeur tienne, et le lagon complete en haut et en bas.
  static const mapSafeWidth = 667.0;

  /// Couleur des bandes de lagon autour du cadre (bord de l'illustration).
  static const mapLagoon = Color(0xFF3FC1B0);

  /// Centre des emplacements des lieux, en dp du cadre 812 x 375.
  static const mapSpots = <String, Offset>{
    'cave': Offset(165, 112),
    'forest': Offset(328, 150),
    'lighthouse': Offset(486, 100),
    'beach': Offset(150, 272),
    'library': Offset(318, 290),
    'shadow': Offset(610, 176),
    'islets': Offset(660, 298),
  };

  /// Pied du guide (Fuzzle) sur la carte, emplacement vide sans lieu.
  static const guideFoot = Offset(480, 346);
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
