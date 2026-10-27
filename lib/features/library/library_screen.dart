import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/entitlements/entitlement_providers.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/l10n/strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/premium_lock.dart';
import 'books.dart';

/// La bibliotheque : livres audio (contenu du pass). Ambiance lampe de
/// chevet, chaque livre est raconte par son personnage principal.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref.watch(hasAccessProvider(PremiumFeature.audioBooks));
    return ModuleScaffold(
      semanticTitle: S.library,
      backdrop: Scenes.library,
      backdropAlignment: Alignment.bottomCenter,
      veil: .35,
      colors: const [AppColors.night, AppColors.night2],
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final side = (c.maxHeight - 8).clamp(AppSizes.minTouch, 200.0);
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: books.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSizes.gap),
                  itemBuilder: (context, i) {
                    final cover = _Cover(book: books[i], side: side);
                    if (!owned) {
                      return Center(
                        child: SizedBox.square(
                          dimension: side,
                          child: PremiumLock(child: cover),
                        ),
                      );
                    }
                    return Center(
                      child: BouncyButton(
                        key: Key('book-$i'),
                        semanticLabel:
                            'Livre ${books[i].volume} : ${books[i].title}',
                        onTap: () {
                          ref
                              .read(audioServiceProvider)
                              .play(books[i].narrator.note);
                          context.go(Routes.book(i));
                        },
                        child: cover,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const ComingSoonCard(
            monster: Monster.pip,
            parentNote:
                'Les 10 livres de la serie (sablier : pas encore paru). '
                'Narration et animations a produire. Contenu du pass '
                '(phase 3).',
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book, required this.side});
  final Book book;
  final double side;

  @override
  Widget build(BuildContext context) => Container(
    width: side,
    height: side,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.s),
      border: Border.all(color: AppColors.plum, width: 3),
      boxShadow: const [BoxShadow(color: Color(0x66FFC56B), blurRadius: 24)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(book.cover, fit: BoxFit.cover),
        // Dos du livre a la couleur du catalogue.
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 10,
          child: ColoredBox(color: book.color),
        ),
        // Livre pas encore paru : petit sablier, sans texte.
        if (!book.isAvailable)
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.plum, width: 3),
              ),
              child: Icon(
                Icons.hourglass_bottom_rounded,
                size: 24,
                color: book.color,
              ),
            ),
          ),
      ],
    ),
  );
}
