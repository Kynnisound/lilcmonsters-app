# Lil C Monsters (nom de code SeaMonsters)

Application d'éveil pour les 3 à 7 ans, marque Little Cuddly Monsters (lilcmonsters.com).
Squelette Flutter préparé en local : aucun dépôt, aucun projet Firebase, aucun compte de store, rien de publié.

- Plateformes : iOS, Android, web (le web sert uniquement à prévisualiser).
- Organisation : `com.lilcmonsters`, paquet `seamonsters`.
- SDK utilisé pour ce squelette : Flutter 3.47.8 stable, Dart 3.13.7.

## Lancer le projet

```bash
flutter pub get
flutter run                      # appareil ou simulateur
flutter run -d chrome            # prévisualisation web
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn   # aucune ressource chargée depuis un CDN
```

Drapeaux de développement (`--dart-define`) :

| Drapeau | Effet |
|---|---|
| `PREMIUM_UNLOCKED=true` | l'implémentation factice des droits ouvre tout le contenu payant |
| `UNLOCK_ALL_ISLETS=true` | ouvre directement le puzzle d'îlots et le jeu d'ombres |
| `PARENTAL_GATE=false` | coupe la porte parentale (développement uniquement) |

Les 5 notes des monstres se régénèrent avec `python3 tool/gen_sounds.py` (synthèse maison, libre de droits) ; tous les autres sons sont ceux livrés par Shada (voir Sons et crédits).
Les illustrations se réimportent depuis le site avec `python3 tool/import_site_images.py` (voir Assets et crédits).

## Architecture

Structure par fonctionnalité, état géré avec Riverpod 3, navigation go_router.

```
lib/
  main.dart                  point d'entrée, appelle bootstrap()
  app/
    bootstrap.dart           orientation paysage, plein écran, assemblage des implémentations (overrides)
    app.dart                 MaterialApp.router, thème, borne de taille de texte
  core/
    theme/                   app_tokens.dart (tous les tokens), app_theme.dart
    router/                  routes.dart, app_router.dart (redirections : îlots fermés, espace parents)
    audio/                   AudioService (interface), AudioplayersAudioService, RecordingAudioService (tests),
                             SoundEffect / Ambience (chemins, choix .m4a ou .ogg), AmbienceScope (boucle d'un lieu)
    entitlements/            EntitlementService (interface), FakeEntitlementService, PremiumFeature
    backend/                 AuthService, StorageService, RemoteConfigService + implémentations locales
    telemetry/               TelemetryService (interface) + NoopTelemetryService
    parental/                porte parentale (question de multiplication), session parentale de 3 min
    links/                   LinkLauncher (url_launcher), appelé seulement après la porte parentale
    progress/                déblocage des îlots (en mémoire)
    content/                 les 5 monstres, aléatoire injectable
    l10n/                    libellés français (lecteurs d'écran, espace parents)
    widgets/                 BouncyButton, RoundIconButton/ToyDisc, ModuleScaffold, PremiumLock, Wobble, ...
  features/
    map/                     carte de l'île (écran d'entrée)
    beach/                   bac à sable sonore
    cave/                    coloriages
    forest/                  chasse aux monstres
    library/                 livres audio + lecteur
    lighthouse/              vidéos de la marque, VideoSource
    puzzle/                  puzzle d'îlots
    shadows/                 jeu d'ombres
    parents/                 espace parents (pass, restauration, son, confidentialité)
assets/
  images/                    illustrations du site lilcmonsters.com (voir Assets et crédits)
                             + map/, places/, icons/ : assets de travail de Margaux (voir plus bas)
  audio/                     sons de Shada (.ogg + .m4a, CC0 ou domaine public) et SOUNDS_MANIFEST.md
  sounds/                    5 notes des monstres générées (tool/gen_sounds.py)
  fonts/                     Luckiest Guy, Baloo 2 + licences
test/                        tests logiques, tests d'écrans, tests de mise en page sur 3 tailles
screenshots/                 captures du build web
design/                      direction visuelle V1 (non modifiée par ce squelette)
```

Règle : un écran ne parle jamais directement à un plugin ou à un SDK. Il lit un provider Riverpod qui expose une interface ; l'implémentation se choisit dans `lib/app/bootstrap.dart`.

### Modules et accès

| Lieu | Route | Accès | État dans ce squelette |
|---|---|---|---|
| Carte de l'île | `/` | gratuit | jouable : 7 lieux, états ouvert, verrouillé, pass, son, entrée parents |
| Plage | `/beach` | gratuit | jouable : 5 monstres chantent une gamme pentatonique, 4 bruitages |
| Puzzle d'îlots | `/puzzle` | gratuit, à débloquer (3 sons joués à la plage) | jouable : 2 x 2 ou 3 x 3, glisser ou toucher la pièce puis sa case |
| Jeu d'ombres | `/shadows` | gratuit, à débloquer (1 puzzle terminé) | jouable : retrouver l'ombre du monstre, glisser ou toucher |
| Phare | `/lighthouse` | gratuit, porte parentale | vignettes + ouverture de la chaîne @LilCMonsters hors de l'appli |
| Grotte | `/cave` | pass (phase 3) | galerie verrouillée ; si débloquée, aperçu de coloriage par teinte |
| Forêt | `/forest` | courte version gratuite, chasse complète dans le pass | jouable : 3 monstres dans 6 buissons (5 dans 8 avec le pass) |
| Bibliothèque | `/library` | pass (phase 3) | étagère verrouillée ; si débloquée, lecteur provisoire |
| Espace parents | `/parents` | porte parentale | simulation d'achat, restauration, son, confidentialité |

### Accessibilité et ergonomie enfant

- Aucun texte indispensable pour l'enfant : pictogrammes, monstres, sons. Les textes visibles sont réservés aux parents.
- Chaque cible tactile porte un libellé `Semantics` en français et respecte la taille minimale des tokens (72 dp, lieux de carte entre 120 et 140 dp, bouton principal 96 dp).
- Paysage imposé sur iOS et Android, `SafeArea` partout, mise en page testée en 740 x 360, 1024 x 768 et 1366 x 1024.
- Pas de minuterie, pas de son d'échec : une mauvaise réponse fait osciller l'objet (+/- 4 degrés, 300 ms).
- La houle de la carte s'arrête si le système demande de réduire les animations.
- Taille de texte système bornée à 1,4 pour éviter les débordements.

## Conformité Kids / Families (Apple Kids Category, Google Play Families)

Choix d'architecture déjà appliqués :

1. **Aucun SDK d'analytics, de crash reporting tiers ni de publicité.** Pas de Firebase Analytics, pas de Crashlytics, pas d'AdMob. `TelemetryService` est une interface avec une implémentation `NoopTelemetryService` désactivée par défaut, qui n'envoie rien. Toute implémentation future devra être validée (aucun identifiant publicitaire, aucune donnée personnelle, consentement parental) et rester désactivable.
2. **Pas de lecteur YouTube intégré.** Le phare est derrière la porte parentale et ouvre la chaîne @LilCMonsters dans l'appli YouTube ou le navigateur (`url_launcher`, mode externe). L'interface `VideoSource` permettra plus tard une source `BrandHostedVideoSource` (vidéos hébergées par la marque, lues dans l'appli sans publicité ni suivi).
3. **Liens externes et achats toujours derrière la porte parentale.** La porte (question de multiplication, 3 réponses) protège : le phare, chaque ouverture de lien, l'espace parents et tout contenu du pass. Une réussite ouvre une session de 3 minutes, révoquée en quittant l'espace parents. La route `/parents` redirige vers la carte sans session valide.
4. **Aucune police ni ressource chargée depuis le réseau.** Polices embarquées (licences dans `assets/fonts/`), build web avec `--no-web-resources-cdn` (vérifié : aucune requête vers un domaine externe pendant les captures).
5. **Pas de compte enfant, pas de donnée personnelle.** `AuthService` prévoit au plus un compte anonyme par appareil.

Dépendances directes : `flutter_riverpod` 3.4.3, `go_router` 18.1.1, `audioplayers` 6.8.1, `url_launcher` 6.3.3 ; en développement `flutter_lints` 6.0.0. Aucun paquet Firebase, RevenueCat, analytics ou publicité dans `pubspec.lock`.

## Thème et tokens

Source prioritaire : `design/VISUAL_SYSTEM_v0.md` et `design/direction_v1.png`. Complément : les tokens du site (`site/assets/css/main.css`). Tout est centralisé dans `lib/core/theme/app_tokens.dart` ; aucun écran n'utilise de valeur en dur hors de ces tokens (exceptions listées plus bas).

- Couleurs direction V1 : lagoon `#3FC1B0`, lagoonDeep `#0B6E6A`, foam `#D4F4EE`, coral `#FF7A5C`, coralDeep `#C8432A`, sand `#FFE4BF`, mist `#B9B3C7`.
- Couleurs de marque : plum `#3A1752`, plum2 `#6E28A0` (boutons de l'espace parents), cream `#FFF6E5`, paper `#FFFDF8`, sun `#FFD60A`, sky `#E3F2FF`, night `#1B1747`, night2 `#2A2470`, et les 5 monstres.
- Bouton principal : disque corail, contour plum 4 dp, tranche coralDeep 12 dp qui disparaît à l'appui (120 ms, échelle 0,96), icône plum.
- Polices : Luckiest Guy (titres, capitales), Baloo 2 500/700/800 (libellés).

## Assets et crédits

Usage des illustrations du site lilcmonsters.com dans l'appli validé par David le 27/10/2026. Toutes les images viennent de `/workspace/lilcmonsters/site/assets/img` (variantes WebP les plus grandes publiées par le site) et sont importées par `tool/import_site_images.py` : recadrage paysage 16:10 pour les décors, carré pour le puzzle, côté long plafonné à 1600 px, WebP qualité 80 (copie à l'identique quand l'image n'a pas besoin d'être recadrée). Poids total de `assets/images/` : environ 2,3 Mo.

| Dossier | Contenu | Sources du site | Écrans |
|---|---|---|---|
| `monsters/` | les 5 monstres détourés (360 px, transparence) | `m-<nom>-360.webp` | partout (guides, plage, forêt, ombres, carte) |
| `books/` | couvertures des 10 livres d'histoires (720 px) | `story-01..10-720.webp`, catalogue `site/data/books.json` | bibliothèque, lecteur |
| `coloring/` | 5 pages à colorier (720 à 960 px) | `line-01..04-720.webp`, `printable-960.webp` | grotte |
| `scenes/` | décors des lieux | `path-5` (carte), `video-06` (plage), `path-4` (forêt), `story-05` (grotte), `night` (bibliothèque), `path-2` (phare), `path-3` (ombres), `video-02` (espace parents) | fonds d'écran sous un voile aux couleurs du lieu |
| `puzzle/` | 5 scènes carrées avec les monstres, sans texte | `path-1-1080`, `story-04-720`, `story-06-720`, `path-5-1080`, `story-07-720` | puzzle d'îlots |
| `videos/` | vignettes des vidéos publiées (960 x 540) | `video-ep1-960`, `music-make-your-chance-fr-960`, `music-no-problem-fr-960` | phare |
| `brand/` | icône de l'appli | `icon-512.png` | lanceur |

- Illustrations, couvertures et vignettes : © Little Cuddly Monsters, lilcmonsters.com. Réservées à l'appli, ne pas redistribuer.
- Le catalogue de la bibliothèque (`lib/features/library/books.dart`) reprend titres, tomes, statuts et couleurs de `site/data/books.json` ; un petit sablier signale les livres pas encore parus.
- Les chemins des décors sont centralisés dans `lib/core/content/scenes.dart` ; `ModuleScaffold` accepte un `backdrop` et un `veil` (opacité du dégradé posé dessus).
- Restent vectoriels : l'île de la carte et les buissons de la forêt (le site n'a pas d'illustration équivalente).
- Polices : voir `assets/fonts/README.md`. Sons : voir Sons et crédits.

## Sons et crédits

Sons de la phase 1 livrés par Shada le 27/10/2026 dans `assets/audio/<catégorie>/` (beach, map, ui, puzzle, shadow, common). Détail complet (source, auteur, licence, durée, sonie, retouches) : **`assets/audio/SOUNDS_MANIFEST.md`**. Tous sont sous CC0 1.0 ou dans le domaine public : usage commercial autorisé, crédit facultatif. Ces fichiers ne doivent pas être retouchés dans l'appli ; une nouvelle coupe se refait chez Shada.

Crédit proposé pour l'écran de crédits : « Sons : Kenney.nl, contributeurs OpenGameArt (rubberduck, Peludo, Thimras), Wikimedia Commons (Jarrod stanley, avphillips) ».

Format : chaque son existe en `.m4a` (AAC) et `.ogg` (Vorbis). `audioFormatFor` (`lib/core/audio/sound_effect.dart`) choisit `.m4a` sur iOS et macOS, `.ogg` ailleurs. Sur le web, Flutter déduit la plateforme du navigateur : iPhone, iPad et Mac (donc Safari) reçoivent le `.m4a`, Android, Windows et Linux le `.ogg`.

| Usage | Son |
|---|---|
| Carte : ambiance en boucle | `map/map_ambience_loop` |
| Carte : lieu ouvert / lieu verrouillé ou contenu du pass | `ui/ui_place_unlocked` / `ui/ui_place_locked` |
| Bouton maison, fermeture de l'espace parents | `ui/ui_back` |
| Boutons simples (son, phare, rejouer, taille du puzzle, couleur, buisson vide) | `ui/ui_tap` |
| Plage : ambiance en boucle | `beach/beach_ambience_loop` |
| Plage : vague, mouette, coquillage, bulles, sable | `beach/beach_wave_splash`, `beach_seagull`, `beach_shell`, `beach_bubbles`, `beach_sand` |
| Puzzle : prise d'une pièce, pièce posée, puzzle fini, mauvaise case | `puzzle/puzzle_piece_pickup`, `puzzle_piece_snap`, `puzzle_complete`, `ui/ui_place_locked` |
| Ombres : lanterne allumée (entrée, nouvelle manche) / éteinte (sortie) | `shadow/shadow_lantern_on` / `shadow_lantern_off` |
| Ombres : bonne ombre, toutes les 3 bonnes ombres, mauvaise ombre | `shadow/shadow_found`, `shadow_level_complete`, `shadow_wrong` |
| Forêt : chasse terminée ; lecteur de livre (piste provisoire) | `common/success_badge` |
| Grotte : ouverture d'une page | `ui/ui_place_unlocked` |
| Notes des 5 monstres (plage, forêt, bibliothèque) | `assets/sounds/note_*.wav` (générées, aucun équivalent livré) |

Ambiances : volume 0,55, effets 0,9 (fourchettes du manifeste). `AmbienceScope` lance la boucle à l'ouverture du lieu, l'arrête à la sortie et quand l'appli passe en arrière-plan ; couper le son l'arrête, le rétablir la relance. Boucle en `ReleaseMode.loop` d'audioplayers : boucle native sur Android (`MediaPlayer.setLooping`) et sur le web (`audio.loop`), mais sur iOS et macOS audioplayers revient au début puis relance la lecture à la fin du fichier, ce qui peut laisser un court blanc. Si on l'entend sur appareil, passer à un lecteur sans blanc (par exemple `just_audio` et `LoopingAudioSource`), sans autre dépendance.

## Assets illustrés de Margaux (version de travail)

Livrés par Margaux Vérany le 27/10/2026 (v1.2) dans `design/assets/` (voir son `README.md` et `manifest.json`, non modifiés). **Version de travail, pas encore validée par David.** Copiés tels quels, avec `2.0x/` et `3.0x/`, dans `assets/images/map/` (cartes téléphone et tablette 4:3), `assets/images/places/` (lieux exportés en 200 dp) et `assets/images/icons/` (PNG uniquement).

- Chemins et règles : **`lib/core/content/design_art.dart`**. Dispositions de carte générées depuis le manifeste par `python3 tool/sync_design_manifest.py` (écrit `lib/core/content/design_map_layouts.g.dart` et recopie les cartes ; lit `map.layouts.phone` et `map.layouts.tablet43`, ainsi que l'ancien format `map.spots`). À relancer à chaque livraison de Margaux.
- Retour aux éléments provisoires sans toucher au code : `--dart-define=DESIGN_ART_V1=false` (les tests passent dans les deux modes). Retrait définitif : passer `DesignArt.enabled` à `false`, retirer les trois dossiers de `pubspec.yaml` et de `assets/images/`.
- Règles de la carte (manifeste v1.2) : carte `tablet43` (1024 x 768 dp) quand largeur / hauteur < 1,6, sinon carte téléphone (812 x 375 dp) ; décor en `BoxFit.cover` (échelle `s`) ; lieux de `140 dp x s`, bornés entre 120 et 200 dp, centrés sur leur position du manifeste ; zone de tap circulaire de 130/140 de la taille du lieu ; HUD (son 72 dp, entrée parents 44 dp, maison 72 dp) en dp fixes ; aucun lieu dans la zone HUD.
- Pas de pictogramme de module sur les lieux de la carte : cadenas déjà dessiné sur les lieux verrouillés, anneau soleil « nouveau » et médaille du pass dessinés par l'appli.
- Entrée parents : roue dentée grise dessinée telle quelle (provisoire), sans disque, sans son, sans oscillation, sans animation ni ripple, zone tactile de 44 dp.
- Tablette 16:10 (1280 x 800, rapport 1,6) : elle reçoit la carte téléphone, rognée d'environ 225 dp de chaque côté ; la grotte, la plage et le puzzle d'îlots touchent les bords. Plutôt qu'une 3e carte, passer le seuil à 1,7 (la carte 4:3 n'y perdrait qu'environ 80 dp de lagon en haut et en bas) : à valider avec Margaux.
- Poids : environ 9 Mo de PNG (dont 5,6 Mo pour les lieux) ; à convertir en WebP une fois la série validée.

## Firebase : ce qu'il faudra faire une fois le projet créé par David

Rien n'est branché aujourd'hui : pas de `flutterfire configure`, pas de `firebase_options.dart`, pas de fichiers `google-services.json` ou `GoogleService-Info.plist`.

1. David crée le projet Firebase (région UE conseillée, RGPD) et ajoute les applis iOS `com.lilcmonsters.seamonsters` et Android `com.lilcmonsters.seamonsters`.
2. `dart pub global activate flutterfire_cli` puis `flutterfire configure` : génère `lib/firebase_options.dart` et les fichiers de configuration natifs.
3. Ajouter uniquement `firebase_core`, `firebase_auth`, `firebase_storage`, `firebase_remote_config`. **Ne pas ajouter** `firebase_analytics` ni `firebase_crashlytics` (conformité Kids).
4. Écrire `FirebaseAuthService` (connexion anonyme), `FirebaseStorageService` (livres audio, pages de coloriage, vidéos de la marque), `FirebaseRemoteConfigService` (clés de `RemoteConfigKeys`) dans `lib/core/backend/`.
5. Dans `lib/app/bootstrap.dart` : `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` puis remplir `buildOverrides()` (exemple en commentaire dans le fichier).
6. Règles Storage en lecture seule pour les contenus publics, aucune écriture depuis l'appli enfant.

## Prochaines étapes

1. Valider la direction V1 avec Margaux Vérany, puis faire dessiner les éléments encore vectoriels (île de la carte, buissons de la forêt) et des monstres détourés en plus haute définition.
2. Persister la progression et les réglages (`shared_preferences`).
3. Coloriage par zones (remplissage) et sauvegarde des dessins.
4. Voix des guides (consignes parlées), notes des monstres définitives, réglage de volume plafonné, mode calme, écoute des boucles sur iPhone et Android.
5. Livres audio animés : narration, synchronisation, téléchargement depuis Storage.
6. Phase 3 : `RevenueCatEntitlementService` derrière `EntitlementService` (un produit « Pass Monstres »), écran d'offre dans l'espace parents uniquement.
7. Localisation anglaise (ARB) : les livres sont en anglais.
8. Test de 5 minutes avec 2 ou 3 enfants (taille des boutons, compréhension du cadenas), puis bêta d'une semaine.

## En attente de l'accord de David

- Création du projet Firebase et choix de la région.
- Création des comptes Apple Developer, Google Play Console et RevenueCat, prix et contenu du pass.
- Création d'un dépôt Git distant et de l'intégration continue.
- Choix des guides par lieu (proposition de la direction V1) et ton des voix.
- Politique de confidentialité, entité éditrice, catégorie Kids (Apple) et programme Families (Google).
- Toute éventuelle mesure d'usage (aujourd'hui aucune).

## Écarts connus avec la direction V1

- Les icônes sont des Material Icons arrondies dans une tuile colorée à contour plum, pas encore les objets dessinés de la spec (coquillage, crayon, loupe...).
- Pas d'animation de « respiration » du bouton principal ni de panoramique caméra entre la carte et les lieux (fondu et léger zoom de 350 ms à la place).
- Les polices sont des sous-ensembles latins convertis depuis les woff2 du site ; la spec conseille les TTF complets de Google Fonts. Luckiest Guy est sous licence Apache 2.0 (pas OFL), Baloo 2 sous OFL 1.1.
- Pas de retour haptique ni de rejet des appuis multiples (paume).
