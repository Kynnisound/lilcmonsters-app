import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/telemetry/telemetry_service.dart';
import 'app.dart';

/// Point d'assemblage des implementations.
///
/// Aujourd'hui : uniquement des implementations locales (aucun SDK Firebase,
/// RevenueCat, analytics, crash reporting ni publicite).
/// Plus tard (voir README, section Firebase) :
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///   overrides: [
///     authServiceProvider.overrideWithValue(FirebaseAuthService()),
///     storageServiceProvider.overrideWithValue(FirebaseStorageService()),
///     remoteConfigProvider.overrideWithValue(FirebaseRemoteConfigService()),
///     entitlementServiceProvider.overrideWithValue(RevenueCatEntitlementService()),
///   ]
List<Override> buildOverrides() => const [];

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Paysage sur telephone et tablette (la carte est pensee en largeur).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final container = ProviderContainer(overrides: buildOverrides());
  final telemetry = container.read(telemetryProvider);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    telemetry.recordError(details.exception, details.stack);
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SeaMonstersApp(),
    ),
  );
}
