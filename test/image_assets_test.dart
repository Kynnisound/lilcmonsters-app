// Passe 4 QA : « Could not decompress image » sur l'emulateur. Chaque PNG et
// WebP embarque doit etre lisible partout, Android 7 compris
// (tool/check_images.py fait le meme controle, avec Pillow et dwebp).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const maxSide = 4096;

/// Dossiers d'assets declares, plus leurs variantes 2.0x et 3.0x.
List<File> embeddedImages() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final block = pubspec.split('\n  assets:\n')[1].split('\n  fonts:')[0];
  final dirs = RegExp(
    r'^\s+- (assets/\S+/)\s*$',
    multiLine: true,
  ).allMatches(block).map((m) => m[1]!);
  final out = <String, File>{};
  for (final d in dirs) {
    final dir = Directory(d);
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync()) {
      final variant =
          e is Directory &&
          RegExp(r'^\d+(\.\d+)?x$').hasMatch(
            e.uri.pathSegments.reversed.firstWhere((s) => s.isNotEmpty),
          );
      final files = variant ? e.listSync() : [e];
      for (final f in files) {
        if (f is File && RegExp(r'\.(png|webp)$').hasMatch(f.path)) {
          out[f.path] = f;
        }
      }
    }
  }
  return out.values.toList()..sort((a, b) => a.path.compareTo(b.path));
}

int u32(Uint8List b, int o) => ByteData.sublistView(b).getUint32(o);

/// Problemes d'un PNG : profondeur, entrelacement, APNG, profil ICC.
List<String> pngProblems(Uint8List b) {
  const sig = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < 8; i++) {
    if (b[i] != sig[i]) return ['signature PNG absente'];
  }
  final p = <String>[];
  final w = u32(b, 16), h = u32(b, 20), depth = b[24], interlace = b[28];
  if (depth != 8) p.add('$depth bits par canal');
  if (interlace != 0) p.add('entrelace');
  if (w > maxSide || h > maxSide) p.add('${w}x$h');
  var pos = 8;
  while (pos + 8 <= b.length) {
    final n = u32(b, pos);
    final type = String.fromCharCodes(b.sublist(pos + 4, pos + 8));
    if (type == 'acTL') p.add('APNG');
    if (type == 'iCCP') {
      final name = String.fromCharCodes(
        b.sublist(pos + 8, pos + 8 + n).takeWhile((c) => c != 0),
      );
      if (!name.toLowerCase().contains('srgb')) p.add('profil ICC $name');
    }
    if (type == 'IEND') break;
    pos += 12 + n;
  }
  return p;
}

/// Problemes d'un WebP : animation, profil ICC (en-tete VP8X).
List<String> webpProblems(Uint8List b) {
  if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(b.sublist(8, 12)) != 'WEBP') {
    return ['signature WebP absente'];
  }
  final p = <String>[];
  if (String.fromCharCodes(b.sublist(12, 16)) == 'VP8X') {
    final flags = b[20];
    if (flags & 0x02 != 0) p.add('anime');
    if (flags & 0x20 != 0) p.add('profil ICC');
  }
  return p;
}

void main() {
  final images = embeddedImages();

  test('toutes les images embarquees sont trouvees', () {
    expect(images.length, greaterThan(150));
    expect(images.where((f) => f.path.contains('/3.0x/')), isNotEmpty);
  });

  test('PNG 8 bits non entrelaces, sans profil exotique ; WebP fixes', () {
    final bad = <String>[];
    for (final f in images) {
      final b = f.readAsBytesSync();
      final p = f.path.endsWith('.png') ? pngProblems(b) : webpProblems(b);
      if (p.isNotEmpty) bad.add('${f.path} : ${p.join(', ')}');
    }
    expect(bad, isEmpty);
  });

  testWidgets('decodage complet par le moteur Flutter, 4096 px au plus', (
    tester,
  ) async {
    final bad = <String>[];
    var decoded = 0;
    await tester.runAsync(() async {
      for (final f in images) {
        try {
          final codec = await ui.instantiateImageCodec(f.readAsBytesSync());
          expect(codec.frameCount, 1, reason: f.path);
          final frame = await codec.getNextFrame();
          final im = frame.image;
          if (im.width > maxSide || im.height > maxSide) {
            bad.add('${f.path} : ${im.width}x${im.height}');
          }
          decoded++;
          im.dispose();
          codec.dispose();
        } catch (e) {
          bad.add('${f.path} : $e');
        }
      }
    });
    expect(bad, isEmpty);
    expect(decoded, images.length);
  });
}
