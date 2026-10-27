import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source d'aleatoire des jeux, injectable pour des tests deterministes.
final gameRandomProvider = Provider<Random>((ref) => Random());
