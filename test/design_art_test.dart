import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/content/design_art.dart';
import 'package:seamonsters/features/map/island_place.dart';

void main() {
  test('assets de Margaux references presents (1x, 2.0x, 3.0x)', () {
    final paths = <String>[
      DesignArt.phoneLayout.image,
      if (DesignArt.tablet43Layout != null) DesignArt.tablet43Layout!.image,
      if (DesignArt.phoneCompactLayout != null)
        DesignArt.phoneCompactLayout!.image,
      for (final m in ['fuzzle', 'pip', 'dottie', 'zib', 'bitsy'])
        DesignArt.shadow(m),
      DesignArt.home,
      DesignArt.soundOn,
      DesignArt.soundOff,
      DesignArt.parentalGate,
      DesignArt.padlockBadge,
      DesignArt.beachShell,
      for (final p in IslandPlace.values) ...[
        DesignArt.place(p.artId, locked: false),
        DesignArt.place(p.artId, locked: true),
        DesignArt.icon(p.iconArt),
      ],
    ];
    for (final path in paths) {
      final i = path.lastIndexOf('/');
      for (final v in ['', '2.0x/', '3.0x/']) {
        final f = '${path.substring(0, i + 1)}$v${path.substring(i + 1)}';
        expect(File(f).existsSync(), isTrue, reason: f);
      }
    }
    for (final l in [
      DesignArt.phoneLayout,
      DesignArt.tablet43Layout!,
      DesignArt.phoneCompactLayout!,
    ]) {
      for (final p in IslandPlace.values) {
        expect(l.spots.containsKey(p.artId), isTrue, reason: p.name);
      }
    }
  });

  test('design_map_layouts.g.dart = regeneration du manifeste', () {
    // Valeurs du manifeste du 27/10/2026 (zones HUD corrigees par Margaux).
    expect(DesignArt.phoneLayout.hud, const Rect.fromLTRB(632, 0, 812, 112));
    expect(
      DesignArt.tablet43Layout!.hud,
      const Rect.fromLTRB(844, 0, 1024, 112),
    );
    final c = DesignArt.phoneCompactLayout!;
    expect(c.frame, const Size(640, 360));
    expect(c.hud, const Rect.fromLTRB(468, 0, 640, 112));
    expect(
      [c.placeBase, c.placeMin, c.placeMax, c.minTap],
      [120, 100, 200, 96],
    );
    expect(DesignArt.phoneLayout.placeMin, 120);
    // Le fichier genere ne differe pas d'une regeneration.
    final before = File('lib/core/content/design_map_layouts.g.dart')
        .readAsStringSync();
    final r = Process.runSync('python3', ['tool/sync_design_manifest.py']);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      File('lib/core/content/design_map_layouts.g.dart').readAsStringSync(),
      before,
    );
  });
}
