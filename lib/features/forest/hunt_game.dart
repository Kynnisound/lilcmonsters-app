import 'dart:math';

import '../../core/content/monsters.dart';

/// Chasse aux monstres : des buissons, certains cachent un monstre.
class HuntGame {
  HuntGame._(this.bushCount, this.hidden, this.opened);

  /// [monsterCount] monstres caches dans [bushCount] buissons.
  factory HuntGame.start({
    required int bushCount,
    required int monsterCount,
    required Random rng,
  }) {
    assert(monsterCount <= bushCount && monsterCount <= Monster.values.length);
    final bushes = List<int>.generate(bushCount, (i) => i)..shuffle(rng);
    final monsters = [...Monster.values]..shuffle(rng);
    return HuntGame._(bushCount, {
      for (var i = 0; i < monsterCount; i++) bushes[i]: monsters[i],
    }, const {});
  }

  final int bushCount;
  final Map<int, Monster> hidden;
  final Set<int> opened;

  Monster? monsterAt(int bush) => hidden[bush];
  bool isOpen(int bush) => opened.contains(bush);
  int get found => opened.where(hidden.containsKey).length;
  bool get isComplete => found == hidden.length;

  HuntGame open(int bush) => HuntGame._(bushCount, hidden, {...opened, bush});
}
