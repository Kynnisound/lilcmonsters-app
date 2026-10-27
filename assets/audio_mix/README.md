# Copies de niveau (appli)

Les 10 pads du bac à sable de la plage, ramenés à la même sonie perçue
(BUG-007, QA du 27/10/2026 puis retest) :

- `beach/` : copies des 5 bruitages de Shada (sources
  `audio_sources/beach/*.ogg`, hors bundle, jamais modifiées) ;
- `notes/` : les 5 notes des monstres, depuis leurs sources
  `assets/sounds/note_*.wav` (générées par `tool/gen_sounds.py`, plus
  embarquées dans l'appli).

Méthode (`python3 tool/normalize_pads.py`) : ffmpeg `loudnorm` en deux
passes (mesure, puis application en mode linéaire, donc un simple gain),
mesure EBU R128 avec `ebur128`, puis encodage en .ogg (Vorbis q5) et .m4a
(AAC 160 kb/s).

- Cible commune : sonie momentanée max (fenêtre 400 ms, la mesure du retest
  QA) à -22 LUFS, à ±0,3 LU ; crête vraie ≤ -3 dBTP. Le limiteur ne sert
  qu'au coquillage (clic de 0,19 s dont la crête est 19 dB au-dessus de la
  sonie).
- Pourquoi la sonie momentanée et pas la sonie intégrée : les pads durent
  de 0,19 s à 3,1 s, plus court qu'un bloc de mesure pour le coquillage, et
  les notes décroissent vite. À sonie intégrée égale, les notes sonneraient
  environ 5 dB plus fort que la mouette à l'oreille. La sonie intégrée est
  quand même enregistrée.
- Résultat : de -22,2 à -22,0 LUFS (écart 0,2 LU, cible P1-S-04 : 3 dB),
  crêtes de -18,3 à -3,3 dBTP. Avant : de -17,5 (mouette) à -23,1 LUFS
  (coquillage), soit 5,6 dB d'écart.
- Mesures dans `levels.json`, vérifiées par `test/qa_regression_test.dart`
  (groupe BUG-007).

Si Shada livre de nouveaux pads au bon niveau, les déposer dans
assets/audio/beach/, y pointer SoundEffect.beach* et supprimer `beach/`.
