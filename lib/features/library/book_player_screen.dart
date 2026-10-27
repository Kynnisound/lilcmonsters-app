import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effect.dart';
import '../../core/entitlements/entitlement_providers.dart';
import '../../core/entitlements/premium_feature.dart';
import '../../core/content/scenes.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/coming_soon_card.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/premium_lock.dart';
import '../../core/widgets/round_icon_button.dart';
import 'books.dart';

/// Lecteur de livre audio (placeholder) : grande couverture et un seul
/// gros bouton lecture / pause. La piste joue un son provisoire.
class BookPlayerScreen extends ConsumerStatefulWidget {
  const BookPlayerScreen({super.key, required this.index});
  final int index;

  @override
  ConsumerState<BookPlayerScreen> createState() => _BookPlayerScreenState();
}

class _BookPlayerScreenState extends ConsumerState<BookPlayerScreen> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final book = books[widget.index.clamp(0, books.length - 1)];
    final owned = ref.watch(hasAccessProvider(PremiumFeature.audioBooks));
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.m),
      child: Image.asset(book.cover, fit: BoxFit.cover),
    );
    return ModuleScaffold(
      semanticTitle: S.library,
      guide: book.narrator,
      backdrop: Scenes.library,
      backdropAlignment: Alignment.bottomCenter,
      veil: .6,
      colors: const [AppColors.night, AppColors.night2],
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: owned ? cover : PremiumLock(child: cover),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.gap),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (owned)
                  RoundIconButton.primary(
                    key: const Key('book-play'),
                    icon: _playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    semanticLabel: _playing ? 'Pause' : 'Ecouter',
                    onTap: () {
                      final audio = ref.read(audioServiceProvider);
                      if (_playing) {
                        audio.stopTrack();
                      } else {
                        audio.playTrack(SoundEffect.chime.asset);
                      }
                      setState(() => _playing = !_playing);
                    },
                  ),
                const SizedBox(height: AppSizes.gap),
                Flexible(
                  child: ComingSoonCard(
                    monster: book.narrator,
                    parentNote: 'Narration a enregistrer (livres en anglais).',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
