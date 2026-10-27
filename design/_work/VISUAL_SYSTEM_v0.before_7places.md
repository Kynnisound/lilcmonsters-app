# Lil C Monsters (code name SeaMonsters) · Visual System v0 (draft)

Research and direction step for the kids' mobile app (Flutter + Firebase, ages ~3 to 7). **This is a direction draft, not final mockups.** Every value below is a proposal for the art director to accept, change or reject.

- Board: `design/direction_v1.png` (2400×1350)
- Reference thumbnails: `design/refs/` (18 PNG files, downloaded from Mobbin's public screen pages)
- Working files (fonts converted for rendering, board script, candidate sheet): `design/_work/`
- Brand sources used: `/workspace/lilcmonsters/CONCEPT.md` (palette, type, motion tokens, "no over-stimulation" risk table), `ref/*_c.png` cutouts, `ref/character_sheet.png`, `site/assets/fonts/`

---

## 0. Existing project findings (box only)

**Update during this run:** at the start (02:58 CET) no SeaMonsters project existed. The filename and content searches found nothing. While I was working, a **Flutter project was created at `/workspace/seamonsters/`** (files dated 03:04 to 03:07 CET, still being written; not a git repo). Our `design/` folder sits inside that project root. Snapshot at 03:08 CET:

- `pubspec.yaml`: package `seamonsters`, description "Lil C Monsters (SeaMonsters) : appli d'eveil pour jeunes enfants". Deps: `go_router`, `flutter_riverpod`, `audioplayers`, `url_launcher`, `cupertino_icons`. **No Firebase or RevenueCat packages yet.** Fonts declared: LuckiestGuy and Baloo2 (500 Medium and 800 ExtraBold only).
- `lib/core/`: `theme/app_tokens.dart` + `app_theme.dart`, `audio/` (audio service over audioplayers, sound effects), `config/app_config.dart` (dart-define flags `PREMIUM_UNLOCKED`, `UNLOCK_ALL_ISLETS`, `PARENTAL_GATE`, YouTube URL `@LilCMonsters`), `l10n/strings.dart` (French labels, comment says the child never needs to read and the labels are for screen readers and the parent area).
- `lib/features/`: empty folders `map, beach, cave, forest, library, lighthouse, puzzle, shadows, parents`. `lib/app/` is empty. **No screens implemented yet.**
- `assets/`: monster webps (5), story covers 01 to 06, colouring colour/line 01 to 04, videos posters, brand icon, generated `.wav` sounds (tap, pop, boing, chime, drum, wave, success, notes do re mi sol la) from `tool/gen_sounds.py`. `screenshots/` and `test/` are empty or near-empty.
- README is the default Flutter template text.

**Current code tokens vs this draft** (for the dev to reconcile once the AD validates):

| Item | `app_tokens.dart` / `app_theme.dart` now | This draft proposes |
|---|---|---|
| Colours | site tokens (5 monsters, sun, teal, plum, plum2, cream, paper, peach, sky, sunset, dusk, lilac, night, night2, duskDeep, inkSoft) | keep all + add `lagoon` (= teal), `lagoonDeep #0B6E6A`, `foam #D4F4EE`, `coral #FF7A5C`, `coralDeep #C8432A`, `sand #FFE4BF`, `mist #B9B3C7` |
| Primary action | `plum2 #6E28A0`, white text (8.5:1, fine for contrast) | `coral` with plum outline and cream/plum icon, to match the turquoise + coral brief; plum2 stays for parent-area buttons |
| `minTouch` | 64 | 72 |
| `homeButton` | 76 | 72 to 76 (fine as is) |
| `mapSpot` | 108 | 120 to 140 hit area |
| `pad` | 120 | no change proposed |
| Motion | t1 300 / t2 600 / t3 1000 / t4 1600 ms, boing / soft / io curves | same (already matches) |
| Fonts | Baloo2 500 + 800 | add 600 or 700 if labels need a middle weight |

Other context found on the box:
- A QA agent profile "QA Lil C Monsters" (`/home/box/sand-data/agents/80ef61ec-.../profile.json`) describes the app: Flutter + Firebase, **RevenueCat subscriptions**, island map, sound sandbox, colouring, monster hunt, animated audiobooks, islets puzzle, shadow game, YouTube; checks for big touch buttons, **no reading required**, **no external link or purchase without a parental gate**, Apple Kids Category / Google Play Families / GDPR / COPPA, a one-week beta with children. It names Webboy (Flutter/Firebase dev) and Margaux Vérany (design mockups).
- Unrelated matches: YouTube channel naming history ("Lil Sea Monsters" → "Lil C Monsters", C for Cuddly), social launch-kit text, a GitHub search dump about an unrelated robotics team "Seamonsters-2605".
- `/workspace/lilcmonsters/` is the static brand website (Python generator, vanilla JS), not app code; its tokens, fonts and motion tokens are reused here.

## 1. References (Mobbin)

**Tool note:** the Mobbin MCP (`user-Mobbin-6781307`) answered every call (`search_screens` deep and standard, `list_collections`) with *"Mobbin MCP requires a paid plan. Upgrade at https://mobbin.com/pricing"*. As a fallback, I found screens through web search and read Mobbin's **public** screen pages (`mobbin.com/explore/screens/<id>`), which expose the title and the screen image. Nothing was saved to any Mobbin collection.

**Catalogue gap:** Mobbin has very few true preschool apps (no Khan Academy Kids, Sago Mini, Toca Boca, Pok Pok or Moshi in public results). The list mixes kid-facing apps (Duolingo ABC) with adult apps whose *patterns* transfer (path nodes, locks, matching, colouring dots, soundscape grids). For true toddler-game references (island maps, shadow matching), App Store screenshots of Khan Academy Kids, Lingokids, Moshi Kids, Pok Pok, Sago Mini World and shadow-match apps would be the next source (not collected here).

| # | App | Use for | What to take | Mobbin URL | Local file |
|---|---|---|---|---|---|
| 1 | Duolingo | Map / level nodes | Winding path of round 3D nodes: done (gold check), current (bright, ringed), future (grey). Mascot sits beside the path. | https://mobbin.com/explore/screens/f0e04c7b-2298-4a2a-8d7e-1ada5c3918db | `refs/01_duolingo_path_next.png` |
| 2 | Duolingo | Map / current node | Active node with a glow ring and a speech-tag label above it; one obvious next step. | https://mobbin.com/explore/screens/d057b2cb-1ed5-47df-a378-3c0a52ade63c | `refs/02_duolingo_path_levelup.png` |
| 3 | Duolingo | Locked content | Locked course shown as a greyed card with a single big JUMP HERE pill; illustration stays visible. | https://mobbin.com/explore/screens/697e2bb9-1624-4e6a-82ed-561a28bb4125 | `refs/03_duolingo_foundations_locked.png` |
| 4 | Duolingo | Locked / progress track | Progress rail with round lock nodes and a big full-width START pill on a warm coral field. | https://mobbin.com/explore/screens/4a6cc567-5284-43f0-846c-02bb44450a16 | `refs/04_duolingo_matchmadness_locks.png` |
| 5 | Duolingo ABC | Kids brand / characters | Character-packed splash: the whole cast on screen, chunky rounded wordmark. | https://mobbin.com/explore/screens/ec629d2a-6a41-4a11-af02-e3db8bbcf310 | `refs/05_duolingo_abc_splash.png` |
| 6 | Duolingo ABC | Big-button kids UI | Two characters as guides, a single huge arrow button, no text needed. | https://mobbin.com/explore/screens/7d4fd1eb-a6d4-4d72-92f7-bc9e9867a77a | `refs/06_duolingo_abc_bigarrow.png` |
| 7 | Duolingo ABC | Big-button kids UI | Stacked large pill answers, one coloured as selected; audio-first prompt. | https://mobbin.com/explore/screens/f3993086-d348-4405-9795-96044c81d844 | `refs/07_duolingo_abc_pills.png` |
| 8 | Duolingo ABC | Character as narrator | Mascot listening with a music note: waiting state carried by the character. | https://mobbin.com/explore/screens/ca815210-39b6-4847-a963-a45f59c0045f | `refs/08_duolingo_abc_loading.png` |
| 9 | Finch | Forest / exploration map | Soft painted forest scene, pet in the centre, three round discovery nodes (flag, found cherry, ? still hidden). | https://mobbin.com/explore/screens/4c4de77e-b5ad-49c5-849a-0a98c951edb5 | `refs/09_finch_forest_nodes.png` |
| 10 | Finch | Hunt / narrator | Character finds items in the scene and talks through speech bubbles: hunt + narration in one. | https://mobbin.com/explore/screens/6bcfac13-2500-4f7e-a76b-e1e7919613c4 | `refs/10_finch_narrator_bubbles.png` |
| 11 | Duolingo Math | Puzzle / matching | Large square tiles in a 2-column grid, matched pairs fade, correct state in green. | https://mobbin.com/explore/screens/22d3d885-4e67-44a7-8eef-35c0c7ecfdfe | `refs/11_duolingo_math_pairs.png` |
| 12 | Duolingo | Sound toy / matching | Match the pairs: round letter-name buttons paired with notes on a staff; tap to hear, then match. | https://mobbin.com/explore/screens/61533f18-71cc-4159-9021-5d88fc2810ea | `refs/12_duolingo_music_pairs.png` |
| 13 | Google Arts & Culture | Sound toy | Four colourful note characters with faces as tappable sound objects, on warm cream paper. | https://mobbin.com/explore/screens/bbeefedf-a697-4f2a-9937-c83da0e37848 | `refs/13_gac_music_notes.png` |
| 14 | Lake | Colouring | Line-art page with a bottom row of large round paint dots; a dark round toast announces the new palette. | https://mobbin.com/explore/screens/ec59d3b8-7053-43d1-9d23-dc53debd713d | `refs/14_lake_colouring.png` |
| 15 | Endel | Sound / mood picking | Grid of round soundscape icons with one-word labels; calm, low-stimulation. | https://mobbin.com/explore/screens/69f2c588-66e1-45fd-8e0b-7ef6ab28b8de | `refs/15_endel_soundscapes.png` |
| 16 | Elevate | Puzzle / shapes | Colourful flat geometric shape puzzle (Mobbin label); clear-edged pieces, a model for islet pieces. | https://mobbin.com/explore/screens/c635898d-f9d2-4505-ab9f-a1870d3ce845 | `refs/16_elevate_shape_puzzle.png` |
| 17 | Khan Academy | Drag & drop / shadow | "Put 7 squirrels in the box": drag items into a drop zone; pattern for the shadow/silhouette game. | https://mobbin.com/explore/screens/65927983-1b21-4701-a997-8def58c2849b | `refs/17_khan_drag_count.png` |
| 18 | Calm | Library / night mood | Starry night illustration behind a story list with a narrator credit and a big Pause pill. | https://mobbin.com/explore/screens/842de1a5-a0ea-4065-ba1c-8768b280daef | `refs/18_calm_night_program.png` |

Board shows 9 of them (01, 03, 09, 06, 10, 14, 13, 16, 18). Screens are © their owners, for internal reference only.

**Patterns to keep**
1. One obvious next step on the map: done / current (glow ring) / future / locked, readable by colour + shape + icon, not by text (Duolingo path, Finch nodes).
2. Locked still shows the place: greyed (mist) but the illustration stays visible, with a padlock and a gentle "wobble + guide line" on tap (Duolingo locked unit).
3. A character holds every waiting or empty moment (Duolingo ABC loading, Finch speech bubbles).
4. Colouring = big round paint dots in a bottom tray, line art on cream (Lake).
5. Sound objects have faces (Google Arts & Culture notes): perfect fit for "monster shells / wave creatures" on the beach.

**Patterns to avoid for 3 to 7**: XP, timers, streak pressure, "Speed round" (Duolingo Math), red/green right-wrong as the only feedback, dense text cards (Calm list), dark neon game UI (Elevate).

## 2. Palette

Built from the existing brand tokens (CONCEPT.md §6) and the five fur colours. Turquoise = the existing `teal #3fc1b0` promoted to "Lagoon". Coral is new, placed between Fuzzle orange and Bitsy pink so it reads as "our" coral and not as either character.

| Token | Hex | Role | Best text on it (WCAG ratio) |
|---|---|---|---|
| `lagoon` | `#3FC1B0` | sea, primary surfaces, map water (brand `teal`) | plum 6.7:1 |
| `lagoonDeep` | `#0B6E6A` | icons and secondary text on light, selected outline | white 6.1:1 · on cream 5.7:1 |
| `foam` | `#D4F4EE` | light backgrounds, cards on map | plum 12.6:1 |
| `coral` | `#FF7A5C` | **main action** (Play, Go, Next) | plum 5.8:1 |
| `coralDeep` | `#C8432A` | button bottom edge, pressed state | white 4.9:1 |
| `sand` | `#FFE4BF` | beach, card fills (close to brand `peach #ffd9a0`) | plum 12.0:1 |
| `plum` | `#3A1752` | ink, all outlines (brand) | on cream 13.7:1 |
| `cream` | `#FFF6E5` | paper background (brand) | plum 13.7:1 |
| `sun` | `#FFD60A` | reward, star, "new" ring, unlock (brand) | plum 10.4:1 |
| `night` | `#1B1747` | bedtime, library (brand); `night2 #2A2470` | cream 15.5:1 · sun 11.8:1 |
| `mist` | `#B9B3C7` | locked state | plum 7.3:1 |
| `sky` | `#E3F2FF` | day sky (brand) | plum 12.9:1 |

Character colours (unchanged): Fuzzle `#FC9313`, Pip `#1B98D0`, Dottie `#86BE34`, Zib `#A75BAD`, Bitsy `#FC647D`. They are fur and "owner" accents (a guide's place, a book's spine), never the only carrier of text.

**Contrast notes for kids**
- Coral vs lagoon is **1.16:1** in luminance: they look vivid side by side but are the same value, and coral/turquoise is a weak pair for red-green colour-blind children. Always separate them with a plum outline (4 dp) or a cream gap; never encode a state only by coral vs turquoise.
- White on lagoon (2.2:1) and white on coral (2.6:1) fail: icons on these fills are cream with a plum outline, or plum.
- States always change **shape or icon + colour + sound** (done = check badge, locked = padlock, new = sun ring), never colour alone.
- Keep saturated character colours to characters and small accents; big backgrounds stay in foam / sand / cream / sky / night to limit visual noise.

## 3. Typography

| Use | Font | Settings | Notes |
|---|---|---|---|
| Place names, titles, wordmark-like moments | **Luckiest Guy** (Apache 2.0, already on the box) | 40 to 72 sp, plum, optional `sun` offset shadow as on the site | **Caps only**: the font has no real lowercase (lowercase renders as small caps). 1 or 2 words max. Not for sentences. |
| Labels, captions, parent area, settings | **Baloo 2** 500 to 800 (OFL, variable, on the box) | 18 sp min for parents, 22 to 28 sp for any word shown to a child | Single-storey `a` and `g` (good for early readers, checked on a render). Weakness: capital `I` and lowercase `l` look the same, `0` and `O` are close. |
| Optional: early-reader word games (later) | Andika (OFL, designed for beginning readers) | only if a module ever teaches letters | The box only has a renamed Lingala subset ("LCM Afri Fallback"), not the full font; get it from Google Fonts if needed. |

**Pre-readers (3 to 5) do not read.** Every child-facing label is an icon + a spoken line by the guide character; text is an extra for parents and older kids. No instruction depends on reading. Parent-only screens (settings, subscriptions, YouTube exit) sit behind a parental gate and can use normal adult text sizes.

Fonts on the box are web subsets (`.woff2`); for Flutter, download the full TTFs from Google Fonts (licences already noted in `site/assets/fonts/`).

## 4. Touch targets and buttons

Reference points: Apple HIG minimum is 44 pt and Material is 48 dp, both for adults. Young children tap less precisely, so this draft goes well above:

| Element | Size | Gap |
|---|---|---|
| Any child-facing target (minimum) | **72 dp** | 24 dp |
| Primary action (Play / Go / Next) | **96 dp** circle or 96 dp-tall pill | 32 dp from screen edge |
| Map places (8 locations) | **120 to 140 dp** hit area (art can be bigger) | well apart, no overlaps |
| Colour dots (cave) | 72 dp | 16 dp |
| Back / home | 72 dp, always top-left, same icon everywhere | |
| Parental gate entry | deliberately small (44 dp) or hold-to-open | top-right |

**Big button anatomy (board §4):** coral circle, 4 dp plum outline, 12 dp solid `coralDeep` bottom edge (toy / sticker look, same language as the site's buttons), cream play triangle with plum outline, soft highlight top-left.
- **Idle**: as above, very slow breathing (scale 1.00 to 1.03, 1.6 s) only on the single next-step button.
- **Pressed**: sinks 12 dp (edge disappears), scale 0.96, fill a touch darker, 120 ms, plus a soft "boop" sound and light haptic.
- **Locked**: `mist` fill, plum padlock, darker mist edge. On tap: small wobble (±4°, 300 ms) + the guide says why ("Find 3 shells first!"). Never a buzzer.
- **New / just unlocked**: `sun` 8 dp ring, slow pulse 1.6 s, guide points at it once.
- Hit area = whole visual + 8 dp padding; accept tap on release, ignore multi-touch palm hits, no long-press-only actions for kids.

## 5. Icon style

- Chunky filled objects (shell, crayon, magnifier, book, lighthouse, puzzle piece), 2 fills + 4 dp plum outline, inside a rounded tile (radius ~33%), matching the painted storybook look.
- No thin strokes, no letters or numbers inside icons, no abstract UI glyphs (no hamburger, no gear for kids).
- Every icon has a voice line (the guide names it on first tap).
- Icon set lives in vector (SVG, then Flutter vector or `flutter_svg`); painted illustration stays raster.

## 6. Motion principles (from CONCEPT.md, adapted to the app)

- Timing tokens kept from the site: `t1 300 ms` (tap feedback), `t2 600 ms` (pop-ins, bubbles), `t3 1000 ms` (place transitions), `t4 1600 ms` (breathing, slow zooms). Curves: `easeBoing cubic-bezier(.34,1.56,.64,1)` for taps, `easeSoft (.22,1,.36,1)` for arrivals, `easeIo (.65,0,.35,1)` for fades.
- **One focal motion at a time.** Background loops (waves, leaves, stars) are slow and low-amplitude.
- **No flashing** (stay far below 3 flashes per second), no strobe, no fast shakes, no screen-wide confetti; rewards = the guide's hug or happy hop + a few soft sparkles + a short warm sound.
- Map navigation = a gentle camera pan/zoom into the place (~1 s), never a hard cut; returning home reverses it.
- No timers, no countdowns, no fail sounds; wrong answers get a playful "hmm, try another!" from the guide.
- **Calm mode** (parent setting) and OS reduced-motion: stop loops, keep only state changes as fades. Sound: gentle, volume-capped, music off by default at bedtime hours (to validate).

## 7. One mood per place (colour + light)

| Place | Module | Guide (proposal) | Mood | Colours | Light |
|---|---|---|---|---|---|
| Island map | entry / navigation | **Fuzzle** (lead) | morning lagoon | lagoon, foam, sand, sun | soft morning key light from top-left, cloud shadows drifting slowly |
| Beach | sound sandbox (waves) | **Pip** (blue = water) | midday sparkle | sky, sand, lagoon gradient, foam | bright high-key, gentle caustic glints on water |
| Cave | digital colouring | **Dottie** (dots = paint dots) | crystal + lantern | violet `#3B2A5C` / `#6B4FA0`, teal crystals, lantern amber `#FFC56B`; canvas stays cream | low ambient, warm local glow pools; the page itself always evenly lit |
| Forest | monster hunt | **Zib** (antennae = finder) | dappled sunbeams | Dottie-green family `#CFE8A8` → `#86BE34`, moss `#2F6B3A` | sun rays through leaves, moving leaf shadows (slow) |
| Library | animated audiobooks | **each book's own lead** narrates | bedtime lamp | night, night2, lamp amber, cream pages | dark room, one warm lamp, slow star twinkle (matches the site's "goodnight" section) |
| Lighthouse | brand YouTube | **the whole crew** | sunset glow | sunset `#FFC9A3`, coral, sun | golden hour, slow rotating beam; exit to YouTube behind parental gate |
| Islets puzzle | unlocked on map | **Fuzzle** ("try again" spirit) | shallow noon | foam, lagoon, sand islets | flat even light so piece edges read clearly |
| Shadow game | unlocked on map | **Bitsy** with the lantern | dusk lantern | dusk `#EAD9F5` → night2, sun-yellow lantern cone | dark surround, lantern cone reveals plum silhouettes (85%) |

The guide assignments are proposals for the AD (characters' personalities in the books should drive the final choice).

## 8. Flutter hand-off notes (proposal)

- Extend the existing `AppColors` / `AppSizes` in `lib/core/theme/app_tokens.dart` rather than starting a new token file; per-place moods could be a `ThemeExtension` so each place overrides background/light colours while buttons stay identical.
- Sizes in logical pixels (dp); test on a small phone (360 dp wide) and on tablets, where children use the app most.
- Next design steps: (1) island map sketch with the 8 places, locked and unlocked states; (2) one key screen per module; (3) a 5-minute hallway test of button size and locked-state understanding with 2 or 3 children before the beta.
