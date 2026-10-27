import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/backend/backend_providers.dart';
import '../../core/backend/remote_config_service.dart';
import '../../core/content/game_random.dart';
import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/entitlements/entitlement_providers.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/premium_lock.dart';
import 'hunt_game.dart';

/// La foret : chasse aux monstres avec Zib. Version gratuite courte
/// (3 monstres, 6 buissons) ; chasse complete dans le pass (5 monstres,
/// 8 buissons, futurs decors).
class ForestScreen extends ConsumerStatefulWidget {
  const ForestScreen({super.key});

  @override
  ConsumerState<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends ConsumerState<ForestScreen> {
  HuntGame? _game;
  bool? _gameIsFull;
  int _celebrations = 0;

  HuntGame _newGame(bool full) {
    final free =
        int.tryParse(
          ref
              .read(remoteConfigProvider)
              .getString(RemoteConfigKeys.forestFreeMonsters),
        ) ??
        3;
    return HuntGame.start(
      bushCount: full ? 8 : 6,
      monsterCount: full ? Monster.values.length : free.clamp(1, 5),
      rng: ref.read(gameRandomProvider),
    );
  }

  void _open(int bush) {
    final game = _game!;
    if (game.isOpen(bush)) return;
    final audio = ref.read(audioServiceProvider);
    final next = game.open(bush);
    final m = next.monsterAt(bush);
    audio.play(m?.note ?? SoundEffect.pop);
    setState(() => _game = next);
    if (next.isComplete) {
      audio.play(SoundEffect.success);
      setState(() => _celebrations++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final full = ref.watch(hasAccessProvider(PremiumFeature.fullMonsterHunt));
    if (_game == null || _gameIsFull != full) {
      _game = _newGame(full);
      _gameIsFull = full;
    }
    final game = _game!;
    return ModuleScaffold(
      semanticTitle: S.forest,
      backdrop: Scenes.forest,
      veil: .55,
      backdropAlignment: Alignment.bottomCenter,
      guide: Monster.zib,
      colors: const [AppColors.forestLight, AppColors.dottie, AppColors.moss],
      trailing: game.isComplete
          ? BouncyButton(
              key: const Key('forest-replay'),
              semanticLabel: 'Rejouer',
              onTap: () => setState(() => _game = _newGame(full)),
              child: const Icon(
                Icons.refresh_rounded,
                size: 56,
                color: AppColors.plum,
              ),
            )
          : null,
      child: Stack(
        children: [
          Column(
            children: [
              // Compteur sans chiffres : ombres des monstres a trouver.
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final m in game.hidden.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ColorFiltered(
                          colorFilter:
                              game.opened.any((b) => game.monsterAt(b) == m)
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                )
                              : ColorFilter.mode(
                                  AppColors.plum.withValues(alpha: .6),
                                  BlendMode.srcIn,
                                ),
                          child: Image.asset(m.asset, height: 52),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cols = game.bushCount ~/ 2;
                    final side = min(
                      (c.maxWidth - AppSizes.gap * (cols + (full ? 0 : 1))) /
                          (cols + (full ? 0 : 1)),
                      (c.maxHeight - AppSizes.gap) / 2,
                    ).clamp(AppSizes.minTouch, 150.0);
                    return Center(
                      child: Wrap(
                        spacing: AppSizes.gap,
                        runSpacing: AppSizes.gap,
                        alignment: WrapAlignment.center,
                        children: [
                          for (var b = 0; b < game.bushCount; b++)
                            _Bush(
                              key: Key('bush-$b'),
                              side: side,
                              open: game.isOpen(b),
                              monster: game.monsterAt(b),
                              onTap: () => _open(b),
                            ),
                          if (!full)
                            SizedBox.square(
                              dimension: side,
                              child: PremiumLock(child: _BushArt(side: side)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_celebrations > 0)
            Positioned.fill(child: Celebration(key: ValueKey(_celebrations))),
        ],
      ),
    );
  }
}

class _Bush extends StatelessWidget {
  const _Bush({
    super.key,
    required this.side,
    required this.open,
    required this.monster,
    required this.onTap,
  });

  final double side;
  final bool open;
  final Monster? monster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      semanticLabel: open
          ? (monster != null
                ? 'Trouve : ${monster!.displayName}'
                : 'Buisson vide')
          : 'Buisson',
      size: Size.square(side),
      onTap: open ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (open && monster != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .3, end: 1),
              duration: AppMotion.t2,
              curve: AppMotion.boing,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Image.asset(monster!.asset, height: side * .9),
            ),
          AnimatedSlide(
            offset: open ? const Offset(0, .55) : Offset.zero,
            duration: AppMotion.t2,
            curve: AppMotion.soft,
            child: AnimatedOpacity(
              opacity: open ? .55 : 1,
              duration: AppMotion.t2,
              child: _BushArt(side: side),
            ),
          ),
        ],
      ),
    );
  }
}

/// Buisson dessine (placeholder vectoriel).
class _BushArt extends StatelessWidget {
  const _BushArt({required this.side});
  final double side;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(side), painter: _BushPainter());
}

class _BushPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width * .24;
    final fill = Paint()..color = AppColors.dottie;
    final dark = Paint()..color = AppColors.moss;
    final line = Paint()
      ..color = AppColors.plum
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.outline;
    final centers = [
      Offset(s.width * .28, s.height * .62),
      Offset(s.width * .72, s.height * .62),
      Offset(s.width * .5, s.height * .42),
      Offset(s.width * .5, s.height * .7),
    ];
    var path = Path();
    for (final c in centers) {
      path = Path.combine(
        PathOperation.union,
        path,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      );
    }
    canvas.drawPath(path.shift(const Offset(0, 6)), dark);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_BushPainter old) => false;
}
