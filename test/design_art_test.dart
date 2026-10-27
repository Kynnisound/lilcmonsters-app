import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:seamonsters/core/content/design_art.dart';
import 'package:seamonsters/features/map/island_place.dart';

void main() {
  test('assets de Margaux references presents (1x, 2.0x, 3.0x)', () {
    final paths = <String>[
      DesignArt.map,
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
    for (final p in IslandPlace.values) {
      expect(DesignArt.mapSpots.containsKey(p.artId), isTrue, reason: p.name);
    }
  });
}
