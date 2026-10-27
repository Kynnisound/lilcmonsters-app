import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/beach/beach_screen.dart';
import '../../features/cave/cave_screen.dart';
import '../../features/forest/forest_screen.dart';
import '../../features/library/book_player_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/lighthouse/lighthouse_screen.dart';
import '../../features/map/island_map_screen.dart';
import '../../features/parents/parents_screen.dart';
import '../../features/puzzle/puzzle_screen.dart';
import '../../features/shadows/shadows_screen.dart';
import '../parental/parental_gate.dart';
import '../progress/progress.dart';
import 'routes.dart';

/// Transition douce commune (fondu + leger zoom), sans texte.
CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

GoRoute _route(
  String path,
  Widget Function(GoRouterState) build, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  pageBuilder: (context, state) => _page(state, build(state)),
  routes: routes,
);

/// Ecrans qui demandent la porte parentale.
const protectedRoutes = [
  (ParentalPurpose.parentsSpace, Routes.parents),
  (ParentalPurpose.lighthouse, Routes.lighthouse),
];

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.map,
    redirect: (context, state) {
      final progress = ref.read(progressProvider);
      final loc = state.matchedLocation;
      // Ilots a debloquer : retour a la carte tant qu'ils sont fermes.
      if (loc == Routes.puzzle && !progress.puzzleUnlocked) return Routes.map;
      if (loc == Routes.shadows && !progress.shadowsUnlocked) return Routes.map;
      // Ecrans proteges (BUG-002, BUG-013) : laissez-passer de la porte a
      // usage unique, ou ecran deja ouvert. Toute navigation, y compris
      // Precedent / Suivant du navigateur, repasse par ici : quitter un
      // ecran protege le referme aussitot, sans attendre la fin de la
      // transition, et y revenir par l'historique renvoie a la carte.
      final access = ref.read(parentalAccessProvider);
      for (final (purpose, route) in protectedRoutes) {
        final here = loc == route || loc.startsWith('$route/');
        if (!here) {
          access.close(purpose);
        } else if (!access.mayShow(purpose)) {
          return Routes.map;
        }
      }
      return null;
    },
    routes: [
      _route(Routes.map, (_) => const IslandMapScreen()),
      _route(Routes.beach, (_) => const BeachScreen()),
      _route(Routes.cave, (_) => const CaveScreen()),
      _route(Routes.forest, (_) => const ForestScreen()),
      _route(
        Routes.library,
        (_) => const LibraryScreen(),
        routes: [
          _route('book/:index', (s) {
            final i = int.tryParse(s.pathParameters['index'] ?? '') ?? 0;
            return BookPlayerScreen(index: i);
          }),
        ],
      ),
      _route(Routes.lighthouse, (_) => const LighthouseScreen()),
      _route(Routes.puzzle, (_) => const PuzzleScreen()),
      _route(Routes.shadows, (_) => const ShadowsScreen()),
      _route(Routes.parents, (_) => const ParentsScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
