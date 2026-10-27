import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';
import 'audioplayers_audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioplayersAudioService();
  ref.onDispose(service.dispose);
  return service;
});

/// Etat du bouton son (carte). Pilote aussi le service audio.
class MutedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(audioServiceProvider).isMuted;

  Future<void> toggle() async {
    state = !state;
    await ref.read(audioServiceProvider).setMuted(state);
  }
}

final mutedProvider = NotifierProvider<MutedNotifier, bool>(MutedNotifier.new);
