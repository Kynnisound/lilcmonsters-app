// Non-regression des rapports QA du 27/10/2026 (BUG-001 a BUG-010) et des
// points a prevoir (manifeste de confidentialite, marges, porte en release).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/audio/sound_effect.dart';
import 'package:seamonsters/core/config/app_config.dart';
import 'package:seamonsters/core/content/design_art.dart';
import 'package:seamonsters/core/content/monsters.dart';
import 'package:seamonsters/core/l10n/strings.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:seamonsters/core/router/app_router.dart';
import 'package:seamonsters/core/router/routes.dart';
import 'package:seamonsters/core/theme/app_insets.dart';
import 'package:seamonsters/core/theme/app_tokens.dart';
import 'package:seamonsters/core/widgets/circle_hit_area.dart';
import 'package:seamonsters/features/beach/beach_screen.dart';
import 'package:seamonsters/features/library/book_player_screen.dart';
import 'package:seamonsters/features/library/library_screen.dart';
import 'package:seamonsters/features/lighthouse/lighthouse_screen.dart';
import 'package:seamonsters/features/map/island_map_screen.dart';
import 'package:seamonsters/features/map/island_place.dart';
import 'package:seamonsters/features/parents/parents_screen.dart';
import 'package:seamonsters/features/puzzle/puzzle_screen.dart';
import 'package:seamonsters/features/shadows/shadow_game.dart';
import 'package:seamonsters/features/shadows/shadows_screen.dart';

import 'helpers.dart';

const phones = [
  Size(568, 320),
  Size(640, 360),
  Size(667, 375),
  Size(692, 360),
  Size(740, 360),
  Size(812, 375),
  Size(844, 390),
  Size(932, 430),
];

Future<void> openParentsViaGate(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('parents-entry')));
  await settle(tester);
  expect(find.byKey(const Key('parental-question')), findsOneWidget);
  await passGate(tester);
  expect(find.byType(ParentsScreen), findsOneWidget);
}

void main() {
  group('BUG-001 porte parentale robuste', () {
    test('30 touchers au hasard : ouverture < 1 % (avant : 100 %)', () {
      final rng = Random(2026);
      const trials = 20000;
      var opened = 0;
      for (var t = 0; t < trials; t++) {
        final access = ParentalAccess(
          now: () => DateTime(2026),
          readGateEnabled: () => true,
        );
        final form = ParentalGateForm(
          access,
          () => ParentalChallenge.random(rng),
        );
        for (var tap = 0; tap < 30; tap++) {
          final key = rng.nextInt(12); // 10 chiffres, effacer, valider
          if (key < 10) {
            form.type(key);
          } else if (key == 10) {
            form.erase();
          } else {
            final step = form.submit();
            if (step == GateStep.success) {
              opened++;
              break;
            }
            if (step == GateStep.lockedOut) break;
          }
        }
      }
      debugPrint('BUG-001 ouvertures au hasard : $opened / $trials');
      expect(opened / trials, lessThan(.01));
    });

    test('3 echecs : blocage 1 min, puis 5 min, puis 15 min', () {
      var now = DateTime(2026);
      final access = ParentalAccess(
        now: () => now,
        readGateEnabled: () => true,
      );
      for (final wait in ParentalAccess.lockSteps) {
        expect(access.recordFailure(), isFalse);
        expect(access.recordFailure(), isFalse);
        expect(access.recordFailure(), isTrue);
        expect(access.isLocked, isTrue);
        now = now.add(wait - const Duration(seconds: 1));
        expect(access.isLocked, isTrue);
        now = now.add(const Duration(seconds: 2));
        expect(access.isLocked, isFalse);
      }
      // Pendant le blocage, valider ne fait rien, meme la bonne reponse.
      access
        ..recordFailure()
        ..recordFailure()
        ..recordFailure();
      final form = ParentalGateForm(access, () => const ParentalChallenge(6, 7))
        ..type(4)
        ..type(2);
      expect(form.canSubmit, isFalse);
      expect(form.submit(), GateStep.typing);
    });

    testWidgets('pave numerique, 3 erreurs ferment la porte et la bloquent', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      // Bien plus de 3 choix : 10 chiffres a saisir, puis valider.
      for (var d = 0; d < 10; d++) {
        expect(find.byKey(Key('parental-key-$d')), findsOneWidget);
      }
      await answerGate(tester, '41');
      await answerGate(tester, '7');
      // Fermer puis rouvrir ne remet pas le compteur a zero.
      await tester.tap(find.byKey(const Key('parental-cancel')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      await answerGate(tester, '420');
      // Troisieme erreur : retour a la carte, aucun acces.
      expect(find.byType(ParentalGateView), findsNothing);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      // Porte bloquee : ni pave ni question, meme sur le phare.
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      expect(find.byKey(const Key('parental-locked')), findsOneWidget);
      expect(find.byKey(const Key('parental-key-4')), findsNothing);
      await tester.tap(find.byKey(const Key('parental-cancel')));
      await settle(tester);
      expect(find.byType(LighthouseScreen), findsNothing);
      // Apres 1 min, la porte revient et la bonne reponse ouvre.
      h.now = h.now.add(const Duration(minutes: 1, seconds: 1));
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-locked')), findsNothing);
      await passGate(tester);
      expect(find.byType(ParentsScreen), findsOneWidget);
      // Aucun son a l'erreur.
      expect(h.audio.played, isNot(contains(SoundEffect.shadowWrong)));
    });

    testWidgets('30 touchers au hasard sur la vraie porte : pas d acces', (
      tester,
    ) async {
      final r = Random(7);
      await pumpApp(tester, challenge: () => ParentalChallenge.random(r));
      final rng = Random(31);
      final keys = [
        for (var d = 0; d < 10; d++) Key('parental-key-$d'),
        const Key('parental-erase'),
        const Key('parental-submit'),
      ];
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      for (var i = 0; i < 30; i++) {
        final f = find.byKey(keys[rng.nextInt(keys.length)]);
        if (f.evaluate().isEmpty) break; // porte fermee (blocage)
        await tester.tap(f, warnIfMissed: false);
        await tester.pump();
      }
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
    });
  });

  group('BUG-002 aucune session partagee', () {
    testWidgets('porte du phare puis espace parents : porte redemandee', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      await passGate(tester);
      expect(find.byType(LighthouseScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('home-button')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-question')), findsOneWidget);
      expect(find.byType(ParentsScreen), findsNothing);
    });

    testWidgets('chaque vignette video redemande la porte', (tester) async {
      final h = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      await passGate(tester);
      for (var i = 1; i <= 2; i++) {
        await tester.tap(find.byKey(const Key('video-ep1')));
        await settle(tester);
        expect(find.byKey(const Key('parental-question')), findsOneWidget);
        expect(h.links.opened.length, i - 1);
        await passGate(tester);
        expect(h.links.opened.length, i);
      }
      // Annuler : rien ne s'ouvre.
      await tester.tap(find.byKey(const Key('open-channel')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('parental-cancel')));
      await settle(tester);
      expect(h.links.opened.length, 2);
    });

    testWidgets('revenir au phare redemande la porte (P1-Y-03)', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      await passGate(tester);
      await tester.tap(find.byKey(const Key('home-button')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      expect(find.byKey(const Key('parental-question')), findsOneWidget);
    });

    testWidgets('laissez-passer a usage unique et de courte duree', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      final router = h.container.read(routerProvider);
      // Lien direct sans porte : retour a la carte.
      router.go(Routes.parents);
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      // Laissez-passer perime (10 s) : refuse.
      h.access.issuePass(ParentalPurpose.parentsSpace);
      h.now = h.now.add(const Duration(seconds: 11));
      router.go(Routes.parents);
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      // Laissez-passer utilise une fois, puis plus rien.
      await openParentsViaGate(tester);
      await tester.tap(find.byKey(const Key('parents-close')));
      await settle(tester);
      router.go(Routes.parents);
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      // Le laissez-passer de l'espace parents n'ouvre pas le phare : la
      // garde du routeur renvoie a la carte (BUG-013).
      h.access.issuePass(ParentalPurpose.parentsSpace);
      router.go(Routes.lighthouse);
      await settle(tester);
      expect(find.byType(LighthouseScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
    });
  });

  group('BUG-003 toute sortie ferme l espace parents', () {
    testWidgets('retour systeme', (tester) async {
      final h = await pumpApp(tester);
      await openParentsViaGate(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(h.access.parentsSpaceOpen, isFalse);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-question')), findsOneWidget);
    });

    testWidgets('croix', (tester) async {
      final h = await pumpApp(tester);
      await openParentsViaGate(tester);
      await tester.tap(find.byKey(const Key('parents-close')));
      await settle(tester);
      expect(h.access.parentsSpaceOpen, isFalse);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-question')), findsOneWidget);
    });

    testWidgets('passage en arriere-plan', (tester) async {
      final h = await pumpApp(tester);
      await openParentsViaGate(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await settle(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(h.access.parentsSpaceOpen, isFalse);
    });
  });

  group('BUG-004 retour systeme Android', () {
    late List<String> calls;
    setUp(() => calls = []);
    void mockPlatform(WidgetTester tester) => tester
        .binding
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call.method);
          return null;
        });

    testWidgets('depuis la plage : retour a la carte', (tester) async {
      await pumpApp(tester);
      mockPlatform(tester);
      await tester.tap(find.byKey(const Key('place-beach')));
      await settle(tester);
      expect(find.byType(BeachScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(find.byType(BeachScreen), findsNothing);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('depuis la carte : rien, l appli reste ouverte', (
      tester,
    ) async {
      await pumpApp(tester);
      mockPlatform(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('depuis un livre : retour a la bibliotheque', (tester) async {
      await pumpApp(tester, config: const AppConfig(premiumUnlocked: true));
      mockPlatform(tester);
      await tester.tap(find.byKey(const Key('place-library')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('book-0')));
      await settle(tester);
      expect(find.byType(BookPlayerScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(LibraryScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('tous les modules reviennent a la carte', (tester) async {
      final h = await pumpApp(
        tester,
        config: const AppConfig(premiumUnlocked: true, unlockAllIslets: true),
      );
      mockPlatform(tester);
      final router = h.container.read(routerProvider);
      for (final r in [
        Routes.beach,
        Routes.cave,
        Routes.forest,
        Routes.library,
        Routes.lighthouse,
        Routes.puzzle,
        Routes.shadows,
      ]) {
        router.go(r);
        await settle(tester);
        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(router.state.matchedLocation, Routes.map, reason: r);
      }
      expect(calls, isNot(contains('SystemNavigator.pop')));
    });
  });

  group('BUG-006 puzzle 3 x 3 sur telephone', () {
    for (final size in phones) {
      testWidgets('9 pieces visibles sans defilement en '
          '${size.width.toInt()} x ${size.height.toInt()}', (tester) async {
        await pumpApp(tester, config: const AppConfig(unlockAllIslets: true));
        tester.view.physicalSize = size;
        await settle(tester, 4);
        await tester.tap(find.byKey(const Key('place-puzzle')));
        await settle(tester);
        await tester.tap(find.byKey(const Key('puzzle-size-3')));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byType(PuzzleScreen),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Scrollable && w.physics is! NeverScrollableScrollPhysics,
            ),
          ),
          findsNothing,
        );
        final screen = Offset.zero & size;
        final pieces = [
          for (var p = 0; p < 9; p++)
            tester.getRect(find.byKey(Key('tray-$p'))),
        ];
        final slot0 = tester.getRect(find.byKey(const Key('slot-0')));
        final home = tester.getRect(find.byKey(const Key('home-button')));
        for (final r in pieces) {
          expect(screen.intersect(r), r, reason: '$r hors ecran');
          expect(r.width, greaterThanOrEqualTo(AppSizes.minTouch));
          expect(r.overlaps(home), isFalse);
        }
        for (var i = 0; i < 9; i++) {
          for (var j = i + 1; j < 9; j++) {
            expect(pieces[i].overlaps(pieces[j]), isFalse);
          }
        }
        // Cases du plateau : au moins 48 dp, jamais sous le bouton maison.
        expect(slot0.width, greaterThanOrEqualTo(AppInsets.adultTouch));
        expect(slot0.overlaps(home), isFalse);
      });
    }
  });

  group('BUG-005 ombres distinctes', () {
    test('distracteurs les moins ressemblants, jamais Fuzzle et Bitsy', () {
      final rng = Random(5);
      for (var i = 0; i < 500; i++) {
        for (final n in [2, 3]) {
          final r = ShadowRound.random(rng, optionCount: n);
          expect(r.options.length, n);
          expect(r.options.toSet().length, n);
          expect(r.options, contains(r.target));
          expect(
            r.worstSimilarity,
            lessThanOrEqualTo(ShadowRound.maxSimilarity),
          );
          // Repli : Fuzzle et Bitsy (0,90) jamais ensemble.
          if (!DesignArt.enabled) {
            expect(
              r.options.contains(Monster.fuzzle) &&
                  r.options.contains(Monster.bitsy),
              isFalse,
            );
          }
        }
      }
      // Ombres de Margaux (DESIGN_ART_V1) : seuil 0,5, mesure max 0,465 ;
      // repli (illustrations teintees) : 0,85, pire manche <= 0,84.
      final worst = [
        for (var i = 0; i < 500; i++)
          ShadowRound.random(rng, optionCount: 3).worstSimilarity,
      ].reduce(max);
      expect(worst, lessThanOrEqualTo(DesignArt.enabled ? .5 : .84));
      expect(ShadowRound.maxSimilarity, DesignArt.enabled ? .5 : .85);
    });

    test('ombres de Margaux : toutes les paires sous 0,5', () {
      for (final a in Monster.values) {
        for (final b in Monster.values) {
          if (a == b) continue;
          expect(shadowSimilarity(a, b, art: true), lessThan(.5));
          expect(shadowSimilarity(a, b, art: false), greaterThan(.69));
        }
      }
    });

    testWidgets('ombres affichees : dessins de Margaux sans filtre, ou repli', (
      tester,
    ) async {
      await pumpApp(tester, config: const AppConfig(unlockAllIslets: true));
      await tester.tap(find.byKey(const Key('place-shadows')));
      await settle(tester);
      final slots = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            RegExp(r'^shadow-(fuzzle|pip|dottie|zib|bitsy)$')
                .hasMatch((w.key! as ValueKey<String>).value),
      );
      for (final e in slots.evaluate()) {
        final name = (e.widget.key! as ValueKey<String>).value.substring(7);
        final slot = find.byWidget(e.widget);
        final art = find.descendant(
          of: slot,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == DesignArt.shadow(name),
          ),
        );
        final filtered = find.descendant(
          of: slot,
          matching: find.byType(ColorFiltered),
        );
        if (DesignArt.enabled) {
          expect(art, findsOneWidget, reason: name);
          expect(filtered, findsNothing, reason: name);
        } else {
          expect(art, findsNothing, reason: name);
          expect(filtered, findsOneWidget, reason: name);
        }
      }
    });

    testWidgets('v2 : le jeu d ombres montre les poses en couleur de Margaux', (
      tester,
    ) async {
      await pumpApp(tester, config: const AppConfig(unlockAllIslets: true));
      await tester.tap(find.byKey(const Key('place-shadows')));
      await settle(tester);
      // Ombres et monstre a placer (le guide Bitsy, dans le coin, garde
      // son illustration du livre comme sur tous les ecrans).
      Iterable<String> assets() => find
          .descendant(
            of: find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('shadow-'),
            ),
            matching: find.byType(Image),
          )
          .evaluate()
          .map((e) => (e.widget as Image).image)
          .whereType<AssetImage>()
          .map((i) => i.assetName);
      String expected(String name) => DesignArt.enabled
          ? 'assets/images/shadows/color/$name.png'
          : 'assets/images/monsters/$name.webp';
      final target = tester.widget(RegExpKey.prefix('shadow-target-')).key!;
      final name = (target as ValueKey<String>).value.substring(14);
      // Le monstre a placer (lanterne).
      final lantern = find.descendant(
        of: find.byKey(Key('shadow-target-$name')),
        matching: find.byType(Image),
      );
      expect(
        ((tester.widget<Image>(lantern.first)).image as AssetImage).assetName,
        expected(name),
      );
      // Image revelee dans l'ombre une fois trouvee.
      await tester.tap(find.byKey(Key('shadow-$name')));
      await tester.pump(const Duration(milliseconds: 400));
      final revealed = find.descendant(
        of: find.byKey(Key('shadow-$name')),
        matching: find.byKey(const ValueKey('color')),
      );
      // (En repli, l'ombre filtree qui s'efface contient la meme image.)
      expect(revealed, findsWidgets);
      for (final e in revealed.evaluate()) {
        expect(
          ((e.widget as Image).image as AssetImage).assetName,
          expected(name),
        );
      }
      if (DesignArt.enabled) {
        // Jamais l'illustration du livre dans le jeu d'ombres.
        expect(assets(), isNotEmpty);
        expect(assets().where((a) => a.contains('/monsters/')), isEmpty);
        for (final m in Monster.values) {
          final f = File(DesignArt.shadowColor(m.name));
          expect(f.existsSync(), isTrue, reason: f.path);
          for (final d in ['2.0x', '3.0x']) {
            expect(
              File('assets/images/shadows/color/$d/${m.name}.png').existsSync(),
              isTrue,
            );
          }
        }
      }
      await settle(tester, 30);
    });

    testWidgets('premier niveau a 2 ombres, aide apres 2 erreurs', (
      tester,
    ) async {
      await pumpApp(tester, config: const AppConfig(unlockAllIslets: true));
      await tester.tap(find.byKey(const Key('place-shadows')));
      await settle(tester);
      expect(find.byType(ShadowsScreen), findsOneWidget);
      final target = tester.widget(RegExpKey.prefix('shadow-target-')).key!;
      final name = (target as ValueKey<String>).value.substring(14);
      final shadows = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            RegExp(r"^shadow-(fuzzle|pip|dottie|zib|bitsy)$")
                .hasMatch((w.key! as ValueKey<String>).value),
      );
      expect(shadows, findsNWidgets(2));
      final wrong = shadows.evaluate().firstWhere(
        (e) => (e.widget.key! as ValueKey<String>).value != 'shadow-$name',
      );
      expect(find.byKey(const Key('shadow-hint')), findsNothing);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byWidget(wrong.widget));
        await settle(tester);
      }
      expect(find.byKey(const Key('shadow-hint')), findsOneWidget);
    });
  });

  group('BUG-007 volumes homogenes', () {
    final levels = jsonDecode(
      File('assets/audio_mix/levels.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final files = levels['files'] as Map<String, dynamic>;
    const pads = [
      SoundEffect.beachWave,
      SoundEffect.beachSeagull,
      SoundEffect.beachShell,
      SoundEffect.beachBubbles,
      SoundEffect.beachSand,
      SoundEffect.noteDo,
      SoundEffect.noteRe,
      SoundEffect.noteMi,
      SoundEffect.noteSol,
      SoundEffect.noteLa,
    ];

    test('10 pads x 2 formats a -22 LUFS (sonie percue), crete <= -3 dBTP', () {
      expect(levels['target_momentary_max_lufs'], -22);
      expect(levels['method'], contains('loudnorm'));
      final lufs = [
        for (final v in files.values)
          ((v as Map)['momentary_max_lufs'] as num).toDouble(),
      ];
      expect(lufs.length, 20);
      for (final l in lufs) {
        expect(l, closeTo(-22, .3));
      }
      // P1-S-04 : 3 dB au plus ; mesure : 0,2 LU.
      expect(lufs.reduce(max) - lufs.reduce(min), lessThanOrEqualTo(.6));
      for (final v in files.values) {
        expect(((v as Map)['true_peak_dbtp'] as num), lessThanOrEqualTo(-3));
      }
    });

    test('les 10 pads jouent les copies de niveau, qui existent', () {
      for (final e in pads) {
        expect(e.base, startsWith('audio_mix/'));
        for (final f in AudioFormat.values) {
          final path = 'assets/${resolveAudioAsset(e.base, f)}';
          expect(File(path).existsSync(), isTrue, reason: path);
          expect(files.containsKey(path.substring(7)), isTrue, reason: path);
        }
      }
      for (final m in Monster.values) {
        expect(pads, contains(m.note));
      }
    });

    test('les sons de Shada ne sont pas modifies (sources du mix)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final v in files.values) {
        final src = ((v as Map)['source'] as Map)['file'] as String;
        expect(File(src).existsSync(), isTrue, reason: src);
        expect(src, isNot(startsWith('audio_mix/')));
      }
      expect(pubspec, contains('- assets/audio_mix/notes/note_do.ogg'));
      expect(pubspec, isNot(contains('- assets/sounds/')));
      // Le README du mix cite un test qui existe.
      final readme = File('assets/audio_mix/README.md').readAsStringSync();
      for (final m in RegExp(r'test/[\w/]+\.dart').allMatches(readme)) {
        expect(File(m[0]!).existsSync(), isTrue, reason: m[0]);
      }
    });
  });

  group('BUG-008 actions semantiques', () {
    testWidgets('entree parents et cadenas du pass : action de toucher', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester);
      final entry = tester.getSemantics(find.byKey(const Key('parents-entry')));
      expect(entry.label, S.parents);
      expect(entry.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      // Le double toucher du lecteur d'ecran ouvre la porte.
      tester.semantics.tap(find.semantics.byLabel(S.parents));
      await settle(tester);
      expect(find.byType(ParentalGateView), findsOneWidget);
      await tester.tap(find.byKey(const Key('parental-cancel')));
      await settle(tester);

      await tester.tap(find.byKey(const Key('place-cave')));
      await settle(tester);
      final locks = find.bySemanticsLabel(S.premium);
      expect(locks, findsWidgets);
      for (final e in locks.evaluate()) {
        final node = tester.getSemantics(find.byWidget(e.widget));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('BUG-010 espacement des zones de tap de la carte', () {
    for (final size in [...phones, const Size(1024, 768)]) {
      testWidgets('8 dp entre cercles en '
          '${size.width.toInt()} x ${size.height.toInt()}', (tester) async {
        await pumpApp(tester);
        tester.view.physicalSize = size;
        await settle(tester, 4);
        final circles = <(Offset, double)>[];
        for (final p in IslandPlace.values) {
          final f = find.byKey(Key('place-${p.name}'));
          final box = tester.getRect(f);
          final hit = tester.widget<CircleHitArea>(
            find.descendant(of: f, matching: find.byType(CircleHitArea)),
          );
          final d = box.shortestSide * hit.ratio;
          // Compacte (h <= 360) : tap >= 96 dp ; sinon >= 72 dp.
          final minTap = DesignArt.enabled && size.height <= 360
              ? 96.0
              : AppSizes.minTouch;
          expect(d, greaterThanOrEqualTo(minTap - 1e-6), reason: p.name);
          circles.add((box.center, d));
        }
        // HUD prioritaire : aucun cercle de tap a moins de 8 dp des boutons
        // son et parents, aucun lieu dessine dessous.
        for (final k in ['mute-button', 'parents-entry']) {
          final hud = tester.getRect(find.byKey(Key(k)));
          for (var i = 0; i < circles.length; i++) {
            final (c, d) = circles[i];
            final dx = max(max(hud.left - c.dx, 0.0), c.dx - hud.right);
            final dy = max(max(hud.top - c.dy, 0.0), c.dy - hud.bottom);
            expect(
              sqrt(dx * dx + dy * dy) - d / 2,
              greaterThanOrEqualTo(AppInsets.targetSpacing - 1e-6),
              reason: '${IslandPlace.values[i].name} / $k',
            );
            if (DesignArt.enabled) {
              final box = tester.getRect(
                find.byKey(Key('place-${IslandPlace.values[i].name}')),
              );
              expect(
                box.overlaps(hud),
                isFalse,
                reason: '${IslandPlace.values[i].name} sous $k',
              );
            }
          }
        }
        final compact = DesignArt.enabled && size.height <= 360;
        // Formats de reference de Margaux (manifeste compact v1.1).
        final reference =
            compact &&
            (size == const Size(568, 320) || size == const Size(640, 360));
        for (var i = 0; i < circles.length; i++) {
          final name = IslandPlace.values[i].name;
          final box = tester.getRect(find.byKey(Key('place-$name')));
          // Dessin entier dans la marge de 20 dp (gestes systeme).
          expect(box.left, greaterThanOrEqualTo(AppInsets.edge - 1e-6));
          expect(box.top, greaterThanOrEqualTo(AppInsets.edge - 1e-6));
          expect(box.right, lessThanOrEqualTo(size.width - AppInsets.edge));
          expect(box.bottom, lessThanOrEqualTo(size.height - AppInsets.edge));
          if (reference) {
            // Manifeste v1.1 : aucun cercle reduit.
            expect(
              circles[i].$2,
              closeTo(DesignArt.phoneCompactLayout!.tapFor(box.width), 1e-6),
              reason: '$name en $size',
            );
          }
          for (var j = i + 1; j < circles.length; j++) {
            if (reference) {
              expect(
                (circles[i].$1 - circles[j].$1).distance,
                greaterThanOrEqualTo(104),
                reason: '$name / ${IslandPlace.values[j].name} (centres)',
              );
            }
            final gap =
                (circles[i].$1 - circles[j].$1).distance -
                circles[i].$2 / 2 -
                circles[j].$2 / 2;
            expect(
              gap,
              greaterThanOrEqualTo(AppInsets.targetSpacing - 1e-6),
              reason:
                  '${IslandPlace.values[i].name} / '
                  '${IslandPlace.values[j].name}',
            );
          }
        }
      });
    }
  });

  group('A prevoir', () {
    test(
      'porte toujours active en release, desactivable en debug seulement',
      () {
        expect(resolveParentalGate(requested: false, release: true), isTrue);
        expect(resolveParentalGate(requested: true, release: true), isTrue);
        expect(resolveParentalGate(requested: false, release: false), isFalse);
        expect(
          const AppConfig(parentalGateEnabled: false).parentalGateEnabled,
          kReleaseMode,
        );
        // Un seul endroit lit PARENTAL_GATE, et seulement via la regle.
        final readers = [
          for (final f in Directory('lib').listSync(recursive: true))
            if (f is File &&
                f.path.endsWith('.dart') &&
                f.readAsStringSync().contains("'PARENTAL_GATE'"))
              f.path.replaceAll(r'\', '/'),
        ];
        expect(readers, ['lib/core/config/app_config.dart']);
        final cfg = File('lib/core/config/app_config.dart').readAsStringSync();
        expect(
          cfg,
          contains('resolveParentalGate(requested: _parentalGateRequested)'),
        );
        expect(cfg, contains('release || requested'));
      },
    );

    test(
      'PrivacyInfo.xcprivacy : aucun suivi, aucune collecte, dans Runner',
      () {
        final plist = File('ios/Runner/PrivacyInfo.xcprivacy')
            .readAsStringSync();
        expect(
          plist,
          matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')),
        );
        for (final k in [
          'NSPrivacyTrackingDomains',
          'NSPrivacyCollectedDataTypes',
        ]) {
          expect(
            plist,
            matches(RegExp('<key>$k</key>\\s*<array/>')),
            reason: k,
          );
        }
        // BUG-011 : UserDefaults (shared_preferences), raison CA92.1, seule
        // API a raison declaree.
        final apis = RegExp(
          r'<key>NSPrivacyAccessedAPIType</key>\s*<string>(\w+)</string>'
          r'\s*<key>NSPrivacyAccessedAPITypeReasons</key>\s*<array>'
          r'\s*((?:<string>[\w.]+</string>\s*)+)</array>',
        ).allMatches(plist).toList();
        expect(apis.map((m) => m[1]), [
          'NSPrivacyAccessedAPICategoryUserDefaults',
        ]);
        expect(apis.single[2], contains('<string>CA92.1</string>'));
        expect(
          RegExp('<string>[0-9A-F]{4}\\.[0-9]</string>')
              .allMatches(plist)
              .length,
          1,
        );
        final pbx = File('ios/Runner.xcodeproj/project.pbxproj')
            .readAsStringSync();
        expect(pbx, contains('PrivacyInfo.xcprivacy in Resources'));
      },
    );

    testWidgets('marges de 20 dp : bouton maison et HUD', (tester) async {
      await pumpApp(tester);
      final mute = tester.getRect(find.byKey(const Key('mute-button')));
      expect(mute.top, greaterThanOrEqualTo(AppInsets.edge));
      await tester.tap(find.byKey(const Key('place-beach')));
      await settle(tester);
      final home = tester.getRect(find.byKey(const Key('home-button')));
      expect(home.left, greaterThanOrEqualTo(AppInsets.edge));
      expect(home.top, greaterThanOrEqualTo(AppInsets.edge));
    });
  });
}

/// Recherche d'une cle par prefixe.
abstract final class RegExpKey {
  static Finder prefix(String p) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(p),
  );
}
