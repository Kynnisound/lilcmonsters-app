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
}

/// Lance l'appli complete en paysage 1280 x 720 avec des services factices.
Future<TestHarness> pumpApp(
  WidgetTester tester, {
  AppConfig config = const AppConfig(),
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = TestHarness();
  h.container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      audioServiceProvider.overrideWithValue(h.audio),
      linkLauncherProvider.overrideWithValue(h.links),
      gameRandomProvider.overrideWithValue(Random(1)),
      parentalChallengeFactoryProvider.overrideWithValue(
        () => const ParentalChallenge(3, 4, [11, 12, 13]),
      ),
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
