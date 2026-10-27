"""Genere des sons placeholder libres de droits (synthese maison, domaine public / CC0).
Usage: python3 tool/gen_sounds.py  -> ecrit assets/sounds/*.wav"""
import math, random, struct, wave, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')

def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + '.wav'), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(s / peak * 0.8 * 32767)) for s in samples))

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
write('boing', boing()); write('pop', pop()); write('wave', wave_sound()); write('drum', drum())
write('chime', chord([C6, E5 * 2, G5 * 2])); write('success', seq([C5, E5, G5, C6]))
write('tap', pop(0.08))
print('ok')
