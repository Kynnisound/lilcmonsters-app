"""Ressemblance des silhouettes des monstres (BUG-005, QA du 27/10/2026).

Recouvrement (IoU) des masques alpha (alpha > 50 %), cadres en 200 x 200
(BoxFit.contain), comme les ombres du jeu. 1 = formes identiques.
Deux tables : les illustrations des monstres (mode de repli, ombres par
ColorFilter) et les ombres dessinees par Margaux (assets/images/shadows/,
mode DESIGN_ART_V1).
Ecrit lib/features/shadows/shadow_similarity.g.dart.
Usage : python3 tool/shadow_similarity.py (a relancer si les images changent)
"""
import itertools, os
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
NAMES = ['fuzzle', 'pip', 'dottie', 'zib', 'bitsy']


def mask(path):
    im = Image.open(path).convert('RGBA')
    w, h = im.size
    s = 200 / max(w, h)
    im = im.resize((max(1, round(w * s)), max(1, round(h * s))))
    canvas = Image.new('RGBA', (200, 200))
    canvas.paste(im, ((200 - im.size[0]) // 2, (200 - im.size[1]) // 2))
    return np.array(canvas)[:, :, 3] > 128


def table(paths):
    masks = {n: mask(p) for n, p in paths.items()}
    rows = []
    for a, b in itertools.combinations(NAMES, 2):
        iou = (masks[a] & masks[b]).sum() / (masks[a] | masks[b]).sum()
        rows.append(f"  (Monster.{a}, Monster.{b}): {iou:.3f},")
    return rows


img = os.path.join(ROOT, 'assets', 'images')
monsters = table({n: os.path.join(img, 'monsters', f'{n}.webp') for n in NAMES})
art = table({n: os.path.join(img, 'shadows', f'shadow_{n}.png') for n in NAMES})
out = os.path.join(ROOT, 'lib', 'features', 'shadows', 'shadow_similarity.g.dart')
with open(out, 'w') as f:
    f.write('// Genere par tool/shadow_similarity.py : ne pas modifier a la main.\n')
    f.write("import '../../core/content/monsters.dart';\n\n")
    f.write('/// IoU des silhouettes des illustrations (mode de repli), par paire.\n')
    f.write('const shadowIoU = <(Monster, Monster), double>{\n')
    f.write('\n'.join(monsters) + '\n};\n\n')
    f.write('/// IoU des ombres dessinees par Margaux (DESIGN_ART_V1), par paire.\n')
    f.write('const shadowArtIoU = <(Monster, Monster), double>{\n')
    f.write('\n'.join(art) + '\n};\n')
# Chaque ombre de Margaux face a sa pose en couleur (v2) : sa propre pose
# doit etre la plus proche.
colors = {n: mask(os.path.join(img, 'shadows', 'color', f'{n}.png')) for n in NAMES}
shadows = {n: mask(os.path.join(img, 'shadows', f'shadow_{n}.png')) for n in NAMES}
print('ombre / pose en couleur (ligne : ombre)')
for a in NAMES:
    row = {b: (shadows[a] & colors[b]).sum() / (shadows[a] | colors[b]).sum() for b in NAMES}
    best = max(row, key=row.get)
    print(f"  {a:7s} " + ' '.join(f"{b} {v:.3f}" for b, v in row.items()) + f"  -> {best}")
    assert best == a, a
print('illustrations\n' + '\n'.join(monsters))
print('ombres de Margaux\n' + '\n'.join(art))
