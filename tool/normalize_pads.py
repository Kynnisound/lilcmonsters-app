"""Sonie des 10 pads du bac a sable (BUG-007, retest QA du 27/10/2026).

Normalisation en sonie percue (EBU R128 / ITU-R BS.1770, LUFS) et non plus
en dBFS : les 5 bruitages de Shada (audio_sources/beach/*.ogg, hors bundle, jamais
modifies) et les 5 notes des monstres (assets/sounds/note_*.wav, generees
par tool/gen_sounds.py) sont ramenes a une cible commune puis reencodes en
.ogg (Vorbis q5) et .m4a (AAC 160 kb/s ; a 128 kb/s l'encodeur ajoute du bruit
sur note_sol, +0,9 LU) dans assets/audio_mix/.

Cible : sonie momentanee max (fenetre 400 ms, celle de la mesure QA) a
TARGET_LUFS (-22 LUFS, le niveau des notes au retest, la mouette etant
4,5 dB au-dessus), crete vraie <= MAX_TP dBTP. Plus haut, le coquillage (un
clic de 0,19 s, crete 19 dB au-dessus de sa sonie) ne tient plus sous
-3 dBTP sans ecraser son attaque au limiteur. Les pads durent de 0,19 s a 3,1 s :
la sonie integree d'un son plus court qu'un bloc de 400 ms n'a pas de sens
seule, et les notes qui decroissent auraient l'air 5 dB trop faibles. La
sonie integree est mesuree et enregistree aussi (levels.json).

Methode, pour chaque pad (ffmpeg loudnorm en deux passes) :
  1. passe de mesure : loudnorm print_format=json (I, TP, LRA, seuil) et
     ebur128 (sonie momentanee max), sur le son complete de silence a 4 s ;
  2. passe d'application : loudnorm linear=true avec les valeurs mesurees et
     une cible integree I = I_mesure + (TARGET_LUFS - M_max) ; un limiteur
     ne sert que si la crete depasserait MAX_TP (coquillage) ;
  3. encodage .ogg et .m4a, nouvelle mesure, petite correction si besoin.

Usage : python3 tool/normalize_pads.py          (genere + verifie)
        python3 tool/normalize_pads.py --check  (verifie seulement)
Ecrit assets/audio_mix/levels.json, lu par test/qa_regression_test.dart
(groupe BUG-007).
"""
import json, os, re, subprocess, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
PADS = {
    # sortie (relative a assets/audio_mix/) : source (relative a la racine du projet)
    'beach/beach_wave_splash': 'audio_sources/beach/beach_wave_splash.ogg',
    'beach/beach_seagull': 'audio_sources/beach/beach_seagull.ogg',
    'beach/beach_shell': 'audio_sources/beach/beach_shell.ogg',
    'beach/beach_bubbles': 'audio_sources/beach/beach_bubbles.ogg',
    'beach/beach_sand': 'audio_sources/beach/beach_sand.ogg',
    'notes/note_do': 'assets/sounds/note_do.wav',
    'notes/note_re': 'assets/sounds/note_re.wav',
    'notes/note_mi': 'assets/sounds/note_mi.wav',
    'notes/note_sol': 'assets/sounds/note_sol.wav',
    'notes/note_la': 'assets/sounds/note_la.wav',
}
TARGET_LUFS = -22.0
MAX_TP = -3.0
TOLERANCE = .3
SR = 44100
PAD = 'apad=whole_dur=4'


def ffmpeg_err(args):
    return subprocess.run(['ffmpeg', '-hide_banner', '-nostats'] + args,
                          capture_output=True, text=True).stderr


def duration(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                          '-of', 'csv=p=0', path], capture_output=True, text=True).stdout
    return float(out.strip())


def loudness(path):
    """Sonie integree, sonie momentanee max (400 ms), crete vraie."""
    err = ffmpeg_err(['-v', 'verbose', '-i', path, '-af',
                      f'{PAD},ebur128=peak=true:framelog=verbose', '-f', 'null', '-'])
    m = [float(x) for x in re.findall(r' M:\s*(-?[\d.]+)', err)]
    i = float(re.findall(r'I:\s+(-?[\d.]+) LUFS', err)[-1])
    tp = re.findall(r'Peak:\s+(-?[\d.]+|-inf)\s+dBFS', err)
    return {'momentary_max_lufs': round(max(m), 2), 'integrated_lufs': round(i, 2),
            'true_peak_dbtp': round(float(tp[-1]), 2) if tp and tp[-1] != '-inf' else -99.0}


def loudnorm_measure(path, target_i):
    err = ffmpeg_err(['-i', path, '-af',
                      f'{PAD},loudnorm=I={target_i:.2f}:TP=0:LRA=50:print_format=json',
                      '-f', 'null', '-'])
    return json.loads(err[err.rindex('{'):err.rindex('}') + 1])


def render(src, dst, gain_db, codec):
    """Passe 2 : loudnorm lineaire (gain constant), limiteur si besoin."""
    m = loudnorm_measure(src, -24)  # cible quelconque : on ne lit que les mesures
    measured_i = float(m['input_i'])
    # Gain borne pour que loudnorm reste lineaire (crete <= 0 dBTP).
    gain_db = min(gain_db, -.1 - float(m['input_tp']))
    target_i = max(-70.0, min(-5.0, measured_i + gain_db))
    # LRA d'un son de 0,19 s : 0 (indefini), que loudnorm prend pour une
    # mesure absente ; on passe 0,01 LU pour rester en mode lineaire.
    # loudnorm reste lineaire tant que la crete obtenue reste sous TP : on
    # lui laisse 0 dBTP et le limiteur ramene ensuite a MAX_TP si besoin.
    ln = (f'loudnorm=I={target_i:.2f}:TP=0:LRA=50:linear=true'
          f":measured_I={m['input_i']}:measured_TP={m['input_tp']}"
          f":measured_LRA={max(float(m['input_lra']), .01):.2f}:measured_thresh={m['input_thresh']}"
          f":offset=0:print_format=json")
    lim = f'alimiter=limit={10 ** ((MAX_TP - 1.0) / 20):.4f}:level=disabled:attack=1:release=30'
    af = f'{PAD},{ln},aresample={SR},{lim},atrim=duration={duration(src):.4f}'
    args = ['-y', '-i', src, '-af', af, '-ac', '1', '-ar', str(SR)]
    args += ['-c:a', 'libvorbis', '-q:a', '5'] if codec == 'ogg' else \
        ['-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart']
    err = ffmpeg_err(args + [dst])
    stats = json.loads(err[err.rindex('{'):err.rindex('}') + 1])
    assert stats['normalization_type'] == 'linear', (dst, stats)


def main(check_only):
    levels = {}
    for out, src_rel in PADS.items():
        src = os.path.join(ROOT, src_rel)
        source = loudness(src)
        for ext in ('ogg', 'm4a'):
            dst = os.path.join(ROOT, 'assets', 'audio_mix', f'{out}.{ext}')
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if not check_only:
                gain = TARGET_LUFS - source['momentary_max_lufs']
                render(src, dst, gain, ext)
                for _ in range(6):
                    after = loudness(dst)['momentary_max_lufs']
                    if abs(after - TARGET_LUFS) <= TOLERANCE:
                        break
                    gain += TARGET_LUFS - after
                    render(src, dst, gain, ext)
            levels[f'audio_mix/{out}.{ext}'] = {'source': {'file': src_rel, **source},
                                                'duration_s': round(duration(dst), 3),
                                                **loudness(dst)}
    with open(os.path.join(ROOT, 'assets', 'audio_mix', 'levels.json'), 'w') as f:
        json.dump({'method': 'ffmpeg loudnorm deux passes (linear), mesure ebur128',
                   'target_momentary_max_lufs': TARGET_LUFS, 'tolerance_lu': TOLERANCE,
                   'max_true_peak_dbtp': MAX_TP, 'files': levels}, f, indent=1)
    for k, v in levels.items():
        s = v['source']
        print(f"{k:32s} M {v['momentary_max_lufs']:6.1f} (source {s['momentary_max_lufs']:6.1f})"
              f"  I {v['integrated_lufs']:6.1f}  TP {v['true_peak_dbtp']:6.1f}  {v['duration_s']:.3f} s")


if __name__ == '__main__':
    main('--check' in sys.argv)
