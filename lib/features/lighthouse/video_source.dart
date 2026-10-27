import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend/backend_providers.dart';
import '../../core/backend/remote_config_service.dart';

/// Une video de la marque.
class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.thumbnailAsset,
    required this.externalUrl,
    this.streamUrl,
  });

  final String id;

  /// Titre pour les parents et les lecteurs d'ecran.
  final String title;
  final String thumbnailAsset;

  /// Lien ouvert hors de l'appli (YouTube), apres porte parentale.
  final Uri externalUrl;

  /// Flux lisible dans l'appli (videos hebergees par la marque, plus tard).
  /// Nul : la video ne se lit qu'en externe.
  final Uri? streamUrl;
}

/// Origine des videos du phare. Aujourd'hui : la chaine YouTube
/// @LilCMonsters ouverte en externe, sans lecteur YouTube integre.
/// Plus tard : BrandHostedVideoSource (videos de la marque sur
/// Firebase Storage ou un CDN, lues dans l'appli sans pub ni suivi).
abstract interface class VideoSource {
  Uri get channelUrl;
  Future<List<VideoItem>> listVideos();
  bool get supportsInAppPlayback;
}

class YouTubeChannelVideoSource implements VideoSource {
  YouTubeChannelVideoSource(this.channelUrl);

  @override
  final Uri channelUrl;

  @override
  bool get supportsInAppPlayback => false;

  @override
  Future<List<VideoItem>> listVideos() async => [
    // Videos publiees sur la chaine (site/data/videos.json), vignettes
    // officielles du site.
    VideoItem(
      id: 'ep1',
      title: 'Episode 1 : Fuzzle\u2019s Very First Try',
      thumbnailAsset: 'assets/images/videos/ep1.webp',
      externalUrl: channelUrl,
    ),
    VideoItem(
      id: 'make-your-chance-fr',
      title: 'Ta chance, tu la crees !',
      thumbnailAsset: 'assets/images/videos/make-your-chance-fr.webp',
      externalUrl: channelUrl,
    ),
    VideoItem(
      id: 'no-problem-fr',
      title: 'Pas d\u2019probleme !',
      thumbnailAsset: 'assets/images/videos/no-problem-fr.webp',
      externalUrl: channelUrl,
    ),
  ];
}

final videoSourceProvider = Provider<VideoSource>((ref) {
  final url = ref
      .watch(remoteConfigProvider)
      .getString(RemoteConfigKeys.youtubeChannelUrl);
  return YouTubeChannelVideoSource(Uri.parse(url));
});

final videosProvider = FutureProvider<List<VideoItem>>(
  (ref) => ref.watch(videoSourceProvider).listVideos(),
);
