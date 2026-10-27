import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/content/game_random.dart';
import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/l10n/strings.dart';
import '../../core/progress/progress.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/wobble.dart';
import 'shadow_game.dart';

/// Jeu d'ombres : la lanterne de Bitsy montre un monstre, l'enfant le
/// glisse (ou touche) sur son ombre. Pas d'echec : une ombre fausse
/// oscille doucement.
class ShadowsScreen extends ConsumerStatefulWidget {
  const ShadowsScreen({super.key});

  @override
  ConsumerState<ShadowsScreen> createState() => _ShadowsScreenState();
}

class _ShadowsScreenState extends ConsumerState<ShadowsScreen> {
  late ShadowRound _round;
  Monster? _solved;
  final Map<Monster, int> _wobbles = {};
  int _celebrations = 0;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _round = ShadowRound.random(ref.read(gameRandomProvider));
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  void _choose(Monster m) {
    if (_solved != null) return;
    final audio = ref.read(audioServiceProvider);
    if (_round.isCorrect(m)) {
      audio.play(SoundEffect.success);
      ref.read(progressProvider.notifier).shadowFound();
      setState(() {
        _solved = m;
        _celebrations++;
      });
      _next = Timer(AppMotion.t4, () {
        if (!mounted) return;
        setState(() {
          _round = ShadowRound.random(
            ref.read(gameRandomProvider),
            avoid: _round.target,
          );
          _solved = null;
        });
      });
    } else {
      audio.play(SoundEffect.pop);
      setState(() => _wobbles[m] = (_wobbles[m] ?? 0) + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      semanticTitle: S.shadows,
      backdrop: Scenes.shadows,
      backdropAlignment: Alignment.bottomCenter,
      veil: .55,
      guide: Monster.bitsy,
      colors: const [AppColors.dusk, AppColors.duskDeep, AppColors.night2],
      child: LayoutBuilder(
        builder: (context, c) {
          final side = (c.maxHeight * .42).clamp(AppSizes.minTouch, 170.0);
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final m in _round.options)
                          Wobble(
                            trigger: _wobbles[m] ?? 0,
                            child: _ShadowSlot(
                              key: Key('shadow-${m.name}'),
                              monster: m,
                              side: side,
                              revealed: _solved == m,
                              onChoose: () => _choose(m),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _solved != null
                          ? const SizedBox.shrink()
                          : _LanternMonster(
                              key: Key('shadow-target-${_round.target.name}'),
                              monster: _round.target,
                              side: side,
                            ),
                    ),
                  ),
                ],
              ),
              if (_celebrations > 0)
                Positioned.fill(
                  child: Celebration(key: ValueKey(_celebrations)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ShadowSlot extends StatelessWidget {
  const _ShadowSlot({
    super.key,
    required this.monster,
    required this.side,
    required this.revealed,
    required this.onChoose,
  });

  final Monster monster;
  final double side;
  final bool revealed;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(monster.asset, fit: BoxFit.contain);
    return DragTarget<Monster>(
      onAcceptWithDetails: (_) => onChoose(),
      builder: (context, candidates, _) => BouncyButton(
        semanticLabel: revealed
            ? '${S.wellDone} ${monster.displayName}'
            : 'Ombre de monstre',
        size: Size.square(side),
        onTap: onChoose,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.lanternAmber.withValues(
              alpha: revealed ? .9 : .25,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: candidates.isNotEmpty || revealed
                  ? AppColors.sun
                  : AppColors.plum,
              width: candidates.isNotEmpty || revealed
                  ? AppSizes.sunRing
                  : AppSizes.outline,
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.t2,
            child: revealed
                ? image
                : ColorFiltered(
                    key: const ValueKey('shadow'),
                    colorFilter: ColorFilter.mode(
                      AppColors.plum.withValues(alpha: .85),
                      BlendMode.srcIn,
                    ),
                    child: image,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LanternMonster extends StatelessWidget {
  const _LanternMonster({super.key, required this.monster, required this.side});
  final Monster monster;
  final double side;

  @override
  Widget build(BuildContext context) {
    final view = Container(
      width: side,
      height: side,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [AppColors.sun, Color(0x00FFC56B)]),
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(monster.asset, fit: BoxFit.contain),
    );
    return Semantics(
      label: 'Monstre a placer : ${monster.displayName}',
      excludeSemantics: true,
      child: Draggable<Monster>(
        data: monster,
        feedback: view,
        childWhenDragging: Opacity(opacity: .3, child: view),
        child: view,
      ),
    );
  }
}
