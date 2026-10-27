import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/monsters.dart';
import '../l10n/strings.dart';
import '../router/routes.dart';
import '../theme/app_tokens.dart';
import 'round_icon_button.dart';

/// Bouton maison : 72 dp, toujours en haut a gauche, meme icone partout.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) => RoundIconButton(
    key: const Key('home-button'),
    icon: Icons.home_rounded,
    semanticLabel: S.backToMap,
    onTap: () => context.go(Routes.map),
  );
}

/// Cadre commun d'un module : ambiance du lieu (illustration du decor sous
/// un voile aux couleurs du lieu, ou degrade seul), zones sures, bouton
/// maison en haut a gauche, guide du lieu en bas a droite.
class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({
    super.key,
    required this.semanticTitle,
    required this.colors,
    required this.child,
    this.guide,
    this.guideSilhouette = false,
    this.trailing,
    this.stops,
    this.backdrop,
    this.backdropAlignment = Alignment.center,
    this.veil = defaultVeil,
  });

  /// Opacite du voile par defaut : le decor reste lisible sans voler la
  /// vedette aux cibles tactiles de l'enfant.
  static const defaultVeil = .45;

  final String semanticTitle;
  final List<Color> colors;
  final List<double>? stops;
  final Widget child;
  final Monster? guide;
  final bool guideSilhouette;
  final Widget? trailing;

  /// Illustration du decor (asset), recadree pour couvrir l'ecran.
  final String? backdrop;
  final Alignment backdropAlignment;

  /// Opacite (0..1) du degrade pose sur l'illustration.
  final double veil;

  @override
  Widget build(BuildContext context) {
    Widget? guideImage;
    if (guide != null) {
      guideImage = Image.asset(guide!.asset, height: 110);
    }
    LinearGradient gradient(double alpha) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [for (final c in colors) c.withValues(alpha: alpha)],
      stops: stops,
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient(1)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (backdrop != null) ...[
              ExcludeSemantics(
                child: Image.asset(
                  backdrop!,
                  fit: BoxFit.cover,
                  alignment: backdropAlignment,
                  gaplessPlayback: true,
                ),
              ),
              DecoratedBox(decoration: BoxDecoration(gradient: gradient(veil))),
            ],
            SafeArea(
              child: Semantics(
                label: semanticTitle,
                container: true,
                explicitChildNodes: true,
                child: Stack(
                  children: [
                    if (guideImage != null)
                      Positioned(
                        right: 8,
                        bottom: 4,
                        child: ExcludeSemantics(child: guideImage),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.homeButton + AppSizes.gap,
                          12,
                          AppSizes.homeButton + AppSizes.gap,
                          12,
                        ),
                        child: child,
                      ),
                    ),
                    const Positioned(left: 12, top: 12, child: HomeButton()),
                    if (trailing != null)
                      Positioned(right: 12, top: 12, child: trailing!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
