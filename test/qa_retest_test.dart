// Non-regression du retest QA du 27/10/2026 (build de 12:05) : BUG-011 a
// BUG-014, restes de BUG-001 et BUG-007 (voir qa_regression_test.dart), et
// fermeture de l'espace parents apres 60 s d'inactivite.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/app/bootstrap.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:seamonsters/core/router/app_router.dart';
import 'package:seamonsters/core/router/routes.dart';
import 'package:seamonsters/features/lighthouse/lighthouse_screen.dart';
import 'package:seamonsters/features/map/island_map_screen.dart';
import 'package:seamonsters/features/parents/parents_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Trois mauvaises reponses : la porte se bloque.
Future<void> lockGate(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('parents-entry')));
  await settle(tester);
  for (final a in ['1', '2', '3']) {
    await answerGate(tester, a);
  }
  expect(find.byType(ParentalGateView), findsNothing);
}

Future<void> openParents(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('parents-entry')));
  await settle(tester);
  await passGate(tester);
  expect(find.byType(ParentsScreen), findsOneWidget);
}

/// Ce que le moteur web envoie quand le navigateur ressort une entree de
/// son historique (Precedent / Suivant, evenement popstate).
Future<void> browserHistory(WidgetTester tester, RouteInformation info) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', {
        'location': info.uri.toString(),
        'state': info.state,
      }),
    ),
    (_) {},
  );
  await settle(tester);
}

void main() {
  group('BUG-011 blocage enregistre sur l appareil', () {
    ParentalAccess access(
      ParentalLockStore store,
      DateTime Function() now, [
      Duration Function()? mono,
    ]) => ParentalAccess(
      now: now,
      readGateEnabled: () => true,
      store: store,
      monotonic: mono,
    );

    test('compteur, palier et heure de fin survivent a une relance', () {
      var now = DateTime(2026, 10, 27, 12);
      final store = MemoryParentalLockStore();
      var a = access(store, () => now);
      a.recordFailure();
      a.recordFailure();
      // Relance : 2 erreurs deja comptees, la 3e bloque.
      a = access(store, () => now);
      expect(a.failures, 2);
      expect(a.recordFailure(), isTrue);
      expect(store.record.lockouts, 1);
      expect(store.record.lockedUntil, now.add(const Duration(minutes: 1)));
      // Relance pendant le blocage : toujours bloque.
      now = now.add(const Duration(seconds: 30));
      a = access(store, () => now);
      expect(a.isLocked, isTrue);
      expect(a.lockRemaining, const Duration(seconds: 30));
      // Apres la fin : debloque, mais le palier reste (5 min ensuite).
      now = now.add(const Duration(seconds: 31));
      a = access(store, () => now);
      expect(a.isLocked, isFalse);
      a
        ..recordFailure()
        ..recordFailure()
        ..recordFailure();
      a = access(store, () => now);
      expect(a.lockRemaining, const Duration(minutes: 5));
      // Une reussite remet tout a zero, y compris sur l'appareil.
      now = now.add(const Duration(minutes: 6));
      access(store, () => now).recordSuccess();
      expect(store.record.sameState(const ParentalLockRecord()), isTrue);
    });

    test('horloge reculee : jamais debloque, jamais plus que le palier', () {
      var now = DateTime(2026, 10, 27, 12);
      final store = MemoryParentalLockStore();
      var a = access(store, () => now);
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      // L'enfant recule l'heure d'un jour, puis relance l'appli.
      now = now.subtract(const Duration(days: 1));
      a = access(store, () => now);
      expect(a.isLocked, isTrue);
      expect(a.lockRemaining, const Duration(minutes: 1));
      // L'heure de fin est recalee sur la nouvelle horloge.
      expect(store.record.lockedUntil, now.add(const Duration(minutes: 1)));
      now = now.add(const Duration(seconds: 59));
      expect(access(store, () => now).isLocked, isTrue);
      now = now.add(const Duration(seconds: 2));
      expect(access(store, () => now).isLocked, isFalse);
      // Annee 1970 : meme chose.
      a = access(store, () => now);
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      now = DateTime(1970, 1, 2);
      expect(
        access(store, () => now).lockRemaining,
        const Duration(minutes: 5),
      );
    });

    test('horloge reculee ou avancee pendant que l appli tourne', () {
      var now = DateTime(2026, 10, 27, 12);
      var mono = const Duration(hours: 3);
      final store = MemoryParentalLockStore();
      final a = access(store, () => now, () => mono);
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      // 20 s reelles, puis l'heure recule d'une heure : il reste 40 s.
      mono += const Duration(seconds: 20);
      now = now
          .add(const Duration(seconds: 20))
          .subtract(const Duration(hours: 1));
      expect(a.lockRemaining, const Duration(seconds: 40));
      expect(store.record.lockedUntil, now.add(const Duration(seconds: 40)));
      // Puis l'heure avance d'un jour : il reste 30 s apres 10 s reelles.
      mono += const Duration(seconds: 10);
      now = now.add(const Duration(days: 1, seconds: 10));
      expect(a.lockRemaining, const Duration(seconds: 30));
      // Relance apres ce changement d'heure : toujours 30 s.
      expect(
        access(store, () => now).lockRemaining,
        const Duration(seconds: 30),
      );
      mono += const Duration(seconds: 31);
      now = now.add(const Duration(seconds: 31));
      expect(a.isLocked, isFalse);
    });

    test(
      'shared_preferences : ecrit sur l appareil et relu a la relance',
      () async {
        SharedPreferences.setMockInitialValues({});
        var prefs = await SharedPreferences.getInstance();
        final now = DateTime(2026, 10, 27, 12, 0, 0);
        var a = access(PrefsParentalLockStore(prefs), () => now);
        for (var i = 0; i < 3; i++) {
          a.recordFailure();
        }
        a.recordFailure();
        // Relance : nouveau processus, preferences relues depuis le disque.
        SharedPreferences.resetStatic();
        prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt(PrefsParentalLockStore.failuresKey), 1);
        expect(prefs.getInt(PrefsParentalLockStore.lockoutsKey), 1);
        expect(
          prefs.getInt(PrefsParentalLockStore.lockedUntilKey),
          now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
        );
        a = access(PrefsParentalLockStore(prefs), () => now);
        expect(a.isLocked, isTrue);
        expect(a.failures, 1);
        // Seules ces quatre cles, aucune donnee personnelle.
        expect(prefs.getKeys(), PrefsParentalLockStore.keys);
        // Le demarrage branche bien les preferences sur la porte.
        final c = ProviderContainer(overrides: buildOverrides(prefs: prefs));
        addTearDown(c.dispose);
        expect(
          c.read(parentalLockStoreProvider),
          isA<PrefsParentalLockStore>(),
        );
        expect(
          c.read(parentalAccessProvider).isLocked,
          isFalse,
        ); // horloge reelle
      },
    );

    testWidgets('relancer l appli ne leve pas le blocage', (tester) async {
      final store = MemoryParentalLockStore();
      var h = await pumpApp(tester, lockStore: store);
      await lockGate(tester);
      final now = h.now;
      // Relance : nouveau conteneur, meme appareil.
      await tester.pumpWidget(const SizedBox());
      h = await pumpApp(tester, lockStore: store);
      h.now = now.add(const Duration(seconds: 12));
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-locked')), findsOneWidget);
      expect(find.byKey(const Key('parental-key-4')), findsNothing);
      await tester.tap(find.byKey(const Key('parental-cancel')));
      await settle(tester);
      // Le phare aussi.
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      expect(find.byKey(const Key('parental-locked')), findsOneWidget);
    });
  });

  group('BUG-012 espace des reponses', () {
    test('aucune reponse fixe ne passe plus de 2 % du temps', () {
      // Exact : la reponse est tiree uniformement parmi 61 produits.
      final n = ParentalChallenge.answers.length;
      expect(n, 61);
      expect(1 / n, lessThan(.02));
      // Mesure : 200 000 questions.
      final rng = Random(12);
      final count = <int, int>{};
      const trials = 200000;
      for (var i = 0; i < trials; i++) {
        final c = ParentalChallenge.random(rng);
        count[c.answer] = (count[c.answer] ?? 0) + 1;
        expect(c.question, isNot(matches(RegExp(r'\d'))));
      }
      final worst = count.values.reduce(max) / trials;
      debugPrint(
        'BUG-012 : ${count.length} reponses, la plus frequente '
        '${(worst * 100).toStringAsFixed(2)} %',
      );
      expect(count.length, 61);
      expect(worst, lessThan(.02));
      // Avant : 36 sortait 3 fois sur 36 (8,3 %).
    });

    test('repeter toujours la meme reponse : <= 2 % par validation', () {
      final rng = Random(13);
      for (final fixed in [36, 72, 42, 120, 99, 24]) {
        var opened = 0, tries = 0;
        for (var t = 0; t < 4000; t++) {
          final access = ParentalAccess(
            now: () => DateTime(2026),
            readGateEnabled: () => true,
          );
          final form = ParentalGateForm(
            access,
            () => ParentalChallenge.random(rng),
          );
          for (var i = 0; i < ParentalAccess.maxFailures; i++) {
            for (final d in '$fixed'.split('')) {
              form.type(int.parse(d));
            }
            tries++;
            final step = form.submit();
            if (step == GateStep.success) {
              opened++;
              break;
            }
            if (step == GateStep.lockedOut) break;
          }
        }
        expect(opened / tries, lessThanOrEqualTo(.02), reason: '$fixed');
      }
    });

    test('jamais reposer la reponse saisie ou vue juste avant', () {
      final rng = Random(14);
      final access = ParentalAccess(
        now: () => DateTime(2026),
        readGateEnabled: () => true,
      );
      for (var t = 0; t < 2000; t++) {
        final form = ParentalGateForm(
          access,
          () => ParentalChallenge.random(rng),
        );
        final seen = form.challenge.answer;
        expect(seen, isNot(access.lastAnswer));
        form
          ..type(4)
          ..type(2);
        final step = form.submit();
        if (step == GateStep.wrong) {
          expect(form.challenge.answer, isNot(42));
          expect(form.challenge.answer, isNot(seen));
        }
        // Un adulte repond juste : la reponse ne revient pas tout de suite.
        for (final d in '${form.challenge.answer}'.split('')) {
          form.type(int.parse(d));
        }
        if (form.submit() == GateStep.success) {
          expect(access.lastAnswer, isNotNull);
        }
        access.recordSuccess(access.lastAnswer);
      }
    });

    test('nombres en lettres et ecritures valides', () {
      expect(frenchNumber(21), 'vingt et un');
      expect(frenchNumber(71), 'soixante et onze');
      expect(frenchNumber(77), 'soixante-dix-sept');
      expect(frenchNumber(80), 'quatre-vingts');
      expect(frenchNumber(81), 'quatre-vingt-un');
      expect(frenchNumber(99), 'quatre-vingt-dix-neuf');
      expect(frenchNumber(12), 'douze');
      for (final v in ParentalChallenge.answers) {
        for (final c in ParentalChallenge.writings(v)) {
          expect(c.answer, v);
        }
      }
      // Retest 5 (BUG-019) : plus d'addition, l'exemple devient a x b.
      expect(
        const ParentalChallenge(7, 23).question,
        'Combien font sept fois vingt-trois\u00a0?',
      );
    });
  });

  group('BUG-013 historique du navigateur', () {
    testWidgets('cas A : croix puis Precedent : pas d espace parents', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      final router = h.container.read(routerProvider);
      await openParents(tester);
      final parentsEntry = router.routeInformationProvider.value;
      expect(parentsEntry.uri.path, Routes.parents);
      await tester.tap(find.byKey(const Key('parents-close')));
      await settle(tester);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      await browserHistory(tester, parentsEntry);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(h.access.parentsSpaceOpen, isFalse);
    });

    testWidgets('cas B : Precedent puis Suivant : pas d espace parents', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      final router = h.container.read(routerProvider);
      final mapEntry = router.routeInformationProvider.value;
      await openParents(tester);
      final parentsEntry = router.routeInformationProvider.value;
      await browserHistory(tester, mapEntry);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(h.access.parentsSpaceOpen, isFalse);
      await browserHistory(tester, parentsEntry);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
    });

    testWidgets('Precedent juste apres la croix, pendant la transition', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      final router = h.container.read(routerProvider);
      await openParents(tester);
      final parentsEntry = router.routeInformationProvider.value;
      await tester.tap(find.byKey(const Key('parents-close')));
      await tester.pump(const Duration(milliseconds: 50));
      await browserHistory(tester, parentsEntry);
      expect(find.byType(ParentsScreen), findsNothing);
    });

    testWidgets('ancienne entree d historique (push) : ecran refuse', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      final router = h.container.read(routerProvider);
      // Entree poussee par les builds d'avant (adresse « / »).
      unawaited(router.push(Routes.parents));
      await settle(tester);
      expect(find.text('ESPACE PARENTS'), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(h.access.parentsSpaceOpen, isFalse);
    });

    testWidgets('phare : Precedent puis Suivant redemande la porte', (
      tester,
    ) async {
      final h = await pumpApp(tester);
      final router = h.container.read(routerProvider);
      final mapEntry = router.routeInformationProvider.value;
      await tester.tap(find.byKey(const Key('place-lighthouse')));
      await settle(tester);
      await passGate(tester);
      expect(find.byType(LighthouseScreen), findsOneWidget);
      final lighthouseEntry = router.routeInformationProvider.value;
      expect(lighthouseEntry.uri.path, Routes.lighthouse);
      await browserHistory(tester, mapEntry);
      await browserHistory(tester, lighthouseEntry);
      expect(find.byType(LighthouseScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
    });

    test('garde du routeur sur les deux ecrans proteges', () {
      expect(protectedRoutes.map((r) => r.$2), [
        Routes.parents,
        Routes.lighthouse,
      ]);
    });
  });

  group('BUG-014 tailles de la porte', () {
    for (final size in const [
      Size(568, 320),
      Size(667, 375),
      Size(1280, 720),
    ]) {
      testWidgets('48 dp porte ouverte et bloquee, 8 dp entre touches en '
          '${size.width.toInt()} x ${size.height.toInt()}', (tester) async {
        await pumpApp(tester);
        tester.view.physicalSize = size;
        await settle(tester);
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester);
        final cancel = tester.getRect(find.byKey(const Key('parental-cancel')));
        expect(cancel.height, greaterThanOrEqualTo(48), reason: 'Annuler');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        // Pave : 8 dp au moins entre deux touches voisines.
        Rect key(String k) => tester.getRect(find.byKey(Key('parental-$k')));
        const grid = [
          ['key-1', 'key-2', 'key-3'],
          ['key-4', 'key-5', 'key-6'],
          ['key-7', 'key-8', 'key-9'],
          ['erase', 'key-0', 'submit'],
        ];
        for (var r = 0; r < grid.length; r++) {
          for (var c = 0; c < 3; c++) {
            final k = key(grid[r][c]);
            expect(k.height, greaterThanOrEqualTo(48));
            expect(k.width, greaterThanOrEqualTo(48));
            if (c < 2) {
              expect(
                key(grid[r][c + 1]).left - k.right,
                greaterThanOrEqualTo(8),
              );
            }
            if (r < grid.length - 1) {
              expect(
                key(grid[r + 1][c]).top - k.bottom,
                greaterThanOrEqualTo(8),
              );
            }
          }
        }
        // Porte bloquee : « Fermer ».
        for (final a in ['1', '2', '3']) {
          await answerGate(tester, a);
        }
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester);
        expect(find.byKey(const Key('parental-locked')), findsOneWidget);
        final close = tester.getRect(find.byKey(const Key('parental-cancel')));
        expect(close.height, greaterThanOrEqualTo(48), reason: 'Fermer');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }
  });

  group('Espace parents : fermeture apres 60 s d inactivite', () {
    testWidgets('ferme a 60 s sans toucher, porte redemandee', (tester) async {
      final h = await pumpApp(tester);
      await openParents(tester);
      await tester.pump(const Duration(seconds: 59));
      expect(find.byType(ParentsScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      expect(h.access.parentsSpaceOpen, isFalse);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-question')), findsOneWidget);
    });

    testWidgets('chaque toucher relance le minuteur', (tester) async {
      await pumpApp(tester);
      await openParents(tester);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 50));
        await tester.tapAt(const Offset(640, 600));
        await tester.pump();
      }
      // 200 s ouvert, jamais 60 s sans toucher.
      expect(find.byType(ParentsScreen), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump(const Duration(seconds: 59));
      expect(find.byType(ParentsScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
    });
  });
}
