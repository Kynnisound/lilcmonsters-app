import 'package:flutter/foundation.dart';

/// Drapeaux de configuration lus au build via `--dart-define`.
///
/// Exemples :
///   flutter run --dart-define=PREMIUM_UNLOCKED=true
///   flutter run --dart-define=UNLOCK_ALL_ISLETS=true
class AppConfig {
  const AppConfig({
    this.premiumUnlocked = false,
    this.unlockAllIslets = false,
    bool parentalGateEnabled = true,
  }) : _parentalGateRequested = parentalGateEnabled;

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

  final bool _parentalGateRequested;

  /// Porte parentale. Desactivable uniquement en debug et en profile :
  /// dans un build release, `PARENTAL_GATE=false` (ou une config de test)
  /// est ignore et la porte reste active.
  bool get parentalGateEnabled =>
      resolveParentalGate(requested: _parentalGateRequested);

  static const youtubeChannelUrl = 'https://www.youtube.com/@LilCMonsters';
}

/// Regle unique : en release, la porte est toujours active.
bool resolveParentalGate({
  required bool requested,
  bool release = kReleaseMode,
}) => release || requested;
