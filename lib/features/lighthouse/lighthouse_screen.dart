import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/content/monsters.dart';
import '../../core/content/scenes.dart';
import '../../core/l10n/strings.dart';
import '../../core/links/link_launcher.dart';
import '../../core/parental/parental_gate.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/round_icon_button.dart';
import 'video_source.dart';

/// Le phare : videos de la marque. Toujours derriere la porte parentale ;
/// aucun lecteur YouTube integre, la chaine s'ouvre hors de l'appli.
class LighthouseScreen extends ConsumerStatefulWidget {
  const LighthouseScreen({super.key});

  @override
  ConsumerState<LighthouseScreen> createState() => _LighthouseScreenState();
}

class _LighthouseScreenState extends ConsumerState<LighthouseScreen> {
  late bool _granted = ref.read(parentalSessionProvider.notifier).isValid;

  Future<void> _open(Uri uri) async {
    // Revalide la session juste avant de quitter l'appli.
    if (!await requestParentalAccess(context, ref)) return;
    await ref.read(linkLauncherProvider).openExternal(uri);
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(videoSourceProvider);
    final videos = ref.watch(videosProvider).value ?? const [];
    return ModuleScaffold(
      semanticTitle: S.lighthouse,
      backdrop: Scenes.lighthouse,
      guide: Monster.bitsy,
      colors: const [AppColors.sunset, AppColors.peach, AppColors.coral],
      child: !_granted
          ? Center(
              child: Card(
                color: AppColors.paper,
                child: ParentalGateView(
                  onResult: (ok) {
                    if (ok) {
                      setState(() => _granted = true);
                    } else {
                      context.go(Routes.map);
                    }
                  },
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: videos.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSizes.gap),
                    itemBuilder: (context, i) {
                      final v = videos[i];
                      return BouncyButton(
                        key: Key('video-${v.id}'),
                        semanticLabel: 'Video ${v.title}, ouvre YouTube',
                        onTap: () => _open(v.externalUrl),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.m),
                              border: Border.all(
                                color: AppColors.plum,
                                width: AppSizes.outline,
                              ),
                              image: DecorationImage(
                                image: AssetImage(v.thumbnailAsset),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 64,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundIconButton.primary(
                      key: const Key('open-channel'),
                      icon: Icons.open_in_new_rounded,
                      semanticLabel: 'Ouvrir la chaine YouTube LilCMonsters',
                      onTap: () => _open(source.channelUrl),
                    ),
                    const SizedBox(width: AppSizes.gap),
                    Flexible(
                      child: Text(
                        'Pour les parents : la chaine @LilCMonsters '
                        "s'ouvre dans YouTube, hors de l'appli.",
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.plum),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
