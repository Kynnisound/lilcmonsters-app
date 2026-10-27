import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/parental/parental_lock_store.dart';
import '../core/parental/parental_lock_store_device.dart';
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
///
/// [prefs] : preferences locales de l'appareil (shared_preferences), ou
/// seul est enregistre l'etat de blocage de la porte parentale (BUG-011).
List<Override> buildOverrides({SharedPreferences? prefs}) => [
  if (prefs != null)
    parentalLockStoreProvider.overrideWithValue(createDeviceLockStore(prefs)),
];

/// Preferences locales ; nulles si la plateforme les refuse (la porte
/// garde alors son etat en memoire seulement).
Future<SharedPreferences?> loadPreferences() async {
  try {
    return await SharedPreferences.getInstance();
  } on Object catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'bootstrap'),
    );
    return null;
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Paysage sur telephone et tablette (la carte est pensee en largeur).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await loadPreferences();
  final container = ProviderContainer(overrides: buildOverrides(prefs: prefs));
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
