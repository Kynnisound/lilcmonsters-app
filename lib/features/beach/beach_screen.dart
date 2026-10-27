import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/l10n/strings.dart';
import '../../core/progress/progress.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/round_icon_button.dart';
import 'sound_pad.dart';

/// La plage : bac a sable sonore. Chaque monstre chante une note de la
/// gamme pentatonique (impossible de "jouer faux"), les objets font des
/// bruitages. Trois sons joues debloquent le puzzle d'ilots.
class BeachScreen extends ConsumerWidget {
  const BeachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Midi scintillant : la mer des monstres sous un voile ciel, lagon
    // puis sable. Guide : Pip.
    return ModuleScaffold(
      semanticTitle: S.beach,
      backdrop: Scenes.beach,
      veil: .6,
      guide: Monster.pip,
      colors: const [
        AppColors.sky,
        AppColors.foam,
        AppColors.lagoon,
        AppColors.sand,
      ],
      stops: const [0, .3, .55, .62],
      child: LayoutBuilder(
        builder: (context, c) {
          // 5 monstres en haut, 4 objets en bas, tailles bornees 72..120.
          final padSide = min(
            AppSizes.pad,
            max(AppSizes.minTouch, min(c.maxWidth / 6.2, c.maxHeight / 2.6)),
          );
          Widget row(Iterable<SoundPadData> pads) => Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSizes.gap,
            runSpacing: AppSizes.gap / 2,
            children: [
              for (final p in pads)
                _Pad(key: Key('pad-${p.id}'), data: p, side: padSide),
            ],
          );
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  row(beachPads.where((p) => p.monster != null)),
                  const SizedBox(height: AppSizes.gap),
                  row(beachPads.where((p) => p.monster == null)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Pad extends ConsumerStatefulWidget {
  const _Pad({super.key, required this.data, required this.side});
  final SoundPadData data;
  final double side;

  @override
  ConsumerState<_Pad> createState() => _PadState();
}

class _PadState extends ConsumerState<_Pad> {
  int _hops = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return BouncyButton(
      semanticLabel: d.label,
      size: Size.square(widget.side),
      onTap: () {
        ref.read(audioServiceProvider).play(d.effect);
        ref.read(progressProvider.notifier).beachSoundPlayed();
        setState(() => _hops++);
      },
      child: ToyDisc(
        color: d.monster != null ? AppColors.paper : d.color,
        edgeColor: d.monster != null
            ? d.color
            : Color.lerp(d.color, AppColors.plum, .35)!,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_hops),
          tween: Tween(begin: 1, end: 0),
          duration: AppMotion.t2,
          curve: AppMotion.soft,
          builder: (_, v, child) => Transform.translate(
            offset: Offset(0, -10 * sin(v * pi)),
            child: child,
          ),
          child: d.monster != null
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(d.monster!.asset, fit: BoxFit.contain),
                )
              : Icon(d.icon, size: widget.side * .45, color: AppColors.plum),
        ),
      ),
    );
  }
}
