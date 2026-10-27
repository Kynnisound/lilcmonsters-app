import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../audio/audio_providers.dart';
import '../audio/sound_effect.dart';
import '../content/design_art.dart';
import '../content/monsters.dart';
import '../l10n/strings.dart';
import '../router/routes.dart';
import '../theme/app_insets.dart';
import '../theme/app_tokens.dart';
import 'round_icon_button.dart';

/// Bouton maison : 72 dp, toujours en haut a gauche, meme icone partout.
class HomeButton extends ConsumerWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RoundIconButton(
    key: const Key('home-button'),
    icon: Icons.home_rounded,
    iconAsset: DesignArt.enabled ? DesignArt.home : null,
    semanticLabel: S.backToMap,
    onTap: () {
      ref.read(audioServiceProvider).play(SoundEffect.uiBack);
      context.go(Routes.map);
    },
  );
}

/// Cadre commun d'un module : ambiance du lieu (illustration du decor sous
/// un voile aux couleurs du lieu, ou degrade seul), zones sures, bouton
/// maison en haut a gauche, guide du lieu en bas a droite.
///
/// Retour systeme Android (BUG-004) : remonte d'un cran dans le module s'il
/// y en a un (livre -> bibliotheque), sinon revient a la carte ; jamais de
/// sortie de l'appli depuis un module.
class ModuleScaffold extends ConsumerWidget {
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
    this.padding = defaultPadding,
  });

  /// Marges du contenu : colonnes du bouton maison et de [trailing] (72 dp
  /// a 20 dp du bord, puis 8 dp d'ecart), 20 dp en haut et en bas (zones
  /// de gestes systeme).
  static const sideColumn =
      AppInsets.edge + AppSizes.homeButton + AppInsets.targetSpacing;
  static const defaultPadding = EdgeInsets.fromLTRB(
    sideColumn,
    AppInsets.edge,
    sideColumn,
    AppInsets.edge,
  );

  /// Marges du contenu (un module peut reprendre la colonne de gauche sous
  /// le bouton maison, comme le puzzle).
  final EdgeInsets padding;

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

  /// Retour systeme : un cran en arriere dans le module, sinon la carte.
  static void systemBack(BuildContext context, WidgetRef ref) {
    ref.read(audioServiceProvider).play(SoundEffect.uiBack);
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.map);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) systemBack(context, ref);
      },
      child: Scaffold(
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
                DecoratedBox(
                  decoration: BoxDecoration(gradient: gradient(veil)),
                ),
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
                        child: Padding(padding: padding, child: child),
                      ),
                      const Positioned(
                        left: AppInsets.edge,
                        top: AppInsets.edge,
                        child: HomeButton(),
                      ),
                      if (trailing != null)
                        Positioned(
                          right: AppInsets.edge,
                          top: AppInsets.edge,
                          child: trailing!,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
