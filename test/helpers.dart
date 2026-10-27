import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/app/app.dart';
import 'package:seamonsters/core/audio/audio_providers.dart';
import 'package:seamonsters/core/audio/audio_service.dart';
import 'package:seamonsters/core/config/app_config.dart';
import 'package:seamonsters/core/config/config_providers.dart';
import 'package:seamonsters/core/content/game_random.dart';
import 'package:seamonsters/core/links/link_launcher.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';

class FakeLinkLauncher implements LinkLauncher {
  final List<Uri> opened = [];
  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

class TestHarness {
  final audio = RecordingAudioService();
  final links = FakeLinkLauncher();
  late ProviderContainer container;

  /// Horloge de la porte parentale, avancee a la main.
  DateTime now = DateTime(2026, 10, 27, 12);

  /// Horloge monotone de la porte : suit [now] tant qu'on ne la fixe pas
  /// (tests d'horloge reculee ou avancee).
  Duration? monotonic;
  Duration get elapsed => monotonic ?? now.difference(DateTime(2026));

  /// Etat de blocage enregistre sur l'appareil (partage entre deux
  /// lancements dans les tests de relance).
  ParentalLockStore lockStore = MemoryParentalLockStore();

  ParentalAccess get access => container.read(parentalAccessProvider);
}

/// Question fixe des tests : six fois sept = 42.
const testChallenge = ParentalChallenge(6, 7);

/// Tape [answer] sur le pave de la porte puis valide.
Future<void> answerGate(WidgetTester tester, String answer) async {
  for (final d in answer.split('')) {
    await tester.tap(find.byKey(Key('parental-key-$d')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('parental-submit')));
  await settle(tester);
}

/// Bonne reponse a la porte.
Future<void> passGate(WidgetTester tester) => answerGate(tester, '42');

/// Lance l'appli complete en paysage 1280 x 720 avec des services factices.
Future<TestHarness> pumpApp(
  WidgetTester tester, {
  AppConfig config = const AppConfig(),
  List<Override> extra = const [],
  ParentalChallenge Function()? challenge,
  ParentalLockStore? lockStore,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = TestHarness();
  if (lockStore != null) h.lockStore = lockStore;
  h.container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      audioServiceProvider.overrideWithValue(h.audio),
      linkLauncherProvider.overrideWithValue(h.links),
      gameRandomProvider.overrideWithValue(Random(1)),
      parentalChallengeFactoryProvider.overrideWithValue(
        challenge ?? () => testChallenge,
      ),
      parentalClockProvider.overrideWithValue(() => h.now),
      parentalMonotonicProvider.overrideWithValue(() => h.elapsed),
      parentalLockStoreProvider.overrideWithValue(h.lockStore),
      ...extra,
    ],
  );
  addTearDown(h.container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: const SeaMonstersApp(),
    ),
  );
  await settle(tester);
  return h;
}

/// Les decors bouclent (houle, sablier) : on avance le temps au lieu
/// d'attendre un etat stable.
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
