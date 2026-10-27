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
  hud: Rect.fromLTRB(632.0, 0.0, 812.0, 112.0),
  placeBase: 140.0,
  placeMin: 120.0,
  placeMax: 200.0,
  minTap: 0.0,
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
  hud: Rect.fromLTRB(844.0, 0.0, 1024.0, 112.0),
  placeBase: 140.0,
  placeMin: 120.0,
  placeMax: 200.0,
  minTap: 0.0,
);

/// Carte compacte des petits telephones (manifest.json >
/// map.layouts.phone_compact). Nulle si absente.
/// Selection (manifest.json > map.layout_selection) : height <= 360 dp -> phone_compact; else width/height < 1.7 -> tablet43; else phone
const MapLayout? designPhoneCompactLayout = MapLayout(
  image: 'assets/images/map/map_island_morning_compact.png',
  frame: Size(640.0, 360.0),
  spots: {
    'cave': Offset(92.0, 104.0),
    'forest': Offset(226.0, 124.0),
    'lighthouse': Offset(360.0, 104.0),
    'beach': Offset(96.0, 268.0),
    'library': Offset(240.0, 280.0),
    'shadow': Offset(466.0, 186.0),
    'islets': Offset(550.0, 276.0),
  },
  guideFoot: Offset(374.0, 332.0),
  hud: Rect.fromLTRB(468.0, 0.0, 640.0, 112.0),
  placeBase: 120.0,
  placeMin: 100.0,
  placeMax: 200.0,
  minTap: 96.0,
);
