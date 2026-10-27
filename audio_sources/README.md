# Sources audio hors bundle

`beach/` : les 5 bruitages d'origine de Shada pour la plage (vague, mouette,
coquillage, bulles, sable), en .ogg et .m4a, octet pour octet identiques aux
fichiers livres (licences et provenance : assets/audio/SOUNDS_MANIFEST.md).
L'appli joue leurs copies de niveau, `assets/audio_mix/beach/`, generees par
`python3 tool/normalize_pads.py` (`--check` pour mesurer sans reecrire).
Ce dossier n'est pas declare dans pubspec.yaml : rien n'est embarque.
L'ambiance de la plage (`beach_ambience_loop`) reste dans assets/audio/beach/.
