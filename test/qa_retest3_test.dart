// Demandes du 27/10/2026 (13:39) : BUG-017 (signature release), bouton
// « Autre question » de la porte, multiplicateur, bruitages d'origine hors
// du bundle, sauvegarde Android desactivee.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/parental/parental_gate.dart';

import 'helpers.dart';

void main() {
  group('porte : Autre question', () {
    test("ne compte pas comme une erreur et garde le compteur d'erreurs", () {
      final access = ParentalAccess(
        now: () => DateTime(2026),
        readGateEnabled: () => true,
      );
      final rng = Random(17);
      final form = ParentalGateForm(access, () => ParentalChallenge.random(rng))
        ..type(1);
      expect(form.submit(), GateStep.wrong);
      expect(access.failures, 1);
      for (var i = 0; i < ParentalGateForm.maxSkips; i++) {
        final before = form.challenge.answer;
        form
          ..type(3)
          ..skip();
        expect(form.entry, isEmpty);
        expect(form.wrong, isFalse);
        expect(form.challenge.answer, isNot(before));
        expect(access.failures, 1);
      }
      form.type(1);
      expect(form.submit(), GateStep.wrong);
      expect(access.failures, 2);
    });

    testWidgets('bouton de 48 dp, nouvelle question, compteur garde', (
      tester,
    ) async {
      var n = 0;
      const pool = [
        ParentalChallenge(6, 7),
        ParentalChallenge(8, 9),
        ParentalChallenge(7, 13),
      ];
      final h = await pumpApp(tester, challenge: () => pool[n++ % pool.length]);
      for (final size in const [Size(1280, 720), Size(568, 320)]) {
        tester.view.physicalSize = size;
        await tester.tap(find.byKey(const Key('parents-entry')));
        await settle(tester);
        final other = find.byKey(const Key('parental-other'));
        expect(other, findsOneWidget);
        expect(find.text('Autre question'), findsOneWidget);
        expect(tester.getSize(other).height, greaterThanOrEqualTo(48));
        await answerGate(tester, '1');
        expect(h.access.failures, 1);
        final q = tester
            .widget<ParentalQuestionText>(
              find.byKey(const Key('parental-question')),
            )
            .question;
        await tester.ensureVisible(other);
        await tester.tap(other);
        await settle(tester);
        expect(
          tester
              .widget<ParentalQuestionText>(
                find.byKey(const Key('parental-question')),
              )
              .question,
          isNot(q),
        );
        expect(h.access.failures, 1);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const Key('parental-cancel')));
        await tester.tap(find.byKey(const Key('parental-cancel')));
        await settle(tester);
        await passGateReset(tester, h);
      }
    });
  });

  test('multiplicateur : 61 reponses, 1,6 % chacune (BUG-019)', () {
    expect(ParentalChallenge.answers.length, 61);
    expect(1 / ParentalChallenge.answers.length, lessThan(.02));
  });

  group('BUG-017 signature release', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    test('lit android/key.properties, ignore par Git', () {
      expect(gradle, contains('rootProject.file("key.properties")'));
      for (final k in [
        'storeFile',
        'storePassword',
        'keyAlias',
        'keyPassword',
      ]) {
        expect(gradle, contains('"$k"'));
      }
      expect(
        File('android/.gitignore').readAsLinesSync(),
        contains('key.properties'),
      );
      // La cle d'envoi reste hors du projet : au plus un lien symbolique vers
      // un dossier de secrets (jamais lu par les tests).
      const kp = 'android/key.properties';
      if (FileSystemEntity.typeSync(kp, followLinks: false) !=
          FileSystemEntityType.notFound) {
        expect(FileSystemEntity.isLinkSync(kp), isTrue);
        expect(
          File(Link(kp).resolveSymbolicLinksSync()).absolute.path,
          isNot(startsWith(Directory.current.absolute.path)),
        );
      }
      expect(
        Directory('android')
            .listSync(recursive: true)
            .where(
              (f) => f.path.endsWith('.jks') || f.path.endsWith('.keystore'),
            ),
        isEmpty,
      );
    });

    test('sans cle : echec clair, cle debug seulement sur option QA', () {
      expect(gradle, contains('throw GradleException('));
      expect(gradle, contains('allowDebugSigning'));
      expect(
        gradle,
        isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
      );
      expect(
        gradle,
        contains('allowDebugSigning -> signingConfigs.getByName("debug")'),
      );
    });
  });

  test('Android : aucune sauvegarde ni transfert des donnees', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml')
        .readAsStringSync();
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
  });

  test("bruitages d'origine de la plage hors du bundle, jamais references", () {
    const sfx = ['bubbles', 'sand', 'seagull', 'shell', 'wave_splash'];
    final inAssets = [
      for (final f in Directory('assets/audio/beach').listSync())
        f.uri.pathSegments.last,
    ]..sort();
    expect(inAssets, ['beach_ambience_loop.m4a', 'beach_ambience_loop.ogg']);
    for (final n in sfx) {
      for (final ext in ['ogg', 'm4a']) {
        expect(File('audio_sources/beach/beach_$n.$ext').existsSync(), isTrue);
        expect(
          File('assets/audio_mix/beach/beach_$n.$ext').existsSync(),
          isTrue,
        );
      }
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('audio_sources')));
    final old = RegExp(r'audio/beach/beach_(bubbles|sand|seagull|shell|wave)');
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        expect(old.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
    }
  });
}

/// Laisse la porte rouverte proprement pour la taille suivante.
Future<void> passGateReset(WidgetTester tester, TestHarness h) async {
  h.access.recordSuccess(42);
  await settle(tester);
}
