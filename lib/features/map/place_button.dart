import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/content/design_art.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/locked_badge.dart';
import '../../core/widgets/round_icon_button.dart';
import '../../core/widgets/wobble.dart';
import 'island_place.dart';

/// Un lieu sur la carte : disque jouet avec son guide et un pictogramme.
/// Etats lisibles sans texte : ouvert, verrouille (brume + cadenas,
/// oscillation au toucher), pass (couronne).
class PlaceButton extends ConsumerStatefulWidget {
  const PlaceButton({
    super.key,
    required this.place,
    required this.unlocked,
    required this.premiumOwned,
    required this.onOpen,
  });

  final IslandPlace place;
  final bool unlocked;
  final bool premiumOwned;
  final VoidCallback onOpen;

  @override
  ConsumerState<PlaceButton> createState() => _PlaceButtonState();
}

class _PlaceButtonState extends ConsumerState<PlaceButton> {
  int _wobble = 0;
  bool _justUnlocked = false;

  @override
  void didUpdateWidget(PlaceButton old) {
    super.didUpdateWidget(old);
    if (!old.unlocked && widget.unlocked) _justUnlocked = true;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final locked = !widget.unlocked;
    final label = locked ? '${p.label}. ${S.locked}' : p.label;
    final isShadow = p == IslandPlace.shadows;

    Widget guide = Image.asset(p.guide.asset, fit: BoxFit.contain);
    if (isShadow) {
      guide = ColorFiltered(
        colorFilter: ColorFilter.mode(
          AppColors.plum.withValues(alpha: .85),
          BlendMode.srcIn,
        ),
        child: guide,
      );
    }

    return Wobble(
      trigger: _wobble,
      child: BouncyButton(
        semanticLabel: label,
        onTap: () {
          if (locked) {
            ref.read(audioServiceProvider).play(SoundEffect.placeLocked);
            setState(() => _wobble++);
            return;
          }
          setState(() => _justUnlocked = false);
          widget.onOpen();
        },
        child: DesignArt.enabled
            ? _artPlace(p, locked)
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ToyDisc(
                      color: locked ? AppColors.mist : AppColors.paper,
                      edgeColor: locked ? AppColors.mistDeep : p.guide.color,
                      ring: _justUnlocked ? AppColors.sun : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                        child: Opacity(opacity: locked ? .45 : 1, child: guide),
                      ),
                    ),
                  ),
                  // Pictogramme du module, en bas a gauche.
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: _IconTile(icon: p.icon, color: p.guide.color),
                  ),
                  if (locked)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: PadlockBadge(
                        key: Key('locked-${p.name}'),
                        size: 44,
                      ),
                    )
                  else if (!widget.premiumOwned)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: CrownBadge(size: 40),
                    ),
                ],
              ),
      ),
    );
  }

  /// Lieu illustre (assets de travail de Margaux) : le cadenas est deja
  /// dessine sur la version verrouillee ; l'anneau soleil "vient d'etre
  /// debloque" et la medaille du pass restent dessines par l'appli.
  Widget _artPlace(IslandPlace p, bool locked) => Stack(
    clipBehavior: Clip.none,
    children: [
      if (_justUnlocked)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sun, width: AppSizes.sunRing),
            ),
          ),
        ),
      Positioned.fill(
        child: Image.asset(
          DesignArt.place(p.artId, locked: locked),
          key: locked ? Key('locked-${p.name}') : null,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      ),
      // Pictogramme du module, en bas a gauche.
      Positioned(
        left: -4,
        bottom: -4,
        child: Image.asset(DesignArt.icon(p.iconArt), width: 48, height: 48),
      ),
      if (!locked && !widget.premiumOwned)
        const Positioned(right: -4, top: -4, child: CrownBadge(size: 40)),
    ],
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16), // ~33 % (spec icones)
      border: Border.all(color: AppColors.plum, width: 3),
    ),
    child: Icon(icon, color: AppColors.plum, size: 30),
  );
}
