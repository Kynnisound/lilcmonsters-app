import 'dart:math';

import '../../core/content/monsters.dart';

/// Une manche du jeu d'ombres : retrouver l'ombre du monstre montre.
class ShadowRound {
  const ShadowRound(this.target, this.options);

  factory ShadowRound.random(
    Random rng, {
    int optionCount = 3,
    Monster? avoid,
  }) {
    final pool = [...Monster.values]..shuffle(rng);
    final target = pool.firstWhere((m) => m != avoid, orElse: () => pool.first);
    final others = pool.where((m) => m != target).take(optionCount - 1);
    final options = [target, ...others]..shuffle(rng);
    return ShadowRound(target, options);
  }

  final Monster target;
  final List<Monster> options;

  bool isCorrect(Monster choice) => choice == target;
}
