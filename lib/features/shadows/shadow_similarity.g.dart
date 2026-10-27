// Genere par tool/shadow_similarity.py : ne pas modifier a la main.
import '../../core/content/monsters.dart';

/// IoU des silhouettes des illustrations (mode de repli), par paire.
const shadowIoU = <(Monster, Monster), double>{
  (Monster.fuzzle, Monster.pip): 0.834,
  (Monster.fuzzle, Monster.dottie): 0.716,
  (Monster.fuzzle, Monster.zib): 0.757,
  (Monster.fuzzle, Monster.bitsy): 0.897,
  (Monster.pip, Monster.dottie): 0.807,
  (Monster.pip, Monster.zib): 0.811,
  (Monster.pip, Monster.bitsy): 0.827,
  (Monster.dottie, Monster.zib): 0.774,
  (Monster.dottie, Monster.bitsy): 0.700,
  (Monster.zib, Monster.bitsy): 0.752,
};

/// IoU des ombres dessinees par Margaux (DESIGN_ART_V1), par paire.
const shadowArtIoU = <(Monster, Monster), double>{
  (Monster.fuzzle, Monster.pip): 0.377,
  (Monster.fuzzle, Monster.dottie): 0.412,
  (Monster.fuzzle, Monster.zib): 0.400,
  (Monster.fuzzle, Monster.bitsy): 0.153,
  (Monster.pip, Monster.dottie): 0.486,
  (Monster.pip, Monster.zib): 0.430,
  (Monster.pip, Monster.bitsy): 0.334,
  (Monster.dottie, Monster.zib): 0.286,
  (Monster.dottie, Monster.bitsy): 0.219,
  (Monster.zib, Monster.bitsy): 0.260,
};
