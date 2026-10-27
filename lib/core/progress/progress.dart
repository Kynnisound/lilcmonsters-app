import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_providers.dart';

/// Progression sur la carte : deblocage des ilots.
/// - Puzzle d'ilots : debloque apres [soundsToUnlockPuzzle] sons a la plage.
/// - Jeu d'ombres : debloque apres un premier puzzle termine.
/// Etat en memoire pour l'instant (a persister : shared_preferences ou
/// Firestore, voir README).
class Progress {
  const Progress({
    this.beachSounds = 0,
    this.puzzlesSolved = 0,
    this.shadowsFound = 0,
    this.unlockAll = false,
  });

  static const soundsToUnlockPuzzle = 3;

  final int beachSounds;
  final int puzzlesSolved;
  final int shadowsFound;
  final bool unlockAll;

  bool get puzzleUnlocked => unlockAll || beachSounds >= soundsToUnlockPuzzle;
  bool get shadowsUnlocked => unlockAll || puzzlesSolved > 0;

  Progress copyWith({
    int? beachSounds,
    int? puzzlesSolved,
    int? shadowsFound,
  }) => Progress(
    beachSounds: beachSounds ?? this.beachSounds,
    puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
    shadowsFound: shadowsFound ?? this.shadowsFound,
    unlockAll: unlockAll,
  );
}

class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() =>
      Progress(unlockAll: ref.watch(appConfigProvider).unlockAllIslets);

  void beachSoundPlayed() =>
      state = state.copyWith(beachSounds: state.beachSounds + 1);
  void puzzleSolved() =>
      state = state.copyWith(puzzlesSolved: state.puzzlesSolved + 1);
  void shadowFound() =>
      state = state.copyWith(shadowsFound: state.shadowsFound + 1);
}

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(
  ProgressNotifier.new,
);
