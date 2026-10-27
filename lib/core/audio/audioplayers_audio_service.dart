import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_service.dart';
import 'sound_effect.dart';

/// Implementation basee sur le plugin audioplayers (iOS, Android, web).
class AudioplayersAudioService implements AudioService {
  AudioplayersAudioService({int poolSize = 4})
    : _pool = List.generate(poolSize, (_) => AudioPlayer());

  final List<AudioPlayer> _pool;
  final AudioPlayer _track = AudioPlayer();
  int _next = 0;
  bool _muted = false;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> play(SoundEffect effect) async {
    if (_muted) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await player.stop();
      await player.play(AssetSource(effect.asset));
    } catch (e) {
      // Un son rate ne doit jamais bloquer le jeu d'un enfant.
      debugPrint('Audio indisponible ($effect) : $e');
    }
  }

  @override
  Future<void> playTrack(String assetPath) async {
    if (_muted) return;
    try {
      await _track.stop();
      await _track.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Piste indisponible ($assetPath) : $e');
    }
  }

  @override
  Future<void> stopTrack() => _track.stop();

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) {
      await _track.stop();
      for (final p in _pool) {
        await p.stop();
      }
    }
  }

  @override
  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    await _track.dispose();
  }
}
