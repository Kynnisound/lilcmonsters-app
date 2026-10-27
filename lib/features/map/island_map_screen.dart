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
import '../../core/theme/app_insets.dart';
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
      // Laissez-passer a usage unique pour l'ecran demande (le phare).
      ref.read(parentalAccessProvider).issuePass(ParentalPurpose.lighthouse);
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
    // Retour systeme sur la carte : rien (P1-T-03), jamais de sortie
    // accidentelle de l'appli.
    return PopScope(
      canPop: false,
      child: AmbienceScope(
        ambience: Ambience.map,
        child: _scaffold(progress, muted, entitlements),
      ),
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
                ? layout.placeSize(scale)
                : (size.shortestSide * .3).clamp(
                    AppSizes.mapSpotMin,
                    AppSizes.mapSpotMax,
                  );
            // Lieux hors des bords de gestes systeme (20 dp).
            final area = Rect.fromLTRB(
              pad.left + AppInsets.edge,
              pad.top + AppInsets.edge,
              size.width - pad.right - AppInsets.edge,
              size.height - pad.bottom - AppInsets.edge,
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
            // Boutons du HUD (taille fixe, ancres a l'ecran) : prioritaires.
            // Un lieu dont la boite les approcherait a moins de 8 dp passe
            // dessous ; aucun cercle de tap ne les approche a moins de 8 dp.
            final hudRight = size.width - pad.right - AppInsets.edge;
            final hudTop = pad.top + AppInsets.edge;
            final parentsRect = Rect.fromLTWH(
              hudRight - AppInsets.adultTouch,
              hudTop,
              AppInsets.adultTouch,
              AppInsets.adultTouch,
            );
            final muteRect = Rect.fromLTWH(
              parentsRect.left - AppSizes.gap - AppSizes.homeButton,
              hudTop,
              AppSizes.homeButton,
              AppSizes.homeButton,
            );
            final hudButtons = muteRect
                .expandToInclude(parentsRect)
                .inflate(AppInsets.targetSpacing);
            Rect placeRect(IslandPlace p) {
              final c = center(p);
              final left = (c.dx - spot / 2).clamp(
                area.left,
                area.right - spot,
              );
              var top = (c.dy - spot / 2).clamp(area.top, area.bottom - spot);
              final r = Rect.fromLTWH(left, top, spot, spot);
              if (DesignArt.enabled && r.overlaps(hudButtons)) {
                top = min(hudButtons.bottom, area.bottom - spot);
              }
              return Rect.fromLTWH(left, top, spot, spot);
            }

            final rects = {for (final p in IslandPlace.values) p: placeRect(p)};
            // Zones de tap circulaires espacees d'au moins 8 dp (BUG-010) :
            // le dessin garde sa taille, seul le cercle de tap se resserre.
            final taps = DesignArt.tapDiameters(
              [for (final p in IslandPlace.values) rects[p]!.center],
              DesignArt.enabled ? layout.tapFor(spot) : spot,
              avoid: [muteRect, parentsRect],
            );

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
                    left: rects[place]!.left,
                    top: rects[place]!.top,
                    width: spot,
                    height: spot,
                    child: PlaceButton(
                      key: Key('place-${place.name}'),
                      place: place,
                      tapRatio: taps[place.index] / spot,
                      unlocked: _unlocked(place, progress),
                      premiumOwned:
                          place.feature == null ||
                          entitlements.contains(place.feature),
                      onOpen: () => _open(place),
                    ),
                  ),
                // Coin adulte, en haut a droite : son + entree parents, a
                // 20 dp des bords (zones de gestes systeme), sous l'encoche.
                Positioned(
                  top: pad.top + AppInsets.edge,
                  right: pad.right + AppInsets.edge,
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
                      _ParentEntry(onTap: () => openParentsSpace(context, ref)),
                    ],
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

/// Entree de l'espace parents : volontairement discrete (dessin de 44 dp)
/// dans une zone de toucher de 48 dp (minimum Android, BUG-009).
class _ParentEntry extends StatelessWidget {
  const _ParentEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: S.parents,
    excludeSemantics: true,
    // Action exposee aux lecteurs d'ecran (BUG-008).
    onTap: onTap,
    // Volontairement inerte (retour QA) : ni son, ni oscillation, ni
    // animation, ni ripple ; zone tactile opaque de 48 dp.
    child: GestureDetector(
      key: const Key('parents-entry'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: AppInsets.adultTouch,
        child: Center(
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
      ),
    ),
  );
}
