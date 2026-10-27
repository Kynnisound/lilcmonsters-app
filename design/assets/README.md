# Lil C Monsters · illustrated assets v1 (working draft)

Status: **draft for art-director review (Margaux Vérany), not final art.** Generated and cleaned on 27 Oct 2026. Nothing here has been copied into the Flutter `assets/` folder or `pubspec.yaml` yet: that is Webboy's call once the AD accepts the set.

- Contact sheet: `design/assets/_contact.png`
- Map mockup (map + 7 places, mixed locked/unlocked, Fuzzle as guide): `design/map_sketch_v1.png`
- Machine-readable list (file names, dp sizes, states, intended screen, map spot coordinates): `design/assets/manifest.json`
- Sources and scripts (rebuild everything): `design/_work/pipeline/` (`map.py`, `landmarks.py`, `icons.py`, `export_icons.py`, `mockup.py`, `contact.py`, `manifest.py`); raw generations in `design/_work/assets_gen/`

The app has **7 places** (beach, cave, forest, library, lighthouse, islets puzzle, shadow game). The island map is the **hub / home screen**, not a place.

## What is in here

| Folder | Files | dp size | Notes |
|---|---|---|---|
| `map/` | `map_island_morning.png` | 812 × 375 dp (@3x = 2436 × 1125 px) | Opaque background (it is the whole screen, so no transparency). Morning lagoon, top-left sun, 7 empty pads + 1 empty pad for the guide. No text, no characters. |
| `map/` | `map_island_morning_safe16x9.png` | 667 × 375 dp (@3x = 2001 × 1125 px) | Centred 16:9 crop of the same frame: what a 16:9 phone shows with `BoxFit.cover`. All 7 places are inside it. |
| `places/` | `place_<id>_unlocked.png`, `place_<id>_locked.png` | 140 × 140 dp box (@3x = 420 px) | `<id>` = `beach`, `cave`, `forest`, `library`, `lighthouse`, `islets`, `shadow`. Transparent. Art sits on the bottom of the box (base = ground contact). Locked = mist ramp + plum padlock badge baked in the top-right corner. |
| `icons/` | `icon_<id>.png` (+ `icons/svg/icon_<id>.svg`) | 96 dp (module objects), 72 dp (sound, back, home), 48 dp (padlock, padlock badge), 44 dp (parental gate) | Transparent. Plump filled objects, plum outline, no letters (the parental-gate gear is the deliberate exception, see below). SVG sources included (usable with `flutter_svg` if you prefer vectors). |

Every PNG exists at `@1x` (no folder), `2.0x/` and `3.0x/`, the @3x file being exactly 3 × the dp size.

Icon mapping to Webboy's current placeholders (screens `01_carte`, `02_plage` … `06_carte_telephone`):

| Placeholder now | Replace with | Place / screen |
|---|---|---|
| music note | `icon_beach_shell` | Beach, sound sandbox |
| palette | `icon_cave_palette` | Cave, colouring |
| magnifier | `icon_forest_magnifier` | Forest, monster hunt |
| book | `icon_library_book` | Library, audiobooks |
| play | `icon_lighthouse_play` | Lighthouse, YouTube (behind parental gate) |
| puzzle | `icon_islets_puzzle` | Islets puzzle |
| lantern | `icon_shadow_lantern` | Shadow game |
| speaker | `icon_sound_on` / `icon_sound_off` | Map top-right toggle |
| family | `icon_parental_gate` (flat mauve-grey gear, v1.1) | Map top-right only, 44 dp, outside the play area |
| house | `icon_home` | Top-left on every place screen |
| (new) | `icon_back` | Top-left inside a sub-screen, if a "one step back" is ever needed |
| padlock | `icon_padlock`, `icon_padlock_badge` | Locked buttons, cards, places |

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
Image.asset('assets/images/places/place_beach_unlocked.png', width: 140, height: 140);
Image.asset('assets/images/icons/icon_home.png', width: 44, height: 44); // inside the 72 dp home button
```

4. Placing the places on the map. All coordinates are in the 812 × 375 dp map frame (`manifest.json → map.spots`). Draw the map with `BoxFit.cover` and place each 140 dp landmark with the same cover transform, so the art always lands on its pad:

```dart
// frame = 812 x 375 dp; spot = manifest map.spots[id].center_dp
LayoutBuilder(builder: (context, c) {
  final s = math.max(c.maxWidth / 812, c.maxHeight / 375);   // cover scale
  final dx = (c.maxWidth - 812 * s) / 2, dy = (c.maxHeight - 375 * s) / 2;
  Offset toScreen(double x, double y) => Offset(dx + x * s, dy + y * s);
  return Stack(children: [
    Positioned.fill(child: Image.asset('assets/images/map/map_island_morning.png', fit: BoxFit.cover)),
    for (final spot in spots)
      Positioned(
        left: toScreen(spot.x, spot.y).dx - 70, top: toScreen(spot.x, spot.y).dy - 70,
        width: 140, height: 140,               // keep 140 dp; do not scale with s on phones
        child: PlaceButton(spot),             // hit area: 130 dp circle centred in the box
      ),
  ]);
});
```

   On a 16:9 phone the cover crop is the `safe16x9` frame, so every place stays visible. On 4:3 tablets `BoxFit.cover` crops top and bottom; see "unsure" below.
5. States:
   - **unlocked**: `place_<id>_unlocked.png`.
   - **locked**: swap to `place_<id>_locked.png` (padlock already baked in), keep the same hit area, wobble ±4° 300 ms on tap (`AppMotion.wobble`) and let the guide say why.
   - **new / just unlocked**: unlocked art + an 8 dp `AppColors.sun` ring drawn by the app (`AppSizes.sunRing`), slow 1.6 s pulse. Not baked into the PNG on purpose.
   - **sound**: swap `icon_sound_on` / `icon_sound_off`.
6. **Parental gate entry** (`icon_parental_gate`, v1.1 after QA review): a flat monochrome gear, fill `#5A536C` with a 2-unit `#4A4459` outline (about half the module-icon outline), no gloss, no relief, no drop shadow, no teal, no people. 3.2:1 against lagoon, 6.7:1 against cream. Draw it as is at 44 × 44 dp, top-right, with **no** button disc, no `buttonEdge`, no wobble, no sound and no breathing/pulse; touch target at least 44 dp (`AppSizes.parentEntry`). It is deliberately unlike the plum padlock (shape, colour and weight). The centre hole is transparent, so the background shows through. The challenge behind it must follow spec §4 (Apple Kids 1.3 / 5.1.4, Google Play Families).
7. Contrast rule (spec §2): the icons never put white directly on lagoon or coral. Light parts (cream speaker, cream arrow, cream house walls, foam lens) are always closed by the 4 dp plum outline, so they can sit on the coral or lagoon buttons as they are.
8. Accessibility: add a `Semantics(label: …)` per place and per icon (the French strings in `lib/core/l10n/strings.dart`); the art has no text.

## Production notes

- Map: drawn as SVG in Python and rendered with cairosvg (exact palette: lagoon #3FC1B0, foam #D4F4EE, sand #FFE4BF, sun #FFD60A, plum #3A1752 outlines; light from the top-left).
- Places: generated as stickers on white (GenerateImage), then cut out in Python (flood fill of the white background from the edges, hole filling, 2 px erosion and soft edge, OpenCV + Pillow), outline colour pulled from mauve to plum, uniform plum rim, fitted to a 140 dp box. Locked variant: luminance mapped to a mist ramp (#766E8E to #DED9E8, 12 % original colour), outlines kept in inkSoft, plum padlock badge.
- Icons: hand-written SVG (`icons.py`), 2 fills + highlight + 4 dp plum outline, rendered with cairosvg.

## Unsure / still weak (self-critique, v1)

- **Two techniques in one set.** Map and icons are clean vector; the places are painted stickers with slight texture. Outlines are all plum and the palette matches, but next to each other the places look richer than the map. Options for v2: repaint the map in the same painted style, or vectorise the places.
- **Lighthouse** is the narrowest silhouette: it reads at 120 dp but has less mass than the other places.
- **Beach vs islets**: both are sand + turquoise. They differ by shells/wave vs jigsaw shapes, but colour alone does not separate them.
- **Locked shadow tent**: the tent is lilac, close to mist, so the locked/unlocked difference is weaker than for the others (the padlock badge carries it). Unlocked saturation was raised 30 % to help.
- **Tablets (4:3)**: the map frame is a phone frame (812 × 375 dp). With `BoxFit.cover` on a 4:3 tablet, the top and bottom get cropped and the lighthouse / library pads sit close to the edge. A taller tablet variant (for example 1024 × 768 dp) is probably needed: to decide with Webboy.
- **Fuzzle** in the mockup is the existing low-res website cutout (`ref/fuzzle_c.png`, 362 × 407 px). It is fine at the mockup size but too small for a @3x guide sprite.
- **Parental gate icon**: replaced in v1.1 (27 Oct 2026, 10:45 CET) after QA found the adult + child figures too inviting. It is now a flat mauve-grey gear. Its contrast on lagoon (3.2:1) only just clears 3:1, so it should not be placed on a lighter or busier background without re-checking.
- The board image `direction_v1.png` still says "8 places" in its status box (the markdown spec is fixed).
