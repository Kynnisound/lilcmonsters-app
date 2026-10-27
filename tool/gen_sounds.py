"""Genere les 5 notes pentatoniques des monstres (synthese maison, domaine public / CC0).
Usage: python3 tool/gen_sounds.py  -> ecrit assets/sounds/note_*.wav"""
import math, random, struct, wave, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')

# Niveau commun des pads de la plage (BUG-007) : RMS max sur 100 ms a
# -18 dBFS, comme les bruitages de Shada ramenes par tool/normalize_pads.py.
TARGET_RMS_DBFS = -18.0
MAX_PEAK_DBFS = -3.0

def rms_max_100ms(samples):
    win, hop = int(SR * 0.1), int(SR * 0.01)
    best = 0.0
    for i in range(0, max(1, len(samples) - win + 1), hop):
        chunk = samples[i:i + win]
        best = max(best, math.sqrt(sum(s * s for s in chunk) / win))
    return best

def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    gain = 10 ** (TARGET_RMS_DBFS / 20) / max(1e-9, rms_max_100ms(samples))
    peak = max(abs(s) for s in samples) * gain
    assert 20 * math.log10(peak) <= MAX_PEAK_DBFS, name
    with wave.open(os.path.join(OUT, name + '.wav'), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(s * gain * 32767)) for s in samples))

def env(i, n, a=0.005, decay=6.0):
    t = i / SR
    att = min(1.0, t / a)
    return att * math.exp(-decay * t)

def bell(freq, dur=0.9, decay=5.0):
    n = int(SR * dur)
    return [env(i, n, decay=decay) * (math.sin(2*math.pi*freq*i/SR) + 0.35*math.sin(2*math.pi*freq*2.76*i/SR) + 0.15*math.sin(2*math.pi*freq*5.4*i/SR)) for i in range(n)]

def boing(dur=0.6):
    n = int(SR * dur); ph = 0.0; out = []
    for i in range(n):
        t = i / SR
        f = 180 + 260 * math.exp(-6*t) * (1 + 0.3*math.sin(2*math.pi*14*t))
        ph += 2*math.pi*f/SR
        out.append(env(i, n, decay=4.5) * math.sin(ph))
    return out

def pop(dur=0.18):
    n = int(SR * dur); ph = 0.0; out = []
    for i in range(n):
        t = i / SR; f = 900 * math.exp(-18*t) + 200
        ph += 2*math.pi*f/SR
        out.append(env(i, n, a=0.001, decay=25) * math.sin(ph))
    return out

def wave_sound(dur=1.6):
    n = int(SR * dur); random.seed(3); out = []; lp = 0.0
    for i in range(n):
        t = i / SR
        lp += 0.04 * (random.uniform(-1, 1) - lp)
        swell = math.sin(math.pi * t / dur) ** 2
        out.append(lp * swell)
    return out

def drum(dur=0.4):
    n = int(SR * dur); ph = 0.0; out = []; random.seed(5)
    for i in range(n):
        t = i / SR; f = 60 + 90 * math.exp(-30*t)
        ph += 2*math.pi*f/SR
        out.append(env(i, n, a=0.001, decay=9) * (math.sin(ph) + 0.15*random.uniform(-1, 1)*math.exp(-60*t)))
    return out

def chord(freqs, dur=1.2):
    parts = [bell(f, dur, 3.5) for f in freqs]
    return [sum(p[i] for p in parts) for i in range(len(parts[0]))]

def seq(freqs, step=0.12):
    total = int(SR * (step * len(freqs) + 0.6)); out = [0.0] * total
    for k, f in enumerate(freqs):
        b = bell(f, 0.6, 7)
        off = int(SR * step * k)
        for i, s in enumerate(b):
            if off + i < total: out[off + i] += s
    return out

C5, D5, E5, G5, A5, C6 = 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5
write('note_do', bell(C5)); write('note_re', bell(D5)); write('note_mi', bell(E5))
write('note_sol', bell(G5)); write('note_la', bell(A5))
# Les autres bruitages (boing, pop, wave, drum, chime, success, tap) sont
# remplaces par les sons de Shada (assets/audio/) ; seules les 5 notes
# pentatoniques des monstres restent generees ici.
print('ok')
