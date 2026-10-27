# Lil C Monsters · illustrated assets v1 (working draft)

Status: **draft for art-director review (Margaux Vérany), not final art.** Generated and cleaned on 27 Oct 2026. Nothing here has been copied into the Flutter `assets/` folder or `pubspec.yaml` yet: that is Webboy's call once the AD accepts the set.

- Contact sheet: `design/assets/_contact.png`
- Map mockups (map + 7 places, mixed locked/unlocked, Fuzzle as guide, no module pictograms on places): phone `design/map_sketch_v1.png`, tablet 4:3 `design/map_sketch_tablet43_v1.png`
- Machine-readable list (file names, dp sizes, states, intended screen, map spot coordinates): `design/assets/manifest.json`
- Sources and scripts (rebuild everything): `design/_work/pipeline/` (`map.py`, `map_tablet.py`, `landmarks.py`, `icons.py`, `export_icons.py`, `mockup.py`, `contact.py`, `manifest.py`); raw generations in `design/_work/assets_gen/`

The app has **7 places** (beach, cave, forest, library, lighthouse, islets puzzle, shadow game). The island map is the **hub / home screen**, not a place.

## What is in here

| Folder | Files | dp size | Notes |
|---|---|---|---|
| `map/` | `map_island_morning.png` | 812 × 375 dp (@3x = 2436 × 1125 px) | Opaque background (it is the whole screen, so no transparency). Morning lagoon, top-left sun, 7 empty pads + 1 empty pad for the guide. No text, no characters. |
| `map/` | `map_island_morning_tablet43.png` | 1024 × 768 dp (@3x = 3072 × 2304 px) | Opaque. 4:3 tablet frame: the same island redrawn (not stretched), places spread a little vertically, extended at top (sky haze, clouds) and bottom (lagoon, foam, small islets). Layout `manifest.json → map.layouts.tablet43`. |
| `map/` | `map_island_morning_safe16x9.png` | 667 × 375 dp (@3x = 2001 × 1125 px) | Centred 16:9 crop of the same frame: what a 16:9 phone shows with `BoxFit.cover`. All 7 places are inside it. |
| `places/` | `place_<id>_unlocked.png`, `place_<id>_locked.png` | exported as a 200 × 200 dp box (@3x = 600 px, v1.2), displayed at 140 dp × map scale, 120–200 dp (rule (b)) | `<id>` = `beach`, `cave`, `forest`, `library`, `lighthouse`, `islets`, `shadow`. Transparent. Art sits on the bottom of the box (base = ground contact). Locked = mist ramp + plum padlock badge baked in the top-right corner. |
| `icons/` | `icon_<id>.png` (+ `icons/svg/icon_<id>.svg`) | 96 dp (module objects), 72 dp (sound, back, home), 48 dp (padlock, padlock badge), 44 dp (parental gate) | Transparent. Plump filled objects, plum outline, no letters (the parental-gate gear is the deliberate exception, see below). SVG sources included (usable with `flutter_svg` if you prefer vectors). |

Every PNG exists at `@1x` (no folder), `2.0x/` and `3.0x/`, the @3x file being exactly 3 × the dp size.

Icon mapping to Webboy's current placeholders (screens `01_carte`, `02_plage` … `06_carte_telephone`):

| Placeholder now | Replace with | Where (v1.2) |
|---|---|---|
| music note | `icon_beach_shell` | Inside the beach module only (not on the map) |
| palette | `icon_cave_palette` | Inside the cave module only |
| magnifier | `icon_forest_magnifier` | Inside the forest module only |
| book | `icon_library_book` | Inside the library module only |
| play | `icon_lighthouse_play` | Inside the lighthouse module only (YouTube exit behind the parental gate) |
| puzzle | `icon_islets_puzzle` | Inside the islets module only |
| lantern | `icon_shadow_lantern` | Inside the shadow-game module only |
| speaker | `icon_sound_on` / `icon_sound_off` | Map top-right toggle |
| family | `icon_parental_gate` (flat mauve-grey gear, v1.1) | Map top-right only, 44 dp, outside the play area |
| house | `icon_home` | Top-left on every place screen |
| (new) | `icon_back` | Top-left inside a sub-screen, if a "one step back" is ever needed |
| padlock | `icon_padlock`, `icon_padlock_badge` | Locked buttons, cards, places |

Since v1.2 the seven module icons are **not** used on the map places any more (rule (a) below): they live inside the modules and in the HUD only.

The yellow medal/premium badge in the screenshots was not redrawn (not in the brief); it still uses Webboy's version.

## Plugging them into Flutter

1. Copy the three folders, keeping the density sub-folders:

```
design/assets/map/     -> assets/images/map/
design/assets/places/  -> assets/images/places/
design/assets/icons/   -> assets/images/icons/        (icons/svg/ only if you use flutter_svg)
```

2. Declare the folders in `pubspec.yaml` (listing the folder is enough; Flutter picks `2.0x/` and `3.0x/` variants automatically):

```yaml
flutter:
  assets:
    - assets/images/map/
    - assets/images/places/
    - assets/images/icons/
```

3. Use the 1x path in code, with the dp size from the manifest:

```dart
Image.asset('assets/images/places/place_beach_unlocked.png', width: place, height: place); // place = clamp(140 * s, 120, 200)
Image.asset('assets/images/icons/icon_home.png', width: 44, height: 44); // inside the 72 dp home button
```

4. Placing the places on the map (rules (a) and (b) below). Pick the layout by screen shape: `tablet43` (1024 × 768 dp frame, `map_island_morning_tablet43.png`) when width / height < 1.7 (covers 4:3 and 16:10 tablets; validated with Webboy 2026-10-27), otherwise `phone` (812 × 375 dp frame, `map_island_morning.png`). Positions come from `manifest.json → map.layouts.<layout>.places[id]` in **map-relative units** (`center_fraction`, or `center_dp` in the frame). The map scale factor `s` is the one `BoxFit.cover` uses for the decor, and places scale with it; HUD buttons do not:

```dart
// layout = manifest map.layouts['tablet43' | 'phone']; frame = layout.frame_dp
LayoutBuilder(builder: (context, c) {
  final fw = layout.frameW, fh = layout.frameH;
  final s = math.max(c.maxWidth / fw, c.maxHeight / fh);          // same factor as BoxFit.cover
  final dx = (c.maxWidth - fw * s) / 2, dy = (c.maxHeight - fh * s) / 2;
  final place = (140 * s).clamp(120.0, 200.0);                     // rule (b)
  return Stack(children: [
    Positioned.fill(child: Image.asset(layout.mapAsset, fit: BoxFit.cover)),
    for (final p in layout.places)                                  // p.fx, p.fy = center_fraction
      Positioned(
        left: dx + p.fx * fw * s - place / 2, top: dy + p.fy * fh * s - place / 2,
        width: place, height: place,
        child: PlaceButton(p, tapDiameter: place * 130 / 140),      // circle, centred
      ),
    // HUD: fixed dp, never multiplied by s (sound 72 dp, parent gear 44 dp, home 72 dp)
    Positioned(top: 24, right: 24, child: HudRow()),
  ]);
});
```

   On a 16:9 phone the cover crop is the `safe16x9` frame, so every place stays visible. Keep the HUD inside `hud_safe_zone_dp` of the layout; no place or guide ever goes there.
5. States:
   - **unlocked**: `place_<id>_unlocked.png`.
   - **locked**: swap to `place_<id>_locked.png` (padlock already baked in), keep the same hit area, wobble ±4° 300 ms on tap (`AppMotion.wobble`) and let the guide say why.
   - **new / just unlocked**: unlocked art + an 8 dp `AppColors.sun` ring drawn by the app (`AppSizes.sunRing`), slow 1.6 s pulse. Not baked into the PNG on purpose.
   - **sound**: swap `icon_sound_on` / `icon_sound_off`.
6. **Parental gate entry** (`icon_parental_gate`, v1.1 after QA review): a flat monochrome gear, fill `#5A536C` with a 2-unit `#4A4459` outline (about half the module-icon outline), no gloss, no relief, no drop shadow, no teal, no people. 3.2:1 against lagoon, 6.7:1 against cream. Draw it as is at 44 × 44 dp, top-right, with **no** button disc, no `buttonEdge`, no wobble, no sound and no breathing/pulse; touch target at least 44 dp (`AppSizes.parentEntry`). It is deliberately unlike the plum padlock (shape, colour and weight). The centre hole is transparent, so the background shows through. The challenge behind it must follow spec §4 (Apple Kids 1.3 / 5.1.4, Google Play Families).
7. Contrast rule (spec §2): the icons never put white directly on lagoon or coral. Light parts (cream speaker, cream arrow, cream house walls, foam lens) are always closed by the 4 dp plum outline, so they can sit on the coral or lagoon buttons as they are.
8. **Map rules (v1.2, also in spec §4):**
   - **(a) No module pictograms on map places.** The drawn place plus its spoken label (the guide names it) is the identifier. Remove the small icon tiles at the bottom-left of each place. Module icons are used only inside the modules and in the HUD (back, home, sound and the like). The locked state keeps its padlock badge (baked in `place_<id>_locked.png`) and the "new" sun ring stays (drawn by the app).
   - **(b) Places scale with the decor.** Place size = `140 dp × s`, `s` = the scale factor used to fit the decor to the screen, clamped to **120–200 dp**; tap area = a circle of 130/140 of that size. Positions come from the manifest in map-relative units. HUD buttons do not scale and stay at their fixed dp size.
9. Accessibility: add a `Semantics(label: …)` per place and per icon (the French strings in `lib/core/l10n/strings.dart`); the art has no text.

## Production notes

- Map: drawn as SVG in Python and rendered with cairosvg (exact palette: lagoon #3FC1B0, foam #D4F4EE, sand #FFE4BF, sun #FFD60A, plum #3A1752 outlines; light from the top-left).
- Places: generated as stickers on white (GenerateImage), then cut out in Python (flood fill of the white background from the edges, hole filling, 2 px erosion and soft edge, OpenCV + Pillow), outline colour pulled from mauve to plum, uniform plum rim, fitted to a 200 dp box (v1.2; was 140 dp). Locked variant: luminance mapped to a mist ramp (#766E8E to #DED9E8, 12 % original colour), outlines kept in inkSoft, plum padlock badge.
- Icons: hand-written SVG (`icons.py`), 2 fills + highlight + 4 dp plum outline, rendered with cairosvg.

## Unsure / still weak (self-critique, v1)

- **Two techniques in one set.** Map and icons are clean vector; the places are painted stickers with slight texture. Outlines are all plum and the palette matches, but next to each other the places look richer than the map. Options for v2: repaint the map in the same painted style, or vectorise the places.
- **Lighthouse** is the narrowest silhouette: it reads at 120 dp but has less mass than the other places.
- **Beach vs islets**: both are sand + turquoise. They differ by shells/wave vs jigsaw shapes, but colour alone does not separate them.
- **Locked shadow tent**: the tent is lilac, close to mist, so the locked/unlocked difference is weaker than for the others (the padlock badge carries it). Unlocked saturation was raised 30 % to help.
- **Tablets (4:3)**: done in v1.2 (`map_island_morning_tablet43.png` + `layouts.tablet43`, mockup `design/map_sketch_tablet43_v1.png`). On the 1024 × 768 frame the island fills about half of the width, so the sea dominates. On a 12.9-inch iPad (s ≈ 1.33) places reach about 187 dp, which is fine. 16:10 Android tablets (1280×800) now use `tablet43` thanks to the < 1.7 threshold, losing only about 80 dp of sky/lagoon at top and bottom; HUD buttons stay anchored to the screen, not to the map. Webboy's `13_carte_tablette_v3.png` letterboxes the phone map and still shows the module pictograms and the old family icon. Both go away with this version.
- **Fuzzle** in the mockup is the existing low-res website cutout (`ref/fuzzle_c.png`, 362 × 407 px). It is fine at the mockup size but too small for a @3x guide sprite.
- **Parental gate icon**: replaced in v1.1 (27 Oct 2026, 10:45 CET) after QA found the adult + child figures too inviting. It is now a flat mauve-grey gear. Its contrast on lagoon (3.2:1) only just clears 3:1, so it should not be placed on a lighter or busier background without re-checking.
- The board image `direction_v1.png` still says "8 places" in its status box (the markdown spec is fixed).
