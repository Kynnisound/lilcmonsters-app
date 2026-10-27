import 'sound_effect.dart';

/// Abstraction audio : les ecrans ne connaissent jamais le plugin utilise.
/// Implementation par defaut : [AudioplayersAudioService].
/// Tests : [RecordingAudioService].
abstract interface class AudioService {
  bool get isMuted;

  /// Effet court, plusieurs effets peuvent se chevaucher.
  Future<void> play(SoundEffect effect);

  /// Piste longue (livre audio, musique). Une seule a la fois.
  Future<void> playTrack(String assetPath);

  Future<void> stopTrack();

  /// Ambiance du lieu, en boucle. Remplace l'ambiance en cours.
  Future<void> playAmbience(Ambience ambience);

  /// Arrete [ambience] si c'est elle qui joue (un ecran qui se ferme ne
  /// coupe pas l'ambience de l'ecran qui vient de s'ouvrir).
  Future<void> stopAmbience(Ambience ambience);

  Future<void> setMuted(bool muted);

  Future<void> dispose();
}

/// Implementation silencieuse qui memorise les appels (tests, previews).
class RecordingAudioService implements AudioService {
  final List<SoundEffect> played = [];
  final List<String> tracks = [];
  final List<Ambience> ambiences = [];
  Ambience? ambience;
  bool _muted = false;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> play(SoundEffect effect) async {
    if (!_muted) played.add(effect);
  }

  @override
  Future<void> playTrack(String assetPath) async {
    if (!_muted) tracks.add(assetPath);
  }

  @override
  Future<void> stopTrack() async {}

  @override
  Future<void> playAmbience(Ambience a) async {
    ambience = a;
    if (!_muted) ambiences.add(a);
  }

  @override
  Future<void> stopAmbience(Ambience a) async {
    if (ambience == a) ambience = null;
  }

  @override
  Future<void> setMuted(bool muted) async => _muted = muted;

  @override
  Future<void> dispose() async {}
}
