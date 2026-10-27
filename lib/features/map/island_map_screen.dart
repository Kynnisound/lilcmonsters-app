import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/content/scenes.dart';
import '../../core/entitlements/entitlement_providers.dart';
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
      audio.play(SoundEffect.tap);
      if (!await requestParentalAccess(context, ref)) return;
      if (!mounted) return;
    } else {
      audio.play(place.guide.note);
    }
    if (mounted) context.go(place.route);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final muted = ref.watch(mutedProvider);
    final entitlements = ref.watch(entitlementsProvider).value ?? const {};

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
            final spot = (size.shortestSide * .3).clamp(
              AppSizes.mapSpotMin,
              AppSizes.mapSpotMax,
            );
            final area = Rect.fromLTRB(
              pad.left + 8,
              pad.top + 8,
              size.width - pad.right - 8,
              size.height - pad.bottom - 8,
            );
            return Stack(
              children: [
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
                for (final place in IslandPlace.values)
                  Positioned(
                    left:
                        (area.left + place.position.dx * area.width - spot / 2)
                            .clamp(area.left, area.right - spot),
                    top: (area.top + place.position.dy * area.height - spot / 2)
                        .clamp(area.top, area.bottom - spot),
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
                          semanticLabel: muted ? S.soundOff : S.soundOn,
                          color: AppColors.foam,
                          edgeColor: AppColors.lagoonDeep,
                          onTap: () =>
                              ref.read(mutedProvider.notifier).toggle(),
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

/// Entree de l'espace parents : volontairement discrete (44 dp).
class _ParentEntry extends StatelessWidget {
  const _ParentEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: S.parents,
    excludeSemantics: true,
    child: GestureDetector(
      key: const Key('parents-entry'),
      onTap: onTap,
      child: Container(
        width: AppSizes.parentEntry,
        height: AppSizes.parentEntry,
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
  );
}
