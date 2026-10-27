import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seamonsters/core/config/app_config.dart';
import 'package:seamonsters/core/router/app_router.dart';
import 'package:seamonsters/core/router/routes.dart';

import 'helpers.dart';

void main() {
  for (final size in const [
    Size(568, 320),
    Size(640, 360),
    Size(667, 375),
    Size(740, 360),
    Size(932, 430),
    Size(1024, 768),
    Size(1366, 1024),
  ]) {
    testWidgets(
      'tous les ecrans sans debordement en ${size.width} x ${size.height}',
      (tester) async {
        final h = await pumpApp(
          tester,
          config: const AppConfig(premiumUnlocked: true, unlockAllIslets: true),
        );
        tester.view.physicalSize = size;
        // L'espace parents s'affiche comme apres la porte.
        h.access.openParentsSpace();
        final router = h.container.read(routerProvider);
        for (final route in [
          Routes.map,
          Routes.beach,
          Routes.cave,
          Routes.forest,
          Routes.library,
          Routes.book(0),
          Routes.lighthouse,
          Routes.puzzle,
          Routes.shadows,
          Routes.parents,
        ]) {
          router.go(route);
          await settle(tester);
          final e = tester.takeException();
          if (e != null) debugPrint('ROUTE $route : $e');
          expect(e, isNull, reason: route);
          expect(router.state.matchedLocation, isNot(isEmpty));
        }
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first)),
          isNotNull,
        );
      },
    );
  }
}
