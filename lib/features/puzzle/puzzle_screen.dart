import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/content/game_random.dart';
import '../../core/content/monsters.dart';
import '../../core/l10n/strings.dart';
import '../../core/progress/progress.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/round_icon_button.dart';
import 'puzzle_game.dart';
import 'puzzle_piece.dart';

/// Images de puzzle : scenes du site ou les monstres sont bien visibles
/// (carrees, sans texte), importees par tool/import_site_images.py.
const puzzleImages = [
  'assets/images/puzzle/puzzle-01.webp',
  'assets/images/puzzle/puzzle-02.webp',
  'assets/images/puzzle/puzzle-03.webp',
  'assets/images/puzzle/puzzle-04.webp',
  'assets/images/puzzle/puzzle-05.webp',
];

/// Puzzle d'ilots : glisser chaque piece a sa place, ou toucher une piece
/// puis sa case. 2 x 2 ou 3 x 3, sans minuterie ni echec.
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  late PuzzleGame _game;
  int _imageIndex = 0;
  int _celebrations = 0;

  @override
  void initState() {
    super.initState();
    _game = PuzzleGame.start(2, ref.read(gameRandomProvider));
  }

  String get _image => puzzleImages[_imageIndex % puzzleImages.length];

  void _restart(int n, {bool nextImage = false}) {
    ref.read(audioServiceProvider).play(SoundEffect.uiTap);
    setState(() {
      if (nextImage) _imageIndex++;
      _game = PuzzleGame.start(n, ref.read(gameRandomProvider));
    });
  }

  void _drop(int piece, int slot) {
    final audio = ref.read(audioServiceProvider);
    if (!_game.fits(piece, slot)) {
      // Pas de son d'echec : un petit "non" tres doux.
      audio.play(SoundEffect.placeLocked);
      return;
    }
    setState(() => _game = _game.place(piece, slot));
    if (_game.isComplete) {
      audio.play(SoundEffect.puzzleComplete);
      ref.read(progressProvider.notifier).puzzleSolved();
      setState(() => _celebrations++);
    } else {
      audio.play(SoundEffect.pieceSnap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      semanticTitle: S.puzzle,
      guide: Monster.fuzzle,
      colors: const [AppColors.foam, AppColors.lagoon],
      trailing: Column(
        children: [
          _SizeChoice(n: 2, selected: _game.n == 2, onTap: () => _restart(2)),
          const SizedBox(height: AppSizes.gap / 2),
          _SizeChoice(n: 3, selected: _game.n == 3, onTap: () => _restart(3)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final board = min(c.maxHeight, c.maxWidth * .55);
          final cell = board / _game.n;
          final trayPiece = max(AppSizes.minTouch, min(cell * .8, 110.0));
          return Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Board(
                    game: _game,
                    image: _image,
                    side: board,
                    onDrop: _drop,
                  ),
                  const SizedBox(width: AppSizes.gap),
                  Expanded(
                    child: Center(
                      child: _game.isComplete
                          ? RoundIconButton.primary(
                              key: const Key('puzzle-next'),
                              icon: Icons.play_arrow_rounded,
                              semanticLabel: 'Puzzle suivant',
                              onTap: () => _restart(_game.n, nextImage: true),
                            )
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: AppSizes.gap / 2,
                                runSpacing: AppSizes.gap / 2,
                                children: [
                                  for (final p in _game.tray)
                                    _TrayPiece(
                                      key: Key('tray-$p'),
                                      piece: p,
                                      image: _image,
                                      n: _game.n,
                                      side: trayPiece,
                                      selected: _game.selected == p,
                                      onTap: () {
                                        ref
                                            .read(audioServiceProvider)
                                            .play(SoundEffect.piecePickup);
                                        setState(() => _game = _game.select(p));
                                      },
                                      onDragStarted: () => ref
                                          .read(audioServiceProvider)
                                          .play(SoundEffect.piecePickup),
                                    ),
                                ],
                              ),
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

class _Board extends StatelessWidget {
  const _Board({
    required this.game,
    required this.image,
    required this.side,
    required this.onDrop,
  });

  final PuzzleGame game;
  final String image;
  final double side;
  final void Function(int piece, int slot) onDrop;

  @override
  Widget build(BuildContext context) {
    final cell = side / game.n;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: AppColors.plum, width: AppSizes.outline),
      ),
      child: Stack(
        children: [
          // Image fantome pour guider l'enfant.
          Positioned.fill(
            child: Opacity(
              opacity: .18,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.m - 4),
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
          ),
          for (var slot = 0; slot < game.pieceCount; slot++)
            Positioned(
              left: (slot % game.n) * cell,
              top: (slot ~/ game.n) * cell,
              width: cell,
              height: cell,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (d) => !game.placed.contains(slot),
                onAcceptWithDetails: (d) => onDrop(d.data, slot),
                builder: (context, candidates, _) {
                  final filled = game.placed.contains(slot);
                  return Semantics(
                    button: !filled,
                    label: filled ? 'Piece posee' : 'Case ${slot + 1}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: Key('slot-$slot'),
                      behavior: HitTestBehavior.opaque,
                      onTap: game.selected == null || filled
                          ? null
                          : () => onDrop(game.selected!, slot),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: filled
                            ? PuzzlePiece(
                                image: image,
                                n: game.n,
                                index: slot,
                                side: cell - 4,
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.s,
                                  ),
                                  border: Border.all(
                                    color: candidates.isNotEmpty
                                        ? AppColors.sun
                                        : AppColors.plum.withValues(alpha: .25),
                                    width: candidates.isNotEmpty ? 6 : 2,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TrayPiece extends StatelessWidget {
  const _TrayPiece({
    super.key,
    required this.piece,
    required this.image,
    required this.n,
    required this.side,
    required this.selected,
    required this.onTap,
    required this.onDragStarted,
  });

  final int piece;
  final String image;
  final int n;
  final double side;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;

  @override
  Widget build(BuildContext context) {
    final view = PuzzlePiece(
      image: image,
      n: n,
      index: piece,
      side: side,
      highlighted: selected,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: 'Piece de puzzle',
      excludeSemantics: true,
      child: Draggable<int>(
        data: piece,
        onDragStarted: onDragStarted,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(scale: 1.08, child: view),
        ),
        childWhenDragging: Opacity(opacity: .3, child: view),
        child: GestureDetector(onTap: onTap, child: view),
      ),
    );
  }
}

/// Choix de difficulte sans texte : 4 ou 9 petits carres.
class _SizeChoice extends StatelessWidget {
  const _SizeChoice({
    required this.n,
    required this.selected,
    required this.onTap,
  });
  final int n;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BouncyButton(
    key: Key('puzzle-size-$n'),
    semanticLabel: 'Puzzle de ${n * n} pieces',
    size: const Size.square(AppSizes.minTouch),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? AppColors.sun : AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.m),
        border: Border.all(color: AppColors.plum, width: AppSizes.outline),
      ),
      child: GridView.count(
        crossAxisCount: n,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          n * n,
          (_) => DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.coral,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ),
  );
}
