import 'dart:math';

/// Logique du puzzle (sans Flutter, testable) : une image coupee en
/// n x n pieces ; chaque piece va dans la case de meme indice.
class PuzzleGame {
  PuzzleGame._(this.n, this.tray, this.placed, this.selected);

  factory PuzzleGame.start(int n, Random rng) {
    final tray = List<int>.generate(n * n, (i) => i)..shuffle(rng);
    return PuzzleGame._(n, tray, const {}, null);
  }

  final int n;

  /// Pieces encore dans le bac, dans l'ordre d'affichage.
  final List<int> tray;
  final Set<int> placed;

  /// Piece choisie au toucher (alternative au glisser-deposer).
  final int? selected;

  int get pieceCount => n * n;
  bool get isComplete => placed.length == pieceCount;

  PuzzleGame select(int piece) =>
      PuzzleGame._(n, tray, placed, selected == piece ? null : piece);

  /// Vrai si la piece correspond a la case. Sinon l'etat ne change pas.
  bool fits(int piece, int slot) => piece == slot && !placed.contains(slot);

  PuzzleGame place(int piece, int slot) {
    if (!fits(piece, slot)) return this;
    return PuzzleGame._(n, [...tray]..remove(piece), {...placed, slot}, null);
  }
}
