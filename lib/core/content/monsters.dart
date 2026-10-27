import 'dart:ui';

import '../audio/sound_effect.dart';
import '../theme/app_tokens.dart';

/// La bande des Little Cuddly Monsters (illustrations detourees du site).
enum Monster {
  fuzzle('Fuzzle', AppColors.fuzzle, SoundEffect.noteDo),
  pip('Pip', AppColors.pip, SoundEffect.noteRe),
  dottie('Dottie', AppColors.dottie, SoundEffect.noteMi),
  zib('Zib', AppColors.zib, SoundEffect.noteSol),
  bitsy('Bitsy', AppColors.bitsy, SoundEffect.noteLa);

  const Monster(this.displayName, this.color, this.note);

  final String displayName;
  final Color color;

  /// Note pentatonique : toutes les combinaisons sonnent juste.
  final SoundEffect note;

  String get asset => 'assets/images/monsters/$name.webp';
}
