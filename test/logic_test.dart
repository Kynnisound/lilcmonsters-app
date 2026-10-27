import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/config/app_config.dart';
import 'package:seamonsters/core/config/config_providers.dart';
import 'package:seamonsters/core/content/monsters.dart';
import 'package:seamonsters/core/entitlements/entitlement_service.dart';
import 'package:seamonsters/core/entitlements/premium_feature.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:seamonsters/core/progress/progress.dart';
import 'package:seamonsters/core/telemetry/telemetry_service.dart';
import 'package:seamonsters/features/forest/hunt_game.dart';
import 'package:seamonsters/features/puzzle/puzzle_game.dart';
import 'package:seamonsters/features/shadows/shadow_game.dart';

void main() {
  test('puzzle : une piece ne va que dans sa case', () {
    var g = PuzzleGame.start(2, Random(3));
    expect(g.tray.toSet(), {0, 1, 2, 3});
    expect(g.place(1, 2), same(g));
    for (var i = 0; i < 4; i++) {
      g = g.place(i, i);
    }
    expect(g.isComplete, isTrue);
    expect(g.tray, isEmpty);
  });

  test("ombres : la bonne reponse est parmi 3 options distinctes", () {
    for (var s = 0; s < 20; s++) {
      final r = ShadowRound.random(Random(s), avoid: Monster.pip);
      expect(r.options.toSet().length, 3);
      expect(r.options, contains(r.target));
      expect(r.target, isNot(Monster.pip));
    }
  });

  test('chasse : complete quand tous les monstres caches sont trouves', () {
    var g = HuntGame.start(bushCount: 6, monsterCount: 3, rng: Random(2));
    expect(g.hidden.length, 3);
    for (final b in g.hidden.keys) {
      g = g.open(b);
    }
    expect(g.isComplete, isTrue);
  });

  test('porte parentale : question en lettres, reponse de 2 chiffres', () {
    final rng = Random(9);
    for (var i = 0; i < 200; i++) {
      final c = ParentalChallenge.random(rng);
      expect(c.answer, inInclusiveRange(36, 300));
      // Aucun chiffre dans la question : rien a recopier pour l'enfant.
      expect(c.question, isNot(matches(RegExp(r'\d'))));
    }
  });

  test(
    'progression : 3 sons ouvrent le puzzle, un puzzle ouvre les ombres',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(progressProvider.notifier);
      expect(c.read(progressProvider).puzzleUnlocked, isFalse);
      for (var i = 0; i < Progress.soundsToUnlockPuzzle; i++) {
        n.beachSoundPlayed();
      }
      expect(c.read(progressProvider).puzzleUnlocked, isTrue);
      expect(c.read(progressProvider).shadowsUnlocked, isFalse);
      n.puzzleSolved();
      expect(c.read(progressProvider).shadowsUnlocked, isTrue);
    },
  );

  test('UNLOCK_ALL_ISLETS ouvre les ilots', () {
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(unlockAllIslets: true),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(progressProvider).shadowsUnlocked, isTrue);
  });

  test('droits factices : verrouille par defaut, achat simule', () async {
    final s = FakeEntitlementService(premiumUnlocked: false);
    expect(await s.activeEntitlements(), isEmpty);
    expect(await s.purchasePass(), PurchaseOutcome.success);
    expect(await s.activeEntitlements(), PremiumFeature.values.toSet());
    final open = FakeEntitlementService(premiumUnlocked: true);
    expect(await open.activeEntitlements(), PremiumFeature.values.toSet());
  });

  test('telemetrie no-op desactivee par defaut', () {
    final t = NoopTelemetryService();
    expect(t.enabled, isFalse);
    t.logEvent('x');
    t.setEnabled(true);
    expect(t.enabled, isTrue);
  });
}
