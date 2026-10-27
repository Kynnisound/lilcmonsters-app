/// Chemins de navigation (go_router).
abstract final class Routes {
  static const map = '/';
  static const beach = '/beach';
  static const cave = '/cave';
  static const forest = '/forest';
  static const library = '/library';
  static const lighthouse = '/lighthouse';
  static const puzzle = '/puzzle';
  static const shadows = '/shadows';
  static const parents = '/parents';

  static String book(int index) => '$library/book/$index';
}
