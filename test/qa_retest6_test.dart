// Retest 6 QA du 27/10/2026 : BUG-019 (question en cours enregistree avec
// l'etat de la porte), BUG-023 (nom de l'appli sur Pip au demarrage).
// BUG-022 (CanvasKit et police depuis gstatic) se verifie sur le build web :
// tool/check_web_build.sh.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

ParentalAccess tab(ParentalLockStore store, DateTime Function() now) =>
    ParentalAccess(now: now, readGateEnabled: () => true, store: store);

String q(ParentalGateForm f) => f.challenge.question;

void main() {
  group('BUG-019 la question en cours survit a la fermeture', () {
    test('20 reouvertures : toujours la meme question', () {
      final store = MemoryParentalLockStore();
      final rng = Random(61);
      final access = tab(store, () => DateTime(2026, 10, 27, 17));
      final first = q(
        ParentalGateForm(access, () => ParentalChallenge.random(rng)),
      );
      for (var i = 0; i < 20; i++) {
        final f = ParentalGateForm(access, () => ParentalChallenge.random(rng));
        expect(q(f), first, reason: 'ouverture $i');
      }
      // Relance de l'appli : relue dans le stockage.
      final relaunched = tab(store, () => DateTime(2026, 10, 27, 17));
      expect(
        q(ParentalGateForm(relaunched, () => ParentalChallenge.random(rng))),
        first,
      );
      expect(store.record.hasQuestion, isTrue);
    });

    test('erreur : nouvelle question, gardee a la reouverture, skips '
        'inchanges', () {
      final store = MemoryParentalLockStore();
      final access = tab(store, () => DateTime(2026));
      final rng = Random(62);
      for (var t = 0; t < 200; t++) {
        final f = ParentalGateForm(access, () => ParentalChallenge.random(rng));
        if (t.isOdd) f.skip(); // un changement deja utilise
        final skips = store.record.skipsUsed;
        final before = f.challenge;
        // Mauvaise reponse : une reponse fausse a 2 ou 3 chiffres.
        final typed = before.answer == 99 ? 98 : 99;
        for (final d in '$typed'.split('')) {
          f.type(int.parse(d));
        }
        expect(f.submit(), GateStep.wrong);
        final after = f.challenge;
        expect(after.answer, isNot(before.answer));
        expect(after.answer, isNot(typed));
        expect(store.record.questionA, after.a);
        expect(store.record.questionB, after.b);
        expect(store.record.skipsUsed, skips, reason: 'pas un changement');
        // Reouverture : la question d'apres l'erreur.
        expect(
          q(ParentalGateForm(access, () => ParentalChallenge.random(rng))),
          after.question,
        );
        // Relance : idem.
        expect(
          q(
            ParentalGateForm(
              tab(store, () => DateTime(2026)),
              () => ParentalChallenge.random(rng),
            ),
          ),
          after.question,
        );
        access.recordSuccess(); // compteur d'erreurs a zero, pas de blocage
      }
    });

    test('Autre question la change, et la nouvelle reste', () {
      final store = MemoryParentalLockStore();
      final access = tab(store, () => DateTime(2026));
      final rng = Random(63);
      final f = ParentalGateForm(access, () => ParentalChallenge.random(rng));
      final before = f.challenge;
      f.skip();
      final after = f.challenge;
      expect(after.answer, isNot(before.answer));
      for (var i = 0; i < 20; i++) {
        expect(
          ParentalGateForm(
            access,
            () => ParentalChallenge.random(rng),
          ).challenge.question,
          after.question,
        );
      }
      expect(store.record.questionA, after.a);
      expect(store.record.questionB, after.b);
    });

    test('bonne reponse : nouvelle question a l ouverture suivante', () {
      final access = tab(MemoryParentalLockStore(), () => DateTime(2026));
      final rng = Random(64);
      for (var t = 0; t < 200; t++) {
        final f = ParentalGateForm(access, () => ParentalChallenge.random(rng));
        final c = f.challenge;
        for (final d in '${c.answer}'.split('')) {
          f.type(int.parse(d));
        }
        expect(f.submit(), GateStep.success);
        final next = ParentalGateForm(
          access,
          () => ParentalChallenge.random(rng),
        ).challenge;
        // Jamais la reponse qui vient d'etre donnee (BUG-012).
        expect(next.answer, isNot(c.answer));
      }
    });

    test('blocage : meme question pendant, nouvelle question a la fin', () {
      final store = MemoryParentalLockStore();
      var now = DateTime(2026, 10, 27, 17);
      final access = tab(store, () => now);
      var n = 0;
      const pool = [
        ParentalChallenge(7, 13),
        ParentalChallenge(8, 17),
        ParentalChallenge(9, 23),
      ];
      ParentalChallenge next() => pool[n++ % pool.length];
      final f = ParentalGateForm(access, next);
      for (var i = 0; i < ParentalAccess.maxFailures; i++) {
        f.type(1);
        f.submit();
      }
      expect(access.isLocked, isTrue);
      // La 3e erreur bloque sans changer de question ; elle change a la fin.
      final before = q(f);
      expect(q(ParentalGateForm(access, next)), before);
      now = now.add(const Duration(minutes: 1, seconds: 1));
      expect(access.isLocked, isFalse);
      expect(store.record.hasQuestion, isFalse);
      expect(q(ParentalGateForm(access, next)), isNot(before));
    });

    test('onglets : meme cle, numero d ecriture, evenement storage', () {
      final store = MemoryParentalLockStore();
      final now = DateTime(2026, 10, 27, 17);
      final rng = Random(65);
      final a = tab(store, () => now), b = tab(store, () => now);
      final fa = ParentalGateForm(a, () => ParentalChallenge.random(rng));
      final fb = ParentalGateForm(b, () => ParentalChallenge.random(rng));
      expect(q(fb), q(fa));
      fa.skip();
      expect(q(fb), q(fa)); // B relit l'etat avant d'afficher
      // Ecriture d'un autre onglet (plus recente) : adoptee.
      final rev = store.record.revision;
      store.writeFromOtherTab(
        ParentalLockRecord(
          skipsUsed: 2,
          questionA: 12,
          questionB: 23,
          revision: rev + 1,
        ),
      );
      expect(q(fa), 'Combien font douze fois vingt-trois\u00a0?');
      expect(q(fb), q(fa));
      expect(a.skipsLeft, 1);
      // Ecriture plus ancienne : ignoree.
      store.writeFromOtherTab(
        const ParentalLockRecord(questionA: 6, questionB: 6, revision: 1),
      );
      expect(q(fa), 'Combien font douze fois vingt-trois\u00a0?');
    });

    test('valeur enregistree hors des tables : ignoree, nouvelle question', () {
      final store = MemoryParentalLockStore(
        const ParentalLockRecord(questionA: 10, questionB: 2, revision: 3),
      );
      final access = tab(store, () => DateTime(2026));
      final c = ParentalGateForm(
        access,
        () => const ParentalChallenge(8, 19),
      ).challenge;
      expect(c.question, const ParentalChallenge(8, 19).question);
    });

    test('mobile : shared_preferences garde la question', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      addTearDown(SharedPreferences.resetStatic);
      final rng = Random(66);
      final first = q(
        ParentalGateForm(
          tab(PrefsParentalLockStore(prefs), () => DateTime(2026)),
          () => ParentalChallenge.random(rng),
        ),
      );
      expect(prefs.getInt(PrefsParentalLockStore.questionAKey), isNonZero);
      final again = q(
        ParentalGateForm(
          tab(PrefsParentalLockStore(prefs), () => DateTime(2026)),
          () => ParentalChallenge.random(rng),
        ),
      );
      expect(again, first);
    });

    testWidgets('appli : Annuler puis rouvrir 20 fois, meme question', (
      tester,
    ) async {
      var n = 0;
      await pumpApp(
        tester,
        challenge: () => ParentalChallenge(7, 13 + n++ % 6),
      );
      String shown() => tester
          .widget<ParentalQuestionText>(
            find.byKey(const Key('parental-question')),
          )
          .question;
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester);
      final first = shown();
      for (var i = 0; i < 20; i++) {
        await tester.tap(find.byKey(const Key('parental-cancel')));
        await settle(tester, 4);
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester, 4);
        expect(shown(), first, reason: 'ouverture $i');
      }
      await tester.tap(find.byKey(const Key('parental-other')));
      await settle(tester, 4);
      final second = shown();
      expect(second, isNot(first));
      await tester.tap(find.byKey(const Key('parental-cancel')));
      await settle(tester, 4);
      await tester.tap(find.byKey(const Key('parents-entry')));
      await settle(tester, 4);
      expect(shown(), second);
    });
  });

  group('BUG-023 nom en bas du splash, sans toucher Pip', () {
    const res = 'android/app/src/main/res';

    /// Lignes (haut, bas) des pixels non transparents, en pixels.
    Future<(int, int, int)> alphaRows(String path) async {
      final codec = await ui.instantiateImageCodec(
        File(path).readAsBytesSync(),
      );
      final img = (await codec.getNextFrame()).image;
      final data = (await img.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      ))!;
      final px = Uint8List.view(data.buffer);
      var top = img.height, bottom = -1;
      for (var y = 0; y < img.height; y++) {
        for (var x = 0; x < img.width; x++) {
          if (px[(y * img.width + x) * 4 + 3] > 0) {
            top = min(top, y);
            bottom = max(bottom, y);
            break;
          }
        }
      }
      return (top, bottom + 1, img.height);
    }

    testWidgets('ecart positif partout (meme modele que la QA)', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // Logos tels qu'ils sont livres (xxxhdpi = @4x, 288 dp).
        final (_, b12, h12) = await alphaRows(
          '$res/drawable-xxxhdpi/android12splash.png',
        );
        final (_, bOld, hOld) = await alphaRows(
          '$res/drawable-xxxhdpi/splash.png',
        );
        final (_, bIos, hIos) = await alphaRows(
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
        );
        final (lt, _, lh) = await alphaRows(
          '$res/drawable-xxxhdpi/branding.png',
        );
        double below(int b, int h, double scale) => (b - h / 2) / scale;
        final pip12 = below(b12, h12, 4);
        final pipOld = below(bOld, hOld, 4);
        final pipIos = below(bIos, hIos, 3);
        final lettersTop = lt / 4; // dans le cadre de 80 dp
        expect(lh / 4, 80);
        double gap(double h, double pip, double margin) =>
            (h - margin - 80 + lettersTop) - (h / 2 + pip);
        final cases = {
          'Android 12 640 x 360 (60 dp)': gap(360, pip12, 60),
          'Android 12 915 x 412 (60 dp)': gap(412, pip12, 60),
          'Android 13 640 x 360 (2 dp)': gap(360, pip12, 2),
          'Android 11 640 x 360': gap(360, pipOld, 0),
          'Android 11 533 x 320': gap(320, pipOld, 0),
          'iPhone SE 568 x 320': gap(320, pipIos, 0),
          'iPhone 812 x 375 (zone sure 21)': gap(375, pipIos, 21),
        };
        debugPrint('BUG-023 : $cases');
        cases.forEach((k, v) => expect(v, greaterThan(8), reason: k));
      });
    });

    test('config : logos recalcules, sans branding_bottom_padding', () {
      final yaml = File('flutter_native_splash.yaml').readAsStringSync();
      expect(
        yaml,
        contains('assets/launch/splash/bug023/splash_logo_1152.png'),
      );
      expect(
        yaml,
        contains('assets/launch/splash/bug023/splash_android12_1152.png'),
      );
      expect(
        yaml,
        isNot(
          matches(RegExp(r'^\s*branding_bottom_padding:', multiLine: true)),
        ),
      );
      expect(
        File('$res/values-v31/styles.xml').readAsStringSync(),
        contains('windowSplashScreenBrandingImage'),
      );
    });

    test('iOS : nom au bas de la zone sure (barre d accueil)', () {
      final s = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
          .readAsStringSync();
      final guide = RegExp(r'<viewLayoutGuide key="safeArea" id="([^"]+)"/>')
          .firstMatch(s);
      expect(
        guide,
        isNotNull,
        reason: 'python3 tool/splash_bug023.py storyboard',
      );
      final id = guide!.group(1);
      expect(
        s,
        contains(
          '<constraint firstItem="$id" firstAttribute="bottom" '
          'secondItem="Uyq-Kz-ftE" secondAttribute="bottom"',
        ),
        reason:
            'relancer python3 tool/splash_bug023.py storyboard apres '
            'flutter_native_splash:create',
      );
      expect(s, contains('Safe area layout guides'));
      expect(
        s,
        isNot(
          contains(
            '<constraint firstAttribute="bottom" secondItem="Uyq-Kz-ftE"',
          ),
        ),
      );
    });

    test('icone de l appli inchangee (octet pour octet)', () {
      const icons = {
        '$res/mipmap-xxxhdpi/ic_launcher.png':
            '37e5b3d36bca91eb60fdbd71459b8c97',
        '$res/drawable-xxxhdpi/ic_launcher_foreground.png':
            'e95242a1b32b65b16a94f350b0b8fdfa',
        '$res/drawable-xxxhdpi/ic_launcher_background.png':
            '20964343074f861ea28ce550591ea702',
        '$res/drawable-xxxhdpi/ic_launcher_monochrome.png':
            '0fca8d06cd65d402a09576a97ce97865',
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
            'f3c02ea50b9b2b1a936fb2a296daf0cb',
      };
      icons.forEach((path, sum) {
        expect(
          md5.convert(File(path).readAsBytesSync()).toString(),
          sum,
          reason: path,
        );
      });
    });
  });
}
