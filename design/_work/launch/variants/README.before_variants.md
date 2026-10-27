# Lil C Monsters · icône d'app + écran de démarrage (BUG-018)

**Version de travail, soumise à validation de David.** Préparé pour Margaux Vérany (DA, Air Paris) le 27/10/2026, à la demande de Webboy (BUG-018 du QA : icône et splash Flutter par défaut sur Android et iOS).
Rien n'a été copié dans `android/`, `ios/`, `assets/` ni `pubspec.yaml` : c'est à Webboy de le faire une fois la version validée.

- Planche de contrôle : `design/assets/launch/_contact.png`
- Scripts (tout se régénère) : `design/_work/pipeline/launch_assets.py` (exports, vérifications, planche, entrée manifest) et `design/_work/pipeline/launch_motif.py` (dessin vectoriel de Pip)
- Mesures brutes : `design/_work/launch/checks.json`
- Manifest : `design/assets/manifest.json → launch`

## Héros : Pip

Un seul monstre, en gros plan : **Pip** (bleu, un seul œil, cornes jaunes rayées orange, houppette, sourire à deux dents, joues corail). Son œil unique est la forme la plus reconnaissable de la bande, et il reste lisible à 29 px. Fuzzle n'existe qu'en basse définition et l'avatar YouTube l'utilise déjà. Les visuels peints (`shadows/color/512/pip_512.png`, sprite 360 px `assets/images/monsters/pip.webp`) sont trop petits pour du 1024 et leur fourrure fine n'a pas de contour. Pip a donc été **redessiné en vectoriel** (SVG rendu par cairosvg), fidèle au sprite mais simplifié : contour extérieur prune épais façon sticker, pas de mèches de fourrure, pas de texte, pas de cadre.

## Fichiers

| Fichier | Taille | Format | Usage |
|---|---|---|---|
| `ios/app_icon_1024.png` | 1024 × 1024 | RGB, **sans alpha**, carré plein | AppIcon iOS (iOS applique le masque arrondi). Motif (bbox 176,142 → 848,899) dans le carré central à 80 % (102 → 922). Seule l'ombre portée douce descend jusqu'à y = 939. |
| `android/ic_launcher_background.png` | 432 × 432 (108 dp @ xxxhdpi) | RGB opaque | Fond de l'icône adaptative : dégradé lagon `#6CD8CA` → `#2FAE9E` avec une lueur écume `#D4F4EE` derrière le héros. **Couleur unie équivalente : `#3FC1B0`.** |
| `android/ic_launcher_foreground.png` | 432 × 432 | RGBA transparent | Premier plan adaptatif. Motif entièrement dans le **cercle de sécurité de 264 px (66 dp)** : rayon max mesuré **128,2 px** (limite 132). |
| `android/ic_launcher_monochrome.png` | 432 × 432 | RGBA, blanc pur sur transparent | Icône thématique Android 13+. Même silhouette et même zone (rayon max 128,2 px). Le blanc de l'œil, la bouche et une fine découpe entre la tête et les cornes, les bras et les pieds sont évidés, pour que Pip reste reconnaissable une fois teinté. |
| `android/play_store/play_store_512.png` | 512 × 512 | RGB | Icône de la fiche Play Store (carré plein, Play applique son masque). Même image que l'icône iOS. |
| `splash/splash_logo.png` | 288 × 288 (288 dp @1x) | RGBA transparent | Logo du splash, @1x |
| `splash/2.0x/splash_logo.png` | 576 × 576 | RGBA | @2x |
| `splash/3.0x/splash_logo.png` | 864 × 864 | RGBA | @3x |
| `splash/android12/splash_android12_1152.png` | 1152 × 1152 (288 dp @4x) | RGBA | Image @4x pour `flutter_native_splash` (`image` et `android_12.image`, cas sans fond d'icône : 1152 px, motif dans un cercle de 768 px). |

Le format 432 correspond déjà à la densité xxxhdpi (108 dp × 4). `flutter_launcher_icons` en dérive les autres densités.

## Couleurs

| Rôle | Hex |
|---|---|
| Fond de l'icône Android (couleur unie équivalente, à utiliser si on préfère une couleur à l'image) | `#3FC1B0` (lagon) |
| Dégradé du fond de l'icône | `#6CD8CA` (haut) → `#2FAE9E` (bas), lueur `#D4F4EE` |
| **Fond du splash** (une seule couleur) | **`#3FC1B0`** (lagon) |
| Contour | `#3A1752` (prune) |
| Pip | `#1B98D0` (dégradé `#5CC3F0` → `#1278AE`), cornes `#FFD60A` + rayures `#FC9313`, joues `#FF7A5C` (corail), œil `#FFFDF8` / `#1B1747` |

Contrastes (WCAG) : prune sur lagon **6,65:1**, prune sur crème 13,74:1. Bleu Pip sur lagon : seulement 1,47:1. C'est le contour prune épais qui détache Pip du fond (voir réserves). Le splash est en lagon, comme l'icône, pour qu'on passe de l'icône au splash sans rupture. La variante crème `#FFF6E5` figure sur la planche, mais elle a été écartée.

## Zones de sécurité (mesurées avec PIL, pixels alpha > 0, distance au centre)

- Premier plan et monochrome Android : rayon max 128,2 px, dans le cercle de 264 px (rayon 132). La fenêtre visible de 72 dp (288 px) n'est donc jamais atteinte, quel que soit le masque (cercle, squircle, carré arrondi).
- Logo du splash : rayon max **96,3 dp** à @1x (96,1 à @2x, 96,0 à @3x et @4x), soit un motif entier dans un cercle d'environ 192 dp, bien à l'intérieur du masque circulaire de 240 dp d'Android 12 (rayon 120). Rien n'est rogné.
- iOS 1024 : rayon max 430 px autour de (512, 486). La bbox du motif tient dans le carré central à 80 %.

## Intégration Flutter (exemple, ne modifie pas `pubspec.yaml` tel quel)

Copier par exemple `design/assets/launch/` vers `assets/launch/` (hors du bundle si on ne veut pas l'embarquer : ces outils lisent les fichiers à la génération seulement). Ensuite, dans un `flutter_launcher_icons.yaml` et un `flutter_native_splash.yaml` à la racine (ou dans `pubspec.yaml`) :

```yaml
# dev_dependencies: flutter_launcher_icons: ^0.14.4
flutter_launcher_icons:
  android: true                 # remplace ic_launcher
  ios: true
  image_path: "assets/launch/ios/app_icon_1024.png"          # iOS + icônes Android anciennes (< 8.0)
  remove_alpha_ios: true        # déjà RGB, sécurité
  background_color_ios: "#3FC1B0"
  min_sdk_android: 21
  adaptive_icon_background: "assets/launch/android/ic_launcher_background.png"   # ou "#3FC1B0"
  adaptive_icon_foreground: "assets/launch/android/ic_launcher_foreground.png"
  adaptive_icon_foreground_inset: 0   # IMPORTANT : la marge est déjà dans le 432 (défaut 16 % = Pip trop petit)
  adaptive_icon_monochrome: "assets/launch/android/ic_launcher_monochrome.png"
```

```yaml
# dev_dependencies: flutter_native_splash: ^2.x
flutter_native_splash:
  color: "#3FC1B0"
  image: assets/launch/splash/android12/splash_android12_1152.png   # le package attend une image @4x
  android_gravity: center
  ios_content_mode: center
  android_12:
    color: "#3FC1B0"
    image: assets/launch/splash/android12/splash_android12_1152.png  # 1152 px, motif dans le cercle de 768 px
    # pas d'icon_background_color : le logo est conçu pour un fond uni lagon
  # color_dark / android_12.color_dark : garder "#3FC1B0" (pas de variante sombre dessinée)
```

Puis `dart run flutter_launcher_icons` et `dart run flutter_native_splash:create`. C'est l'étape de Webboy, non exécutée ici.
Les `splash/splash_logo.png` en 1x, 2x et 3x servent si l'on affiche le même logo côté Flutter (écran de transition animé ou `Image.asset` à 288 dp) : `Image.asset('assets/launch/splash/splash_logo.png', width: 288, height: 288)`.

## Réserves DA (à trancher par David)

1. **Bleu sur lagon** : Pip `#1B98D0` et le lagon `#3FC1B0` ont des luminances proches (1,47:1). La lisibilité repose sur le contour prune épais et sur la lueur écume derrière le héros. Ça tient à 29 px, mais si l'on veut plus de punch, on peut assombrir le bas du dégradé, ou passer le fond en lagon profond `#0B6E6A` (au prix de la cohérence avec la carte).
2. **Redessin** : Pip vectoriel est plus « sticker » (aplats, contour épais) que les illustrations peintes de l'appli et des livres. C'est voulu pour la petite taille, mais le style diffère un peu des visuels intérieurs.
3. **Splash** : on voit le logo seul, sans nom ni wordmark (sans texte, comme demandé). Si David veut le nom au démarrage, le mieux est un `branding` en bas (800 × 320 px, Luckiest Guy), non fourni ici.
