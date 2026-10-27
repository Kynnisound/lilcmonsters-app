import 'dart:ui';

import '../../core/content/monsters.dart';

/// Etat d'un livre dans le catalogue du site (data/books.json).
enum BookStatus { published, newSoon, comingSoon }

/// Livre de la serie : vraie couverture du site, titre officiel (anglais),
/// couleur du catalogue pour le dos. La narration audio reste a enregistrer.
class Book {
  const Book({
    required this.id,
    required this.volume,
    required this.title,
    required this.status,
    required this.color,
    required this.narrator,
  });

  /// Identifiant du catalogue (story-01...).
  final String id;
  final int volume;

  /// Titre officiel, pour les parents et les lecteurs d'ecran.
  final String title;
  final BookStatus status;

  /// Couleur du livre dans le catalogue (dos de la couverture).
  final Color color;

  /// Monstre qui raconte l'histoire (sa note joue a l'ouverture).
  final Monster narrator;

  String get cover => 'assets/images/books/$id.webp';
  bool get isAvailable => status == BookStatus.published;
}

/// Les 10 livres d'histoires du catalogue lilcmonsters.com
/// (site/data/books.json, lu le 27/10/2026), dans l'ordre des tomes.
const books = [
  Book(
    id: 'story-01',
    volume: 1,
    title: 'Fuzzle\u2019s Very First Try',
    status: BookStatus.published,
    color: Color(0xFFFC9313),
    narrator: Monster.fuzzle,
  ),
  Book(
    id: 'story-02',
    volume: 2,
    title: 'Christmas Magic',
    status: BookStatus.published,
    color: Color(0xFFD71E3C),
    narrator: Monster.bitsy,
  ),
  Book(
    id: 'story-03',
    volume: 3,
    title: 'Spooky Fun',
    status: BookStatus.newSoon,
    color: Color(0xFF7A3FC0),
    narrator: Monster.zib,
  ),
  Book(
    id: 'story-04',
    volume: 4,
    title: 'The Lost Shell',
    status: BookStatus.comingSoon,
    color: Color(0xFF1B98D0),
    narrator: Monster.pip,
  ),
  Book(
    id: 'story-05',
    volume: 5,
    title: 'Little Bitsy, Big Space',
    status: BookStatus.comingSoon,
    color: Color(0xFF2A2470),
    narrator: Monster.bitsy,
  ),
  Book(
    id: 'story-06',
    volume: 6,
    title: 'The Tiny Dino Who Was Shy',
    status: BookStatus.comingSoon,
    color: Color(0xFF3F8F2A),
    narrator: Monster.dottie,
  ),
  Book(
    id: 'story-07',
    volume: 7,
    title: 'Everyone Has a Thing',
    status: BookStatus.comingSoon,
    color: Color(0xFFC77A12),
    narrator: Monster.fuzzle,
  ),
  Book(
    id: 'story-08',
    volume: 8,
    title: 'Not My Birthday',
    status: BookStatus.comingSoon,
    color: Color(0xFFE0457B),
    narrator: Monster.bitsy,
  ),
  Book(
    id: 'story-09',
    volume: 9,
    title: 'Fuzzle\u2019s Favorite Season',
    status: BookStatus.comingSoon,
    color: Color(0xFFE2711D),
    narrator: Monster.fuzzle,
  ),
  Book(
    id: 'story-10',
    volume: 10,
    title: 'The Wobbly Wand',
    status: BookStatus.comingSoon,
    color: Color(0xFF8A3FB0),
    narrator: Monster.zib,
  ),
];
