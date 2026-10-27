import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_service.dart';
import 'sound_effect.dart';

/// Implementation basee sur le plugin audioplayers (iOS, Android, web).
/// Format choisi par plateforme : .m4a sur iOS / macOS (et Safari), .ogg
/// ailleurs (voir [audioFormatFor]).
class AudioplayersAudioService implements AudioService {
  AudioplayersAudioService({int poolSize = 4})
    : _pool = List.generate(poolSize, (_) => AudioPlayer());

  /// Volume des ambiances (manifeste : 0,5 a 0,6) et des effets (0,8 a 1).
  static const ambienceVolume = .55;
  static const effectVolume = .9;

  final List<AudioPlayer> _pool;
  final AudioPlayer _track = AudioPlayer();
  final AudioPlayer _ambiencePlayer = AudioPlayer();
  int _next = 0;
  bool _muted = false;

  /// Ambiance voulue par l'ecran courant (reprise apres coupure du son).
  Ambience? _ambience;
  bool _ambiencePlaying = false;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> play(SoundEffect effect) async {
    if (_muted) return;
    // Web : le navigateur refuse le son avant le premier geste. L'ambiance
    // refusee au lancement repart au premier effet (donc au premier toucher).
    if (_ambience != null && !_ambiencePlaying) unawaited(_startAmbience());
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await player.stop();
      await player.play(AssetSource(effect.asset), volume: effectVolume);
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
      await _track.play(AssetSource(resolveAudioAsset(assetPath)));
    } catch (e) {
      debugPrint('Piste indisponible ($assetPath) : $e');
    }
  }

  @override
  Future<void> stopTrack() => _track.stop();

  @override
  Future<void> playAmbience(Ambience ambience) async {
    if (_ambience == ambience && _ambiencePlaying) return;
    _ambience = ambience;
    await _startAmbience();
  }

  Future<void> _startAmbience() async {
    final a = _ambience;
    if (a == null || _muted) return;
    try {
      await _ambiencePlayer.stop();
      // Boucle native du lecteur (fichiers coupes sur un fondu de raccord).
      await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
      await _ambiencePlayer.play(AssetSource(a.asset), volume: ambienceVolume);
      _ambiencePlaying = true;
    } catch (e) {
      debugPrint('Ambiance indisponible ($a) : $e');
    }
  }

  @override
  Future<void> stopAmbience(Ambience ambience) async {
    if (_ambience != ambience) return;
    _ambience = null;
    _ambiencePlaying = false;
    await _ambiencePlayer.stop();
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) {
      await _track.stop();
      await _ambiencePlayer.stop();
      _ambiencePlaying = false;
      for (final p in _pool) {
        await p.stop();
      }
    } else {
      await _startAmbience();
    }
  }

  @override
  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    await _track.dispose();
    await _ambiencePlayer.dispose();
  }
}
