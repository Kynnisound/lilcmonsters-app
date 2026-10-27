// Non-regression du retest 2 QA du 27/10/2026 (build de 12:33) : BUG-015
// (porte trop facile pour un lecteur de 7 ans), BUG-016 (blocage partage
// entre onglets) et survol de la souris pour la fermeture apres 60 s.
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:seamonsters/features/map/island_map_screen.dart';
import 'package:seamonsters/features/parents/parents_screen.dart';

import 'helpers.dart';

void main() {
  group('BUG-015 porte hors de portee d un enfant de 7 ans', () {
    const trials = 400000;
    late Map<int, int> answers;
    late int times, notTimes, small;
    setUpAll(() {
      final rng = Random(15);
      answers = {};
      times = notTimes = small = 0;
      for (var i = 0; i < trials; i++) {
        final c = ParentalChallenge.random(rng);
        answers[c.answer] = (answers[c.answer] ?? 0) + 1;
        // Retest 5 (BUG-019) : plus d'addition, uniquement a x b.
        if (c.a * c.b == c.answer &&
            c.question.contains(' fois ') &&
            !c.question.contains(' plus ')) {
          times++;
        } else {
          notTimes++;
        }
        final lo = min(c.a, c.b), hi = max(c.a, c.b);
        // Tables 6 a 9 et 12, multiplicateur de 6 a 25, sans 10, 11, 20.
        if (lo < 6 || hi > 25 || (c.a > 12 && c.b > 12)) small++;
        if (ParentalChallenge.easyFactors.contains(c.a) ||
            ParentalChallenge.easyFactors.contains(c.b)) {
          small++;
        }
      }
      debugPrint(
        'BUG-015 : ${(times / trials * 100).toStringAsFixed(1)} % de '
        'multiplications, ${answers.length} reponses de '
        '${answers.keys.reduce(min)} a ${answers.keys.reduce(max)}, la plus '
        'frequente ${(answers.values.reduce(max) / trials * 100).toStringAsFixed(2)} %',
      );
    });

    // Retest 5 (BUG-019) : avant, environ 80 % de multiplications et 20 %
    // d'additions ; les additions sont retirees, 100 % de multiplications.
    test('100 % de multiplications (tables de 6 a 12)', () {
      expect(times, trials);
      expect(notTimes, 0);
      expect(small, 0);
    });

    test(
      'reponses uniformes : aucune au-dessus de 2 %, 3 chiffres au plus',
      () {
        expect(answers.length, ParentalChallenge.answers.length);
        expect(answers.values.reduce(max) / trials, lessThan(.02));
        expect(answers.values.reduce(min) / trials, greaterThan(.012));
        expect(ParentalChallenge.minAnswer, 36);
        expect(ParentalChallenge.maxAnswer, 300);
        expect(
          '${ParentalChallenge.maxAnswer}'.length,
          ParentalGateForm.maxDigits,
        );
      },
    );

    test('impossible avec les deux facteurs de 6 a 12 (27 produits)', () {
      final p = {
        for (var a = 6; a <= 12; a++)
          for (var b = 6; b <= 12; b++) a * b,
      };
      expect(p.length, 27);
      expect(1 / p.length, greaterThan(.02));
    });

    testWidgets('reponse a 3 chiffres saisie sur le pave', (tester) async {
      await pumpApp(tester, challenge: () => const ParentalChallenge(12, 19));
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(
        tester
            .widget<ParentalQuestionText>(
              find.byKey(const Key('parental-question')),
            )
            .question,
        'Combien font douze fois dix-neuf\u00a0?',
      );
      await answerGate(tester, '228');
      expect(find.byType(ParentsScreen), findsOneWidget);
    });
  });

  group('BUG-016 blocage partage entre onglets', () {
    ParentalAccess tab(ParentalLockStore store, DateTime Function() now) =>
        ParentalAccess(now: now, readGateEnabled: () => true, store: store);

    test('onglet ouvert avant le blocage : bloque, et ne l efface pas', () {
      var now = DateTime(2026, 10, 27, 12);
      final store = MemoryParentalLockStore();
      final a = tab(store, () => now);
      final b = tab(store, () => now); // ouvert avant les erreurs de A
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      // B relit le stockage avant de verifier : bloque.
      expect(b.isLocked, isTrue);
      expect(b.lockRemaining, const Duration(minutes: 1));
      final form = ParentalGateForm(b, () => const ParentalChallenge(6, 7))
        ..type(1);
      expect(form.canSubmit, isFalse);
      // Une erreur enregistree par B ne leve pas le blocage.
      b.recordFailure();
      expect(store.record.lockedUntil, now.add(const Duration(minutes: 1)));
      expect(store.record.lockouts, 1);
      // A recharge : toujours bloque.
      now = now.add(const Duration(seconds: 5));
      expect(tab(store, () => now).isLocked, isTrue);
      expect(a.isLocked, isTrue);
    });

    test('ecriture ancienne ou ignorante du blocage : reecrite', () {
      final now = DateTime(2026, 10, 27, 12);
      final store = MemoryParentalLockStore();
      final a = tab(store, () => now);
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      final rev = store.record.revision;
      // Ancien build, ou onglet qui n'a pas relu : efface le blocage.
      store.writeFromOtherTab(
        ParentalLockRecord(failures: 1, revision: rev + 1),
      );
      expect(a.isLocked, isTrue);
      expect(store.record.lockedUntil, now.add(const Duration(minutes: 1)));
      expect(store.record.revision, greaterThan(rev + 1));
      // Ecriture plus ancienne (revision inferieure) : ignoree.
      store.writeFromOtherTab(const ParentalLockRecord(revision: 1));
      expect(a.isLocked, isTrue);
      expect(store.record.lockedUntil, isNotNull);
    });

    test('le blocage le plus strict gagne', () {
      var now = DateTime(2026, 10, 27, 12);
      final store = MemoryParentalLockStore();
      final a = tab(store, () => now);
      final b = tab(store, () => now);
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      // Fin du premier blocage, puis B se bloque au palier 2 (5 min).
      now = now.add(const Duration(minutes: 2));
      for (var i = 0; i < 3; i++) {
        b.recordFailure();
      }
      expect(store.record.lockouts, 2);
      expect(a.lockRemaining, const Duration(minutes: 5));
      expect(a.lockouts, 2);
    });

    test('bonne reponse dans un onglet, blocage fini : les deux repartent', () {
      var now = DateTime(2026, 10, 27, 12);
      final store = MemoryParentalLockStore();
      final a = tab(store, () => now);
      final b = tab(store, () => now);
      for (var i = 0; i < 3; i++) {
        a.recordFailure();
      }
      now = now.add(const Duration(minutes: 2));
      expect(b.isLocked, isFalse);
      b.recordSuccess(42);
      expect(a.isLocked, isFalse);
      expect(a.lockouts, 0);
      expect(a.failures, 0);
    });

    testWidgets('evenement storage : la porte ouverte se bloque aussitot', (
      tester,
    ) async {
      final store = MemoryParentalLockStore();
      final h = await pumpApp(tester, lockStore: store);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      expect(find.byKey(const Key('parental-key-4')), findsOneWidget);
      // L'autre onglet se bloque pendant que celui-ci affiche la porte.
      store.writeFromOtherTab(
        ParentalLockRecord(
          lockouts: 1,
          lockedUntil: h.now.add(const Duration(minutes: 1)),
          revision: store.record.revision + 5,
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('parental-locked')), findsOneWidget);
      expect(find.byKey(const Key('parental-key-4')), findsNothing);
    });
  });

  group('Espace parents : survol de la souris', () {
    testWidgets('le survol compte comme une action (ordinateur)', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      await passGate(tester);
      expect(find.byType(ParentsScreen), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(600, 400));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 40));
        await mouse.moveTo(Offset(600, 400 + 10.0 * (i + 1)));
        await tester.pump();
      }
      // 120 s de lecture a la souris, sans clic : toujours ouvert.
      expect(find.byType(ParentsScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      await settle(tester);
      expect(find.byType(ParentsScreen), findsNothing);
      expect(find.byType(IslandMapScreen), findsOneWidget);
      await mouse.removePointer();
    });
  });
}
