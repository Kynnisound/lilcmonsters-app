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

  void expectDeclaredAndPresent(String path) {
    expect(File('assets/$path').existsSync(), isTrue, reason: path);
    final dir = 'assets/${path.substring(0, path.lastIndexOf('/') + 1)}';
    expect(pubspec, contains('- $dir'), reason: '$dir dans pubspec.yaml');
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

  test('aucun son genere inutilise dans assets/sounds', () {
    final used = {for (final e in SoundEffect.values) 'assets/${e.base}'};
    for (final f in Directory('assets/sounds').listSync()) {
      final p = f.path.replaceAll('\\', '/');
      expect(used, contains(p), reason: '$p non utilise');
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
}
