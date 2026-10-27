import 'dart:math';

import '../../core/content/design_art.dart';
import '../../core/content/monsters.dart';
import 'shadow_similarity.g.dart';

/// Ressemblance de deux silhouettes affichees (IoU des masques, 1 =
/// identiques) : ombres dessinees par Margaux en mode DESIGN_ART_V1,
/// illustrations teintees sinon.
double shadowSimilarity(Monster a, Monster b, {bool art = DesignArt.enabled}) {
  if (a == b) return 1;
  final t = art ? shadowArtIoU : shadowIoU;
  return t[(a, b)] ?? t[(b, a)] ?? 1;
}

/// Une manche du jeu d'ombres : retrouver l'ombre du monstre montre.
///
/// Distracteurs (BUG-005) : parmi les combinaisons possibles, celle dont la
/// paire la plus ressemblante est la moins ressemblante possible ; deux
/// silhouettes au-dela de [maxSimilarity] ne sont jamais proposees ensemble.
/// Le tirage reste varie entre combinaisons presque aussi bonnes.
class ShadowRound {
  const ShadowRound(this.target, this.options);

  /// Seuil anti-doublon : ombres de Margaux 0,5 (mesure max 0,465,
  /// Fuzzle / Pip) ; mode de repli 0,85 (Fuzzle / Bitsy a 0,90 jamais cote
  /// a cote).
  static const maxSimilarity = DesignArt.enabled ? .5 : .85;

  /// Marge de tirage autour de la meilleure combinaison.
  static const tolerance = DesignArt.enabled ? .15 : .02;

  factory ShadowRound.random(
    Random rng, {
    int optionCount = 3,
    Monster? avoid,
  }) {
    final pool = [...Monster.values]..shuffle(rng);
    final target = pool.firstWhere((m) => m != avoid, orElse: () => pool.first);
    final others = pool.where((m) => m != target).toList();
    final combos = <List<Monster>>[];
    void build(int from, List<Monster> acc) {
      if (acc.length == optionCount - 1) {
        combos.add([...acc]);
        return;
      }
      for (var i = from; i < others.length; i++) {
        build(i + 1, [...acc, others[i]]);
      }
    }

    build(0, []);
    double score(List<Monster> combo) {
      final all = [target, ...combo];
      var worst = 0.0;
      for (var i = 0; i < all.length; i++) {
        for (var j = i + 1; j < all.length; j++) {
          worst = max(worst, shadowSimilarity(all[i], all[j]));
        }
      }
      return worst;
    }

    final scored = {for (final c in combos) c: score(c)};
    final best = scored.values.reduce(min);
    final picks = [
      for (final e in scored.entries)
        if (e.value <= best + tolerance && e.value <= maxSimilarity) e.key,
    ];
    final chosen = picks.isEmpty
        ? scored.entries.firstWhere((e) => e.value == best).key
        : picks[rng.nextInt(picks.length)];
    final options = [target, ...chosen]..shuffle(rng);
    return ShadowRound(target, options);
  }

  final Monster target;
  final List<Monster> options;

  /// Ressemblance de la paire la plus proche de la manche.
  double get worstSimilarity {
    var worst = 0.0;
    for (var i = 0; i < options.length; i++) {
      for (var j = i + 1; j < options.length; j++) {
        worst = max(worst, shadowSimilarity(options[i], options[j]));
      }
    }
    return worst;
  }

  bool isCorrect(Monster choice) => choice == target;
}
