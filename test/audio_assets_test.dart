import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/audio/sound_effect.dart';

/// Chemins relatifs a `assets/` pour chaque format attendu.
List<String> _variants(String base) => base.endsWith('.wav')
    ? [base]
    : [for (final f in AudioFormat.values) resolveAudioAsset(base, f)];

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  /// Declare dans pubspec.yaml : le fichier lui-meme (les sons sont
  /// declares un par un, voir plus bas) ou son dossier.
  void expectDeclaredAndPresent(String path) {
    expect(File('assets/$path').existsSync(), isTrue, reason: path);
    final dir = 'assets/${path.substring(0, path.lastIndexOf('/') + 1)}';
    final declared =
        RegExp(
          '- (path: )?${RegExp.escape('assets/$path')}\$',
          multiLine: true,
        ).hasMatch(pubspec) ||
        pubspec.contains('- $dir\n');
    expect(declared, isTrue, reason: 'assets/$path dans pubspec.yaml');
  }

  test('chaque son et chaque ambiance existe en .ogg et .m4a', () {
    for (final e in SoundEffect.values) {
      _variants(e.base).forEach(expectDeclaredAndPresent);
    }
    for (final a in Ambience.values) {
      _variants(a.base).forEach(expectDeclaredAndPresent);
    }
  });

  test('chaque chemin audio ecrit dans lib/ existe', () {
    final literal = RegExp(r"""['"]((?:audio|sounds)/[A-Za-z0-9_/.\-]+)['"]""");
    final found = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in literal.allMatches(f.readAsStringSync())) {
        found.add(m.group(1)!);
      }
    }
    expect(found, isNotEmpty);
    for (final path in found) {
      _variants(path).forEach(expectDeclaredAndPresent);
    }
  });

  test('chaque note generee (assets/sounds) a sa copie de niveau jouee', () {
    // Les .wav sont les sources de tool/normalize_pads.py (BUG-007).
    final used = {for (final e in SoundEffect.values) e.base};
    for (final f in Directory('assets/sounds').listSync()) {
      final name = f.uri.pathSegments.last.replaceAll('.wav', '');
      expect(used, contains('audio_mix/notes/$name'), reason: name);
    }
  });

  test('format : m4a sur iOS et macOS, ogg ailleurs', () {
    expect(audioFormatFor(TargetPlatform.iOS), AudioFormat.m4a);
    expect(audioFormatFor(TargetPlatform.macOS), AudioFormat.m4a);
    expect(audioFormatFor(TargetPlatform.android), AudioFormat.ogg);
    expect(audioFormatFor(TargetPlatform.windows), AudioFormat.ogg);
    expect(
      resolveAudioAsset('audio/ui/ui_tap', AudioFormat.m4a),
      'audio/ui/ui_tap.m4a',
    );
    expect(resolveAudioAsset('sounds/note_do.wav'), 'sounds/note_do.wav');
  });

  test('.m4a reserves a iOS, macOS et web : ni APK ni AAB', () {
    final audio = [
      for (final d in Directory('assets').listSync(recursive: true))
        if (d is File && RegExp(r'\.(ogg|m4a)$').hasMatch(d.path)) d.path,
    ];
    expect(audio, isNotEmpty);
    for (final f in audio) {
      final dir = f.substring(0, f.lastIndexOf('/') + 1);
      // Aucun dossier audio declare en bloc : il ramenerait les .m4a.
      expect(pubspec, isNot(contains('- $dir\n')), reason: dir);
      if (f.endsWith('.m4a')) {
        expect(
          pubspec,
          contains('- path: $f\n      platforms: [ios, macos, web]\n'),
          reason: f,
        );
      } else {
        expect(
          RegExp(
            '^    - ${RegExp.escape(f)}\$',
            multiLine: true,
          ).hasMatch(pubspec),
          isTrue,
          reason: f,
        );
      }
    }
  });
}
