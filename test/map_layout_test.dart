import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/content/design_art.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:seamonsters/core/theme/app_tokens.dart';
import 'package:seamonsters/core/widgets/bouncy_button.dart';
import 'package:seamonsters/core/widgets/wobble.dart';
import 'package:seamonsters/features/beach/beach_screen.dart';
import 'package:seamonsters/features/map/island_place.dart';

import 'helpers.dart';

void main() {
  test('taille des lieux : 140 dp x echelle, bornee entre 120 et 200 dp', () {
    expect(DesignArt.placeSize(.5), 120);
    expect(DesignArt.placeSize(.9), 126);
    expect(DesignArt.placeSize(1), 140);
    expect(DesignArt.placeSize(1.2), closeTo(168, 1e-9));
    expect(DesignArt.placeSize(1.92), 200);
    expect(DesignArt.placeSize(4), 200);
  });

  test('carte tablette quand largeur / hauteur < 1,6, si elle existe', () {
    const tablet = MapLayout(
      image: 'assets/images/map/test_43.png',
      frame: Size(1024, 768),
      spots: {},
      hud: Rect.fromLTRB(864, 0, 1024, 112),
    );
    MapLayout pick(double w, double h, [MapLayout? t = tablet]) =>
        DesignArt.layoutFor(Size(w, h), tablet: t);
    expect(pick(1024, 768, null), same(DesignArt.phoneLayout));
    expect(pick(1024, 768), same(tablet));
    expect(pick(1366, 1024), same(tablet));
    expect(pick(1279, 800), same(tablet));
    expect(pick(1280, 800), same(DesignArt.phoneLayout));
    expect(pick(1280, 720), same(DesignArt.phoneLayout));
    expect(pick(800, 360), same(DesignArt.phoneLayout));
    // Carte livree par Margaux (manifest.json > map.layouts.tablet43).
    expect(DesignArt.tablet43Layout, isNotNull);
    expect(
      DesignArt.layoutFor(const Size(1024, 768)),
      same(DesignArt.tablet43Layout),
    );
  });

  testWidgets('entree parents : inerte (aucun son) et 44 dp minimum', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    final entry = find.byKey(const Key('parents-entry'));
    final size = tester.getSize(entry);
    expect(size.width, greaterThanOrEqualTo(AppSizes.parentEntry));
    expect(size.height, greaterThanOrEqualTo(AppSizes.parentEntry));
    // Ni oscillation, ni rebond, ni ripple autour de l'entree.
    for (final t in [Wobble, BouncyButton, InkWell, InkResponse]) {
      expect(
        find.ancestor(of: entry, matching: find.byType(t)),
        findsNothing,
        reason: '$t',
      );
    }
    h.audio.played.clear();
    await tester.tap(entry);
    await tester.pump();
    expect(h.audio.played, isEmpty);
    await settle(tester);
    expect(find.byType(ParentalGateView), findsOneWidget);
    expect(h.audio.played, isEmpty);
  });

  for (final screen in const [
    Size(740, 360),
    Size(800, 360),
    Size(1280, 720),
    Size(1024, 768),
    Size(1280, 800),
    Size(1920, 1080),
  ]) {
    testWidgets('lieux a l echelle de la carte, HUD fixe, tap suivi '
        '(${screen.width.toInt()} x ${screen.height.toInt()})', (tester) async {
      final h = await pumpApp(tester);
      tester.view.physicalSize = screen;
      await settle(tester, 4);
      final scale = DesignArt.layoutFor(screen).scaleFor(screen);
      final expected = DesignArt.enabled ? DesignArt.placeSize(scale) : null;
      for (final p in IslandPlace.values) {
        final box = tester.getRect(find.byKey(Key('place-${p.name}')));
        expect(
          box.width,
          inInclusiveRange(120 - 1e-6, 200 + 1e-6),
          reason: p.name,
        );
        if (expected != null) expect(box.width, closeTo(expected, .01));
        expect(box.left, greaterThanOrEqualTo(0));
        expect(box.right, lessThanOrEqualTo(screen.width));
        expect(box.bottom, lessThanOrEqualTo(screen.height));
      }
      // HUD : taille fixe, quel que soit l'ecran.
      expect(
        tester.getSize(find.byKey(const Key('mute-button'))).width,
        AppSizes.homeButton,
      );
      expect(
        tester.getSize(find.byKey(const Key('parents-entry'))).width,
        AppSizes.parentEntry,
      );
      // La zone de tap suit le lieu : cercle de 130/140 centre.
      final beach = tester.getRect(find.byKey(const Key('place-beach')));
      if (DesignArt.enabled) {
        await tester.tapAt(beach.topLeft + const Offset(3, 3));
        await settle(tester, 4);
        expect(find.byType(BeachScreen), findsNothing);
      }
      await tester.tapAt(beach.center);
      await settle(tester);
      expect(find.byType(BeachScreen), findsOneWidget);
      expect(h.audio.played, isNotEmpty);
    });
  }
}
