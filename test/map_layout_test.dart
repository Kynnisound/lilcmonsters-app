import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/content/design_art.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:seamonsters/core/theme/app_insets.dart';
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

  test('selection : compacte (h <= 360), tablette (< 1,7), telephone', () {
    const tablet = MapLayout(
      image: 'assets/images/map/test_43.png',
      frame: Size(1024, 768),
      spots: {},
      hud: Rect.fromLTRB(844, 0, 1024, 112),
    );
    const compact = MapLayout(
      image: 'assets/images/map/test_compact.png',
      frame: Size(640, 360),
      spots: {},
      hud: Rect.fromLTRB(468, 0, 640, 112),
    );
    const phone = DesignArt.phoneLayout;
    MapLayout pick(
      double w,
      double h, {
      MapLayout? t = tablet,
      MapLayout? c = compact,
    }) => DesignArt.layoutFor(Size(w, h), tablet: t, compact: c);
    // Compacte : 360 dp de haut ou moins, quelle que soit la largeur.
    for (final s in const [
      Size(568, 320),
      Size(640, 360),
      Size(692, 360),
      Size(740, 360),
      Size(800, 360),
      Size(480, 360), // 4:3 bas : compacte d'abord
    ]) {
      expect(pick(s.width, s.height), same(compact), reason: '$s');
    }
    expect(pick(740, 361), same(phone));
    // Tablette : ratio < 1,7.
    expect(pick(1024, 768), same(tablet));
    expect(pick(1366, 1024), same(tablet));
    expect(pick(1280, 800), same(tablet)); // 16:10
    expect(pick(1359, 800), same(tablet)); // 1,699
    expect(pick(1360, 800), same(phone)); // 1,7
    // Telephone.
    for (final s in const [
      Size(667, 375),
      Size(812, 375),
      Size(844, 390),
      Size(932, 430),
      Size(1334, 750),
      Size(1280, 720),
    ]) {
      expect(pick(s.width, s.height), same(phone), reason: '$s');
    }
    // Dispositions absentes : sautees.
    expect(pick(568, 320, c: null), same(phone));
    expect(pick(1024, 768, t: null), same(phone));
    // Dispositions livrees par Margaux.
    expect(
      DesignArt.layoutFor(const Size(568, 320)),
      same(DesignArt.phoneCompactLayout),
    );
    expect(
      DesignArt.layoutFor(const Size(1024, 768)),
      same(DesignArt.tablet43Layout),
    );
    expect(DesignArt.layoutFor(const Size(812, 375)), same(phone));
  });

  test('carte compacte : lieux 120 dp x echelle, bornes 100 a 200, tap 96', () {
    final c = DesignArt.phoneCompactLayout!;
    final s = c.scaleFor(const Size(568, 320));
    expect(s, closeTo(.889, .001));
    expect(c.placeSize(s), closeTo(106.7, .1));
    expect(c.placeSize(.5), 100);
    expect(c.tapFor(100), 96);
    expect(c.tapFor(c.placeSize(1)), closeTo(111.4, .1));
  });

  testWidgets('entree parents : inerte (aucun son) et 44 dp minimum', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    final entry = find.byKey(const Key('parents-entry'));
    final size = tester.getSize(entry);
    // BUG-009 : 48 dp (minimum Android), dessin discret de 44 dp.
    expect(size.width, greaterThanOrEqualTo(AppInsets.adultTouch));
    expect(size.height, greaterThanOrEqualTo(AppInsets.adultTouch));
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
    Size(568, 320),
    Size(640, 360),
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
      final layout = DesignArt.layoutFor(screen);
      final scale = layout.scaleFor(screen);
      final expected = DesignArt.enabled ? layout.placeSize(scale) : null;
      for (final p in IslandPlace.values) {
        final box = tester.getRect(find.byKey(Key('place-${p.name}')));
        expect(
          box.width,
          inInclusiveRange(
            (DesignArt.enabled ? layout.placeMin : 120) - 1e-6,
            200 + 1e-6,
          ),
          reason: p.name,
        );
        if (expected != null) expect(box.width, closeTo(expected, .01));
        expect(box.left, greaterThanOrEqualTo(0));
        expect(box.top, greaterThanOrEqualTo(0));
        expect(box.right, lessThanOrEqualTo(screen.width));
        expect(box.bottom, lessThanOrEqualTo(screen.height));
      }
      // HUD : ancre a l'ecran (coin haut droit), jamais rogne.
      for (final k in ['mute-button', 'parents-entry']) {
        final r = tester.getRect(find.byKey(Key(k)));
        expect(r.left, greaterThanOrEqualTo(0), reason: k);
        expect(r.top, greaterThanOrEqualTo(0), reason: k);
        expect(r.right, lessThanOrEqualTo(screen.width), reason: k);
        expect(r.bottom, lessThanOrEqualTo(screen.height), reason: k);
      }
      expect(
        screen.width -
            tester.getRect(find.byKey(const Key('parents-entry'))).right,
        AppInsets.edge,
      );
      expect(
        tester.getRect(find.byKey(const Key('mute-button'))).top,
        AppInsets.edge,
      );
      // HUD : taille fixe, quel que soit l'ecran.
      expect(
        tester.getSize(find.byKey(const Key('mute-button'))).width,
        AppSizes.homeButton,
      );
      expect(
        tester.getSize(find.byKey(const Key('parents-entry'))).width,
        AppInsets.adultTouch,
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
