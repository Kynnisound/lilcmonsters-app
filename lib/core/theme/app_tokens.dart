import 'package:flutter/animation.dart';

/// Tokens du theme. Source prioritaire : design/VISUAL_SYSTEM_v0.md
/// (direction V1, design/direction_v1.png). Complement : tokens du site
/// lilcmonsters.com (site/assets/css/main.css, :root).
/// Aucun ecran ne doit utiliser une couleur, une taille ou une duree en dur.
abstract final class AppColors {
  // Direction V1 : turquoise + corail sur les tokens de marque
  static const lagoon = Color(0xFF3FC1B0); // mer, surfaces (= teal du site)
  static const lagoonDeep = Color(0xFF0B6E6A); // icones, contour selection
  static const foam = Color(0xFFD4F4EE); // fonds clairs, cartes
  static const coral = Color(0xFFFF7A5C); // action principale
  static const coralDeep = Color(0xFFC8432A); // tranche du bouton, appui
  static const sand = Color(0xFFFFE4BF); // plage, remplissage de cartes
  static const mist = Color(0xFFB9B3C7); // etat verrouille
  static const mistDeep = Color(0xFF8F88A3); // tranche d'un bouton verrouille
  // Ambiances par lieu (spec section 7)
  static const caveViolet = Color(0xFF3B2A5C);
  static const caveViolet2 = Color(0xFF6B4FA0);
  static const lanternAmber = Color(0xFFFFC56B);
  static const forestLight = Color(0xFFCFE8A8);
  static const moss = Color(0xFF2F6B3A);

  // Les cinq monstres
  static const fuzzle = Color(0xFFFC9313);
  static const pip = Color(0xFF1B98D0);
  static const dottie = Color(0xFF86BE34);
  static const zib = Color(0xFFA75BAD);
  static const bitsy = Color(0xFFFC647D);
  // Accents
  static const sun = Color(0xFFFFD60A); // recompense, deblocage
  static const teal = lagoon;
  // Encres
  static const plum = Color(0xFF3A1752);
  static const plum2 = Color(0xFF6E28A0);
  static const inkSoft = Color(0xFF5A3F6B);
  // Fonds
  static const cream = Color(0xFFFFF6E5);
  static const paper = Color(0xFFFFFDF8);
  static const peach = Color(0xFFFFD9A0);
  static const sky = Color(0xFFE3F2FF);
  static const sunset = Color(0xFFFFC9A3);
  static const dusk = Color(0xFFEAD9F5);
  static const lilac = Color(0xFFDCCDF3);
  // Nuit
  static const night = Color(0xFF1B1747);
  static const night2 = Color(0xFF2A2470);
  static const duskDeep = Color(0xFF43397F);
}

abstract final class AppRadii {
  static const s = 14.0;
  static const m = 24.0;
  static const l = 36.0;
}

abstract final class AppMotion {
  /// Appui : enfoncement de la tranche (spec : 120 ms).
  static const press = Duration(milliseconds: 120);

  /// Oscillation d'un element verrouille (+-4 degres, 300 ms).
  static const wobble = Duration(milliseconds: 300);
  static const wobbleAngleDeg = 4.0;
  static const t1 = Duration(milliseconds: 300);
  static const t2 = Duration(milliseconds: 600);
  static const t3 = Duration(seconds: 1);
  static const t4 = Duration(milliseconds: 1600);
  static const boing = Cubic(.34, 1.56, .64, 1);
  static const soft = Cubic(.22, 1, .36, 1);
  static const io = Cubic(.65, 0, .35, 1);
}

abstract final class AppSizes {
  /// Cible tactile minimale pour l'enfant (spec : 72 dp).
  static const minTouch = 72.0;

  /// Ecart minimal entre deux cibles d'enfant (spec : 24 dp).
  static const gap = 24.0;

  /// Bouton principal (Jouer, Aller, Suivant) : 96 dp.
  static const primary = 96.0;

  /// Retour carte, toujours en haut a gauche : 72 dp.
  static const homeButton = 72.0;

  /// Lieux de la carte : zone tactile entre 120 et 140 dp.
  static const mapSpotMin = 120.0;
  static const mapSpotMax = 140.0;

  /// Pastilles du bac a sable.
  static const pad = 120.0;

  /// Pastilles de couleur (grotte) : 72 dp.
  static const colorDot = 72.0;

  /// Entree de la porte parentale : volontairement petite (44 dp).
  static const parentEntry = 44.0;

  /// Contour plum des boutons et icones (4 dp) et tranche du bouton (12 dp).
  static const outline = 4.0;
  static const buttonEdge = 12.0;
  static const sunRing = 8.0;

  /// Marge minimale du bouton principal au bord de l'ecran.
  static const primaryEdgeMargin = 32.0;
}

/// Polices embarquees (assets/fonts, licences jointes), aucun chargement
/// reseau. Luckiest Guy : titres, capitales uniquement. Baloo 2 : libelles.
abstract final class AppFonts {
  static const display = 'LuckiestGuy';
  static const body = 'Baloo2';
}
