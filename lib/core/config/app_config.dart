/// Drapeaux de configuration lus au build via `--dart-define`.
///
/// Exemples :
///   flutter run --dart-define=PREMIUM_UNLOCKED=true
///   flutter run --dart-define=UNLOCK_ALL_ISLETS=true
class AppConfig {
  const AppConfig({
    this.premiumUnlocked = false,
    this.unlockAllIslets = false,
    this.parentalGateEnabled = true,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    premiumUnlocked: bool.fromEnvironment('PREMIUM_UNLOCKED'),
    unlockAllIslets: bool.fromEnvironment('UNLOCK_ALL_ISLETS'),
    parentalGateEnabled: bool.fromEnvironment(
      'PARENTAL_GATE',
      defaultValue: true,
    ),
  );

  /// Implementation factice des droits : tout le contenu payant est
  /// deverrouille (true) ou verrouille (false).
  final bool premiumUnlocked;

  /// Ouvre directement le puzzle d'ilots et le jeu d'ombres sur la carte.
  final bool unlockAllIslets;

  /// Desactivable uniquement pour le developpement.
  final bool parentalGateEnabled;

  static const youtubeChannelUrl = 'https://www.youtube.com/@LilCMonsters';
}
