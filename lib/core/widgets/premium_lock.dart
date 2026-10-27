import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../audio/audio_providers.dart';
import '../audio/sound_effect.dart';
import '../l10n/strings.dart';
import '../parental/parental_gate.dart';
import '../router/routes.dart';
import 'locked_badge.dart';

/// Recouvre un contenu payant : toucher declenche la porte parentale puis
/// l'espace parents (achats). L'enfant ne voit jamais d'offre commerciale.
class PremiumLock extends ConsumerWidget {
  const PremiumLock({super.key, required this.child, this.badgeSize = 44});

  final Widget child;
  final double badgeSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: S.premium,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          ref.read(audioServiceProvider).play(SoundEffect.placeLocked);
          if (await requestParentalAccess(context, ref) && context.mounted) {
            context.push(Routes.parents);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.5, 0.3, 0.1, 0, 40, //
                  0.2, 0.6, 0.1, 0, 40, //
                  0.2, 0.3, 0.4, 0, 50, //
                  0, 0, 0, 1, 0,
                ]),
                child: child,
              ),
            ),
            Positioned(right: 6, top: 6, child: CrownBadge(size: badgeSize)),
          ],
        ),
      ),
    );
  }
}
