import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Point unique pour d'eventuelles mesures d'usage ou de stabilite.
///
/// Conformite Apple Kids Category / Google Play Families : aucun SDK
/// d'analytics, de crash reporting tiers ni de publicite n'est inclus.
/// Toute future implementation devra etre validee (pas d'identifiant
/// publicitaire, pas de donnees personnelles, consentement parental) et
/// rester desactivable.
abstract interface class TelemetryService {
  bool get enabled;
  void setEnabled(bool value);
  void logEvent(String name, [Map<String, Object?> params = const {}]);
  void recordError(Object error, StackTrace? stack);
}

/// Implementation par defaut : ne fait rien, n'envoie rien.
class NoopTelemetryService implements TelemetryService {
  bool _enabled = false;

  @override
  bool get enabled => _enabled;

  @override
  void setEnabled(bool value) => _enabled = value;

  @override
  void logEvent(String name, [Map<String, Object?> params = const {}]) {}

  @override
  void recordError(Object error, StackTrace? stack) {}
}

final telemetryProvider = Provider<TelemetryService>(
  (ref) => NoopTelemetryService(),
);
