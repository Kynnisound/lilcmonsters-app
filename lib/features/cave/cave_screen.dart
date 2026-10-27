import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/entitlements/entitlement_providers.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/premium_lock.dart';

const coloringPages = [
  'assets/images/coloring/line-01.webp',
  'assets/images/coloring/line-02.webp',
  'assets/images/coloring/line-03.webp',
  'assets/images/coloring/line-04.webp',
  'assets/images/coloring/line-05.webp',
];

/// Pastilles de couleur : les cinq monstres + soleil, lagon, corail.
const coloringPalette = [
  AppColors.fuzzle,
  AppColors.pip,
  AppColors.dottie,
  AppColors.zib,
  AppColors.bitsy,
  AppColors.sun,
  AppColors.lagoon,
  AppColors.coral,
];

/// La grotte : coloriages (contenu du pass). Apercu provisoire : la page
/// se teinte de la couleur choisie ; le vrai remplissage par zones
/// arrivera en phase 2.
class CaveScreen extends ConsumerStatefulWidget {
  const CaveScreen({super.key});

  @override
  ConsumerState<CaveScreen> createState() => _CaveScreenState();
}

class _CaveScreenState extends ConsumerState<CaveScreen> {
  int? _page;
  Color _color = AppColors.sun;

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(hasAccessProvider(PremiumFeature.coloring));
    return ModuleScaffold(
      semanticTitle: S.cave,
      backdrop: Scenes.cave,
      veil: .6,
      guide: Monster.dottie,
      colors: const [AppColors.caveViolet, AppColors.caveViolet2],
      child: _page == null ? _gallery(owned) : _canvas(_page!),
    );
  }

  Widget _gallery(bool owned) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final side = (c.maxHeight - 8).clamp(AppSizes.minTouch, 220.0);
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: coloringPages.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSizes.gap),
                itemBuilder: (context, i) {
                  final card = _PageCard(asset: coloringPages[i], side: side);
                  if (!owned) {
                    return Center(
                      child: SizedBox.square(
                        dimension: side,
                        child: PremiumLock(child: card),
                      ),
                    );
                  }
                  return Center(
                    child: BouncyButton(
                      key: Key('coloring-$i'),
                      semanticLabel: 'Coloriage ${i + 1}',
                      onTap: () {
                        ref.read(audioServiceProvider).play(SoundEffect.chime);
                        setState(() => _page = i);
                      },
                      child: card,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const ComingSoonCard(
          monster: Monster.dottie,
          parentNote:
              'Apercu : coloriage par zones et sauvegarde des dessins '
              'en phase 2. Contenu du pass (phase 3).',
        ),
      ],
    );
  }

  Widget _canvas(int i) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  border: Border.all(
                    color: AppColors.plum,
                    width: AppSizes.outline,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedSwitcher(
                  duration: AppMotion.t2,
                  child: ColorFiltered(
                    key: ValueKey(_color),
                    // Le blanc de la page prend la couleur, les traits restent.
                    colorFilter: ColorFilter.mode(
                      Color.lerp(_color, Colors.white, .35)!,
                      BlendMode.multiply,
                    ),
                    child: Image.asset(coloringPages[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.gap),
        // Pastilles 72 dp, ecart 16 dp (spec).
        SingleChildScrollView(
          child: Wrap(
            direction: Axis.vertical,
            spacing: 16,
            children: [
              for (final c in coloringPalette)
                BouncyButton(
                  semanticLabel: 'Couleur',
                  size: const Size.square(AppSizes.colorDot),
                  onTap: () {
                    ref.read(audioServiceProvider).play(SoundEffect.pop);
                    setState(() => _color = c);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c == _color ? AppColors.sun : AppColors.plum,
                        width: c == _color
                            ? AppSizes.sunRing
                            : AppSizes.outline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.asset, required this.side});
  final String asset;
  final double side;

  @override
  Widget build(BuildContext context) => Container(
    width: side,
    height: side,
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(AppRadii.m),
      border: Border.all(
        color: AppColors.lanternAmber,
        width: AppSizes.outline,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(asset, fit: BoxFit.cover),
  );
}
