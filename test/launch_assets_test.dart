// BUG-018 : icone et ecran de demarrage de Lil C Monsters (visuels de
// travail de Margaux, design/assets/launch/, validation de David attendue).
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String md5Of(String path) =>
    md5.convert(File(path).readAsBytesSync()).toString();

void main() {
  const res = 'android/app/src/main/res';

  test("plus l'icone Flutter par defaut (Android et iOS)", () {
    // md5 des fichiers du gabarit Flutter 3.47.8.
    const flutterTemplate = {
      '$res/mipmap-xxxhdpi/ic_launcher.png': '57838d52c318faff743130c3fcfae0c6',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
          'c785f8932297af4acd5f5ccb7630f01c',
    };
    flutterTemplate.forEach((path, md5) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(md5Of(path), isNot(md5), reason: path);
    });
  });

  test('icone adaptative : premier plan sans marge, monochrome Android 13', () {
    final xml = File('$res/mipmap-anydpi-v26/ic_launcher.xml')
        .readAsStringSync();
    expect(xml, contains('@drawable/ic_launcher_background'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('@drawable/ic_launcher_monochrome'));
    expect(xml, contains('android:inset="0%"'));
    expect(xml, isNot(contains('android:inset="16%"')));
    for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      for (final f in ['background', 'foreground', 'monochrome']) {
        expect(
          File('$res/drawable-$d/ic_launcher_$f.png').existsSync(),
          isTrue,
          reason: '$d $f',
        );
      }
    }
  });

  test('ecran de demarrage lagon #3FC1B0, Android 12 avec le logo', () {
    final v31 = File('$res/values-v31/styles.xml').readAsStringSync();
    expect(v31, contains('windowSplashScreenBackground">#3FC1B0'));
    expect(v31, contains('@drawable/android12splash'));
    expect(
      File('$res/drawable-xxxhdpi/android12splash.png').existsSync(),
      isTrue,
    );
    final bg = File('$res/drawable-v21/launch_background.xml')
        .readAsStringSync();
    expect(bg, contains('@drawable/splash'));
    final story = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
        .readAsStringSync();
    expect(story, contains('LaunchImage'));
    expect(story, contains('LaunchBackground'));
  });

  test('sources de travail hors du bundle, copies conformes de design/', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('- assets/launch/')));
    for (final f in [
      'ios/app_icon_1024.png',
      'android/ic_launcher_foreground.png',
      'android/ic_launcher_background.png',
      'android/ic_launcher_monochrome.png',
      'splash/android12/splash_android12_1152.png',
    ]) {
      final copy = File('assets/launch/$f');
      final orig = File('design/assets/launch/$f');
      expect(copy.existsSync(), isTrue, reason: f);
      if (orig.existsSync()) {
        expect(md5Of(copy.path), md5Of(orig.path), reason: f);
      }
    }
    final icons = File('flutter_launcher_icons.yaml').readAsStringSync();
    expect(icons, contains('adaptive_icon_foreground_inset: 0'));
    final splash = File('flutter_native_splash.yaml').readAsStringSync();
    expect(splash, contains('color: "#3FC1B0"'));
    expect(splash, contains('splash_android12_1152.png'));
    expect(splash, contains('android_12:'));
  });
}
