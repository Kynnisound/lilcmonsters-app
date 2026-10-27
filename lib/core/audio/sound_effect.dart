import 'package:flutter/foundation.dart';

/// Format des sons livres par Shada (assets/audio/, deux fichiers par son).
enum AudioFormat {
  /// AAC-LC : iOS et macOS (AVPlayer ne lit pas l'Ogg Vorbis), et Safari.
  m4a,

  /// Ogg Vorbis : Android, web hors Safari, Windows, Linux.
  ogg,
}

/// Choisit le format selon la plateforme. Sur le web, Flutter deduit
/// [defaultTargetPlatform] du navigateur : tout navigateur sur iPhone, iPad
/// ou Mac (donc Safari) recoit le .m4a, que Chrome et Firefox lisent aussi.
AudioFormat audioFormatFor(TargetPlatform platform) => switch (platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => AudioFormat.m4a,
  _ => AudioFormat.ogg,
};

AudioFormat get currentAudioFormat => audioFormatFor(defaultTargetPlatform);

/// Chemin d'un son de Shada (sans extension, relatif a `assets/`) dans le
/// format de la plateforme courante. Les .wav restent tels quels.
String resolveAudioAsset(String base, [AudioFormat? format]) {
  if (base.endsWith('.wav')) return base;
  return '$base.${(format ?? currentAudioFormat).name}';
}

/// Effets courts. Sons de Shada (CC0 ou domaine public, detail dans
/// assets/audio/SOUNDS_MANIFEST.md), sauf les cinq notes des monstres,
/// generees par tool/gen_sounds.py (aucun equivalent livre).
enum SoundEffect {
  // Notes pentatoniques des monstres (synthese maison).
  noteDo('sounds/note_do.wav'),
  noteRe('sounds/note_re.wav'),
  noteMi('sounds/note_mi.wav'),
  noteSol('sounds/note_sol.wav'),
  noteLa('sounds/note_la.wav'),

  // Interface.
  uiTap('audio/ui/ui_tap'),
  uiBack('audio/ui/ui_back'),
  placeUnlocked('audio/ui/ui_place_unlocked'),
  placeLocked('audio/ui/ui_place_locked'),

  // Plage.
  beachWave('audio/beach/beach_wave_splash'),
  beachSeagull('audio/beach/beach_seagull'),
  beachShell('audio/beach/beach_shell'),
  beachBubbles('audio/beach/beach_bubbles'),
  beachSand('audio/beach/beach_sand'),

  // Puzzle.
  piecePickup('audio/puzzle/puzzle_piece_pickup'),
  pieceSnap('audio/puzzle/puzzle_piece_snap'),
  puzzleComplete('audio/puzzle/puzzle_complete'),

  // Jeu d'ombres.
  lanternOn('audio/shadow/shadow_lantern_on'),
  lanternOff('audio/shadow/shadow_lantern_off'),
  shadowFound('audio/shadow/shadow_found'),
  shadowWrong('audio/shadow/shadow_wrong'),
  shadowLevelComplete('audio/shadow/shadow_level_complete'),

  // Commun.
  success('audio/common/success_badge');

  const SoundEffect(this.base);

  /// Chemin relatif a `assets/`, sans extension pour les sons de Shada.
  final String base;

  /// Chemin relatif a `assets/` dans le format de la plateforme.
  String get asset => resolveAudioAsset(base);
}

/// Ambiances en boucle (environ -16 LUFS, fondus de raccord).
enum Ambience {
  map('audio/map/map_ambience_loop'),
  beach('audio/beach/beach_ambience_loop');

  const Ambience(this.base);
  final String base;
  String get asset => resolveAudioAsset(base);
}
