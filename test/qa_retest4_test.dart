// Passe 4 QA du 27/10/2026 : BUG-019 (« Autre question » illimite, facteurs
// dix et onze) et « Autre question » coupe a 45 px en 568 x 320 (BUG-014).
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';

import 'helpers.dart';

/// Vraies polices de l'appli : les mesures de mise en page ne valent rien
/// avec la police carree des tests.
Future<void> loadAppFonts() async {
  const fonts = {
    'LuckiestGuy': ['assets/fonts/LuckiestGuy-Regular.ttf'],
    'Baloo2': [
      'assets/fonts/Baloo2-Medium.ttf',
      'assets/fonts/Baloo2-Bold.ttf',
      'assets/fonts/Baloo2-ExtraBold.ttf',
    ],
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

/// Question facile pour un enfant de 7 ans : table de 2 a 5, de 10, de 11
/// ou de 20, ou toute addition (retest 5 : il n'y en a plus).
bool isEasy(ParentalChallenge c) {
  if (c.question.contains(' plus ') || c.a * c.b != c.answer) return true;
  bool easy(int f) => f <= 5 || f == 10 || f == 11 || f == 20;
  return easy(c.a) || easy(c.b);
}

void main() {
  group('BUG-019 porte : pas de question facile, 3 changements au plus', () {
    test('aucun facteur 10, 11 ou 20, ni table de 2 a 5', () {
      for (final f in ParentalChallenge.easyFactors) {
        expect(ParentalChallenge.tables, isNot(contains(f)));
        expect(ParentalChallenge.multipliers, isNot(contains(f)));
      }
      expect(ParentalChallenge.tables.reduce(min), greaterThanOrEqualTo(6));
      expect(
        ParentalChallenge.multipliers.reduce(min),
        greaterThanOrEqualTo(6),
      );
      for (final v in ParentalChallenge.answers) {
        for (final c in ParentalChallenge.writings(v)) {
          expect(isEasy(c), isFalse, reason: c.question);
        }
      }
    });

    test('reponse la plus frequente sous 2 % (mesure, 300 000 tirages)', () {
      final rng = Random(19);
      final count = <int, int>{};
      const trials = 300000;
      for (var i = 0; i < trials; i++) {
        final c = ParentalChallenge.random(rng);
        count[c.answer] = (count[c.answer] ?? 0) + 1;
      }
      final top = count.values.reduce(max) / trials;
      debugPrint(
        'BUG-019 : ${count.length} reponses, la plus frequente '
        '${(top * 100).toStringAsFixed(2)} %',
      );
      expect(top, lessThan(.02));
    });

    test('10 touchers : question facile presque jamais (< 1 %)', () {
      // Pire cas : chaque toucher donne une nouvelle question (Autre
      // question, ou Annuler puis rouvrir la porte).
      final rng = Random(10);
      const runs = 20000;
      var hit = 0;
      for (var r = 0; r < runs; r++) {
        final access = ParentalAccess(
          now: () => DateTime(2026),
          readGateEnabled: () => true,
        );
        var form = ParentalGateForm(
          access,
          () => ParentalChallenge.random(rng),
        );
        var easy = isEasy(form.challenge);
        for (var t = 0; t < 10 && !easy; t++) {
          if (form.canSkip) {
            form.skip();
          } else {
            form = ParentalGateForm(
              access,
              () => ParentalChallenge.random(rng),
            );
          }
          easy = isEasy(form.challenge);
        }
        if (easy) hit++;
      }
      debugPrint('BUG-019 : question facile en 10 touchers : $hit / $runs');
      expect(hit / runs, lessThan(.01));
    });

    test('3 changements entre deux reussites, puis plus rien', () {
      final access = ParentalAccess(
        now: () => DateTime(2026),
        readGateEnabled: () => true,
      );
      final rng = Random(3);
      var form = ParentalGateForm(access, () => ParentalChallenge.random(rng));
      for (var i = 0; i < 3; i++) {
        expect(form.canSkip, isTrue);
        form.skip();
      }
      expect(form.canSkip, isFalse);
      final q = form.challenge.question;
      form.skip();
      expect(form.challenge.question, q);
      // Retest 5 (BUG-019) : rouvrir la porte ne rend AUCUN changement
      // (avant : de nouveau 3 a chaque ouverture).
      form = ParentalGateForm(access, () => ParentalChallenge.random(rng));
      expect(form.skipsLeft, 0);
      expect(form.canSkip, isFalse);
      // Une reussite les rend.
      access.recordSuccess(form.challenge.answer);
      form = ParentalGateForm(access, () => ParentalChallenge.random(rng));
      expect(form.skipsLeft, 3);
    });

    testWidgets('bouton grise apres 3 changements', (tester) async {
      var n = 0;
      await pumpApp(
        tester,
        challenge: () => ParentalChallenge(6, 7 + n++ % 12),
      );
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      final other = find.byKey(const Key('parental-other'));
      for (var i = 0; i < 3; i++) {
        expect(tester.widget<TextButton>(other).onPressed, isNotNull);
        await tester.tap(other);
        await settle(tester);
      }
      expect(tester.widget<TextButton>(other).onPressed, isNull);
    });
  });

  group('568 x 320 : Annuler et Autre question entiers (BUG-014)', () {
    setUpAll(loadAppFonts);

    for (final size in const [
      Size(568, 320),
      Size(640, 360),
      Size(1280, 720),
    ]) {
      testWidgets('$size, avant et apres une erreur, vraies polices', (
        tester,
      ) async {
        await pumpApp(tester, challenge: () => const ParentalChallenge(7, 17));
        tester.view.physicalSize = size;
        await settle(tester);
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester);
        void check(String when) {
          for (final k in [
            'parental-cancel',
            'parental-other',
            'parental-key-0',
            'parental-submit',
          ]) {
            final r = tester.getRect(find.byKey(Key(k)));
            expect(r.height, greaterThanOrEqualTo(48), reason: '$k $when');
            expect(r.top, greaterThanOrEqualTo(0), reason: '$k $when');
            expect(
              r.bottom,
              lessThanOrEqualTo(size.height),
              reason: '$k $when : $r',
            );
          }
        }

        check('a l\'ouverture');
        await answerGate(tester, '1');
        expect(find.byKey(const Key('parental-wrong')), findsOneWidget);
        check('apres une erreur');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
