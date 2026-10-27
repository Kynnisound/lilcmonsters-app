/// Marges et espacements issus de la QA du 27/10/2026 (complement des
/// tokens de design/, qui ne changent pas).
abstract final class AppInsets {
  /// Distance minimale des commandes aux bords de l'ecran : hors des zones
  /// de gestes systeme (retour Android, centre de controle iOS), 20 dp.
  static const edge = 20.0;

  /// Cible tactile minimale d'une commande adulte (Android : 48 dp,
  /// Apple : 44 pt).
  static const adultTouch = 48.0;

  /// Ecart minimal entre deux zones de toucher voisines (checklist A1).
  static const targetSpacing = 8.0;
}
