import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/ambience_scope.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';

import 'dart:math';

import '../../core/content/design_art.dart';
import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/entitlements/entitlement_providers.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/l10n/strings.dart';
import '../../core/parental/parental_gate.dart';
import '../../core/progress/progress.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/round_icon_button.dart';
import 'island_painter.dart';
import 'island_place.dart';
import 'place_button.dart';

/// Ecran d'entree : la carte de l'ile.
class IslandMapScreen extends ConsumerStatefulWidget {
  const IslandMapScreen({super.key});

  @override
  ConsumerState<IslandMapScreen> createState() => _IslandMapScreenState();
}

class _IslandMapScreenState extends ConsumerState<IslandMapScreen>
    with SingleTickerProviderStateMixin {
  // Houle tres lente (une boucle toutes les 8 s).
  late final AnimationController _sea = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _sea.stop();
    } else if (!_sea.isAnimating) {
      _sea.repeat();
    }
  }

  @override
  void dispose() {
    _sea.dispose();
    super.dispose();
  }

  bool _unlocked(IslandPlace p, Progress progress) => switch (p) {
    IslandPlace.puzzle => progress.puzzleUnlocked,
    IslandPlace.shadows => progress.shadowsUnlocked,
    _ => true,
  };

  Future<void> _open(IslandPlace place) async {
    final audio = ref.read(audioServiceProvider);
    if (place.access == PlaceAccess.parental) {
      audio.play(SoundEffect.uiTap);
      if (!await requestParentalAccess(context, ref)) return;
      if (!mounted) return;
    } else {
      audio.play(SoundEffect.placeUnlocked);
    }
    if (mounted) context.go(place.route);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final muted = ref.watch(mutedProvider);
    final entitlements = ref.watch(entitlementsProvider).value ?? const {};

    // Ambiance de l'ile (oiseaux, mer au loin) tant que la carte est visible.
    return AmbienceScope(
      ambience: Ambience.map,
      child: _scaffold(progress, muted, entitlements),
    );
  }

  Widget _scaffold(
    Progress progress,
    bool muted,
    Set<PremiumFeature> entitlements,
  ) {
    return Scaffold(
      backgroundColor: AppColors.lagoon,
      body: Semantics(
        label: S.map,
        container: true,
        explicitChildNodes: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = MediaQuery.paddingOf(context);
            final size = constraints.biggest;
            // Assets de Margaux : carte telephone ou tablette 4:3 (manifeste),
            // en cover, reduite si besoin pour garder la largeur utile.
            final layout = DesignArt.layoutFor(size);
            final frame = layout.frame;
            final scale = layout.scaleFor(size);
            // Lieux : grandissent avec le decor (120 a 200 dp) ; mode de
            // repli : 120 a 140 dp selon l'ecran.
            final spot = DesignArt.enabled
                ? DesignArt.placeSize(scale)
                : (size.shortestSide * .3).clamp(
                    AppSizes.mapSpotMin,
                    AppSizes.mapSpotMax,
                  );
            final area = Rect.fromLTRB(
              pad.left + 8,
              pad.top + 8,
              size.width - pad.right - 8,
              size.height - pad.bottom - 8,
            );
            final origin = Offset(
              (size.width - frame.width * scale) / 2,
              (size.height - frame.height * scale) / 2,
            );
            Offset onMap(Offset dp) => origin + dp * scale;
            Offset center(IslandPlace p) => DesignArt.enabled
                ? onMap(layout.spots[p.artId]!)
                : Offset(
                    area.left + p.position.dx * area.width,
                    area.top + p.position.dy * area.height,
                  );
            final guideH = (DesignArt.guideHeight * scale).clamp(64.0, 110.0);
            final foot = layout.guideFoot == null
                ? null
                : onMap(layout.guideFoot!);
            // Zone du HUD a l'ecran (boutons de taille fixe en haut a droite) :
            // un lieu qui la chevaucherait passe dessous.
            final hudFrame = Rect.fromPoints(
              onMap(layout.hud.topLeft),
              onMap(layout.hud.bottomRight),
            );
            final hud = Rect.fromLTRB(
              min(hudFrame.left, size.width - pad.right - _hudWidth),
              0,
              size.width,
              max(hudFrame.bottom, pad.top + 12 + AppSizes.homeButton),
            );
            Rect placeRect(IslandPlace p) {
              final c = center(p);
              final left = (c.dx - spot / 2).clamp(
                area.left,
                area.right - spot,
              );
              var top = (c.dy - spot / 2).clamp(area.top, area.bottom - spot);
              final r = Rect.fromLTWH(left, top, spot, spot);
              if (DesignArt.enabled && r.overlaps(hud)) {
                top = min(hud.bottom, area.bottom - spot);
              }
              return Rect.fromLTWH(left, top, spot, spot);
            }

            return Stack(
              children: [
                if (DesignArt.enabled) ...[
                  Positioned(
                    left: origin.dx,
                    top: origin.dy,
                    width: frame.width * scale,
                    height: frame.height * scale,
                    child: ExcludeSemantics(
                      child: Image.asset(layout.image, fit: BoxFit.fill),
                    ),
                  ),
                  // Le guide (Fuzzle) attend sur son emplacement vide.
                  if (foot != null)
                    Positioned(
                      left: foot.dx - guideH * .45,
                      top: foot.dy - guideH,
                      height: guideH,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: Image.asset(Monster.fuzzle.asset),
                        ),
                      ),
                    ),
                ] else ...[
                  // Mer, phare et bateau des monstres (illustration du site).
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Image.asset(
                        Scenes.map,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _sea,
                        builder: (_, _) => CustomPaint(
                          painter: IslandPainter(_sea.value, seaVeil: .5),
                        ),
                      ),
                    ),
                  ),
                ],
                for (final place in IslandPlace.values)
                  Positioned(
                    left: placeRect(place).left,
                    top: placeRect(place).top,
                    width: spot,
                    height: spot,
                    child: PlaceButton(
                      key: Key('place-${place.name}'),
                      place: place,
                      unlocked: _unlocked(place, progress),
                      premiumOwned:
                          place.feature == null ||
                          entitlements.contains(place.feature),
                      onOpen: () => _open(place),
                    ),
                  ),
                // Coin adulte, en haut a droite : son + entree parents (44 dp).
                Positioned(
                  top: pad.top + 12,
                  right: pad.right + 12,
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoundIconButton(
                          key: const Key('mute-button'),
                          icon: muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          iconAsset: DesignArt.enabled
                              ? (muted ? DesignArt.soundOff : DesignArt.soundOn)
                              : null,
                          semanticLabel: muted ? S.soundOff : S.soundOn,
                          color: AppColors.foam,
                          edgeColor: AppColors.lagoonDeep,
                          onTap: () {
                            ref
                                .read(audioServiceProvider)
                                .play(SoundEffect.uiTap);
                            ref.read(mutedProvider.notifier).toggle();
                          },
                        ),
                        const SizedBox(width: AppSizes.gap),
                        _ParentEntry(
                          onTap: () async {
                            if (await requestParentalAccess(context, ref) &&
                                context.mounted) {
                              context.push(Routes.parents);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Largeur du HUD en haut a droite : bouton son 72 dp, ecart, entree
/// parents 44 dp, marge 12 dp.
const _hudWidth =
    12 + AppSizes.homeButton + AppSizes.gap + AppSizes.parentEntry + 12;

/// Entree de l'espace parents : volontairement discrete (44 dp).
class _ParentEntry extends StatelessWidget {
  const _ParentEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: S.parents,
    excludeSemantics: true,
    // Volontairement inerte (retour QA) : ni son, ni oscillation, ni
    // animation, ni ripple ; zone tactile opaque de 44 dp minimum.
    child: GestureDetector(
      key: const Key('parents-entry'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: AppSizes.parentEntry,
        child: DesignArt.enabled
            // Roue dentee grise de Margaux (provisoire), dessinee telle
            // quelle, sans disque ni relief.
            ? Image.asset(DesignArt.parentalGate)
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.paper.withValues(alpha: .8),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.plum, width: 2),
                ),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  size: 24,
                  color: AppColors.plum,
                ),
              ),
      ),
    ),
  );
}
