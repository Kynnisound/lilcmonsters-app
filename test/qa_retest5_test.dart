// Retest 5 QA du 27/10/2026 : BUG-019 (« Autre question » remis a 3 en
// fermant puis rouvrant la porte ; additions), BUG-020 (orientation
// paysage retiree du manifeste par flutter_native_splash), BUG-021
// (question coupee au trait d'union en 568 x 320), et nom de l'appli en
// bas de l'ecran de demarrage.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';

import 'helpers.dart';
import 'qa_retest4_test.dart' show loadAppFonts;

void main() {
  group('BUG-019 uniquement des multiplications', () {
    test('aucune addition sur 10 000 tirages', () {
      final rng = Random(2019);
      final count = <int, int>{};
      for (var i = 0; i < 10000; i++) {
        final c = ParentalChallenge.random(rng);
        count[c.answer] = (count[c.answer] ?? 0) + 1;
        expect(c.question, contains(' fois '), reason: c.question);
        expect(c.question, isNot(contains(' plus ')), reason: c.question);
        expect(c.answer, c.a * c.b);
        expect(ParentalChallenge.tables, contains(c.a), reason: c.question);
        expect(ParentalChallenge.multipliers, contains(c.b));
        for (final f in ParentalChallenge.easyFactors) {
          expect(c.a, isNot(f));
          expect(c.b, isNot(f));
        }
      }
      // Toutes les reponses sortent, aucune au-dessus de 2 %.
      expect(count.length, ParentalChallenge.answers.length);
      expect(count.values.reduce(max) / 10000, lessThan(.025));
      expect(1 / ParentalChallenge.answers.length, lessThan(.02));
    });

    test('toute ecriture possible est une multiplication', () {
      for (final v in ParentalChallenge.answers) {
        final w = ParentalChallenge.writings(v);
        expect(w, isNotEmpty);
        for (final c in w) {
          expect(c.a * c.b, v);
          expect(c.question, contains(' fois '));
        }
      }
    });
  });

  group('BUG-019 « Autre question » enregistre avec l etat de la porte', () {
    ParentalAccess open(
      MemoryParentalLockStore store,
      DateTime Function() now,
    ) => ParentalAccess(now: now, readGateEnabled: () => true, store: store);

    test('fermer puis rouvrir la porte ne rend pas les changements', () {
      final store = MemoryParentalLockStore();
      final now = DateTime(2026, 10, 27, 15);
      final rng = Random(5);
      final access = open(store, () => now);
      var form = ParentalGateForm(access, () => ParentalChallenge.random(rng));
      for (var i = 0; i < ParentalGateForm.maxSkips; i++) {
        expect(form.canSkip, isTrue);
        form.skip();
      }
      expect(form.canSkip, isFalse);
      expect(store.record.skipsUsed, 3);
      // Reouverture de la porte (meme session).
      for (var i = 0; i < 5; i++) {
        form = ParentalGateForm(access, () => ParentalChallenge.random(rng));
        expect(form.skipsLeft, 0);
        expect(form.canSkip, isFalse);
        final q = form.challenge.question;
        form.skip();
        expect(form.challenge.question, q);
      }
      // Relance de l'appli : le compteur est relu dans le stockage.
      final relaunched = open(store, () => now);
      expect(relaunched.skipsLeft, 0);
      // Une reussite remet 3 changements.
      relaunched.recordSuccess(42);
      expect(store.record.skipsUsed, 0);
      expect(
        ParentalGateForm(
          relaunched,
          () => ParentalChallenge.random(rng),
        ).skipsLeft,
        3,
      );
    });

    test('la fin d un blocage remet les changements, pas le blocage', () {
      final store = MemoryParentalLockStore();
      var now = DateTime(2026, 10, 27, 15);
      final access = open(store, () => now);
      final form = ParentalGateForm(access, () => const ParentalChallenge(7, 8))
        ..skip()
        ..skip();
      expect(access.skipsLeft, 1);
      for (var i = 0; i < ParentalAccess.maxFailures; i++) {
        access.recordFailure();
      }
      expect(access.isLocked, isTrue);
      expect(form.canSkip, isFalse);
      expect(access.skipsUsed, 2); // pas de remise a zero pendant le blocage
      now = now.add(const Duration(minutes: 1, seconds: 1));
      expect(access.isLocked, isFalse);
      expect(access.skipsLeft, 3);
      expect(store.record.skipsUsed, 0);
    });

    test('partage entre onglets (meme cle, numero d ecriture)', () {
      final store = MemoryParentalLockStore();
      final now = DateTime(2026, 10, 27, 15);
      final a = open(store, () => now), b = open(store, () => now);
      for (var i = 0; i < 3; i++) {
        expect(a.recordSkip(), isTrue);
      }
      expect(a.recordSkip(), isFalse);
      // L'onglet B relit l'etat avant chaque verification.
      expect(b.skipsLeft, 0);
      expect(store.record.revision, greaterThan(0));
      // Evenement storage : un autre onglet a reussi la porte.
      store.writeFromOtherTab(
        ParentalLockRecord(revision: store.record.revision + 1),
      );
      expect(a.skipsLeft, 3);
      expect(b.skipsLeft, 3);
      // Ecriture plus ancienne : ignoree.
      a.recordSkip();
      store.writeFromOtherTab(const ParentalLockRecord(revision: 1));
      expect(a.skipsUsed, 1);
    });

    testWidgets('appli : 3 changements, Annuler, rouvrir : bouton grise', (
      tester,
    ) async {
      var n = 0;
      final h = await pumpApp(
        tester,
        challenge: () => ParentalChallenge(7, 13 + n++ % 6),
      );
      Future<void> openGate() async {
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester);
      }

      final other = find.byKey(const Key('parental-other'));
      await openGate();
      for (var i = 0; i < 3; i++) {
        await tester.tap(other);
        await settle(tester);
      }
      expect(tester.widget<TextButton>(other).onPressed, isNull);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('parental-cancel')));
        await settle(tester);
        await openGate();
        expect(
          tester.widget<TextButton>(other).onPressed,
          isNull,
          reason: 'reouverture $i',
        );
      }
      expect(h.lockStore.load().skipsUsed, 3);
    });
  });

  group('BUG-020 orientation paysage', () {
    test('AndroidManifest : sensorLandscape sur MainActivity', () {
      final xml = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      final activity = RegExp(
        r'<activity[^>]*android:name="\.MainActivity"[^>]*>',
      ).firstMatch(xml);
      expect(activity, isNotNull);
      expect(
        activity!.group(0),
        contains('android:screenOrientation="sensorLandscape"'),
      );
    });

    test('flutter_native_splash la reecrit a chaque generation', () {
      final yaml = File('flutter_native_splash.yaml').readAsStringSync();
      expect(yaml, contains('android_screen_orientation: sensorLandscape'));
    });
  });

  group('ecran de demarrage : nom de l appli en bas', () {
    const res = 'android/app/src/main/res';

    test('Android 12+, Android ancien et iOS', () {
      for (final f in ['values-v31', 'values-night-v31']) {
        expect(
          File('$res/$f/styles.xml').readAsStringSync(),
          contains(
            'android:windowSplashScreenBrandingImage">@drawable/android12branding',
          ),
          reason: f,
        );
      }
      for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(File('$res/drawable-$d/branding.png').existsSync(), isTrue);
        expect(
          File('$res/drawable-$d-v31/android12branding.png').existsSync(),
          isTrue,
        );
      }
      for (final f in ['drawable', 'drawable-v21', 'drawable-night-v21']) {
        final bg = File('$res/$f/launch_background.xml').readAsStringSync();
        expect(bg, contains('android:gravity="bottom"'), reason: f);
        expect(bg, contains('@drawable/branding'), reason: f);
      }
      final story = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
          .readAsStringSync();
      expect(story, contains('image="BrandingImage"'));
      for (final f in ['', '@2x', '@3x']) {
        expect(
          File(
            'ios/Runner/Assets.xcassets/BrandingImage.imageset/BrandingImage$f.png',
          ).existsSync(),
          isTrue,
        );
      }
      final yaml = File('flutter_native_splash.yaml').readAsStringSync();
      expect(yaml, contains('branding_mode: bottom'));
    });
  });

  group('BUG-021 question sans coupure au trait d union', () {
    setUpAll(loadAppFonts);

    // Questions les plus longues, avec des mots a trait d'union.
    const longest = [
      ParentalChallenge(12, 24),
      ParentalChallenge(7, 17),
      ParentalChallenge(9, 19),
      ParentalChallenge(8, 22),
      ParentalChallenge(12, 18),
    ];

    for (final c in longest) {
      testWidgets('568 x 320 : ${c.question}', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = previous);

        await pumpApp(tester, challenge: () => c);
        tester.view.physicalSize = const Size(568, 320);
        await settle(tester);
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester);

        final q = find.byKey(const Key('parental-question'));
        expect(q, findsOneWidget);
        // Chaque mot, trait d'union compris, est un seul bloc d'une ligne.
        final words = find.descendant(of: q, matching: find.byType(Text));
        expect(words, findsNWidgets(c.words.length));
        final lineHeight = tester.getSize(words.first).height;
        for (final e in words.evaluate()) {
          final text = (e.widget as Text).data!;
          final para = e.renderObject! as RenderParagraph;
          expect(para.didExceedMaxLines, isFalse, reason: text);
          expect(para.size.height, closeTo(lineHeight, 1), reason: text);
        }
        expect(
          find.descendant(of: q, matching: find.textContaining('-')),
          findsWidgets,
        );
        // Dans l'ecran, sans debordement.
        final r = tester.getRect(q);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(568));
        expect(r.bottom, lessThanOrEqualTo(320));
        final overflow = errors.where(
          (e) => e.exceptionAsString().contains('overflowed'),
        );
        expect(overflow, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
