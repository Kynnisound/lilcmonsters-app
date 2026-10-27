/// Contenus payants (phase 3, via RevenueCat). Le reste est gratuit :
/// carte, bac a sable, puzzle, ombres, phare YouTube.
enum PremiumFeature {
  coloring('Coloriages de la grotte'),
  fullMonsterHunt('Chasse aux monstres complete'),
  audioBooks('Livres audio de la bibliotheque');

  const PremiumFeature(this.parentLabel);

  /// Libelle affiche uniquement dans l'espace parents.
  final String parentLabel;
}
