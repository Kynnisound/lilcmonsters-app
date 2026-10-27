// GENERE par tool/sync_design_manifest.py depuis design/assets/manifest.json.
// Ne pas modifier a la main : relancer le script.
// ignore_for_file: unnecessary_nullable_for_final_variable_declarations
import 'dart:ui';

import 'design_art.dart';

/// Carte telephone (manifest.json > map).
const designPhoneLayout = MapLayout(
  image: 'assets/images/map/map_island_morning.png',
  frame: Size(812.0, 375.0),
  spots: {
    'cave': Offset(165.0, 112.0),
    'forest': Offset(328.0, 150.0),
    'lighthouse': Offset(486.0, 100.0),
    'beach': Offset(150.0, 272.0),
    'library': Offset(318.0, 290.0),
    'shadow': Offset(610.0, 176.0),
    'islets': Offset(662.0, 300.0),
  },
  guideFoot: Offset(480.0, 346.0),
  hud: Rect.fromLTRB(690.0, 0.0, 812.0, 100.0),
);

/// Carte tablette 4:3 (manifest.json > map.layouts.tablet43). Nulle si
/// absente du manifeste : la carte telephone sert alors partout.
const MapLayout? designTablet43Layout = MapLayout(
  image: 'assets/images/map/map_island_morning_tablet43.png',
  frame: Size(1024.0, 768.0),
  spots: {
    'cave': Offset(256.5, 302.6),
    'forest': Offset(429.3, 349.0),
    'lighthouse': Offset(596.8, 288.0),
    'beach': Offset(240.6, 497.8),
    'library': Offset(418.7, 519.8),
    'shadow': Offset(728.2, 380.7),
    'islets': Offset(783.4, 532.0),
  },
  guideFoot: Offset(590.4, 577.1),
  hud: Rect.fromLTRB(864.0, 0.0, 1024.0, 112.0),
);
