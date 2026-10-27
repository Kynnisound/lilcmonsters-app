/// Sons placeholder generes par tool/gen_sounds.py (synthese maison,
/// libres de droits). A remplacer par les sons definitifs de la marque.
enum SoundEffect {
  noteDo('sounds/note_do.wav'),
  noteRe('sounds/note_re.wav'),
  noteMi('sounds/note_mi.wav'),
  noteSol('sounds/note_sol.wav'),
  noteLa('sounds/note_la.wav'),
  boing('sounds/boing.wav'),
  pop('sounds/pop.wav'),
  wave('sounds/wave.wav'),
  drum('sounds/drum.wav'),
  chime('sounds/chime.wav'),
  success('sounds/success.wav'),
  tap('sounds/tap.wav');

  const SoundEffect(this.asset);

  /// Chemin relatif a `assets/`.
  final String asset;
}
