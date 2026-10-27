"""Importe les illustrations du site lilcmonsters.com dans l'appli.

Usage : python3 tool/import_site_images.py [chemin/vers/site]
Source par defaut : /workspace/lilcmonsters/site/assets/img (variantes WebP
les plus grandes publiees par le site). Sortie : assets/images/<sous-dossier>/.
Recadrage paysage 16:10 pour les decors, carre pour le puzzle, cote long
plafonne a 1600 px, WebP qualite 80. Usage valide par David le 27/10/2026.
"""
import os
import sys

from PIL import Image

SITE = sys.argv[1] if len(sys.argv) > 1 else '/workspace/lilcmonsters/site'
SRC = os.path.join(SITE, 'assets', 'img')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'images')
MAX = 1600
Q = 80

# (source, destination, recadrage, ancrage vertical 0..1)
# recadrage : None (tel quel), 'land' (16:10), 'square'
JOBS = [
    # Monstres (detoures, transparence conservee).
    *[(f'm-{m}-360.webp', f'monsters/{m}.webp', None, .5)
      for m in ('fuzzle', 'pip', 'dottie', 'zib', 'bitsy')],
    # Couvertures des 10 livres (catalogue data/books.json).
    *[(f'story-{i:02d}-720.webp', f'books/story-{i:02d}.webp', None, .5)
      for i in range(1, 11)],
    # Pages a colorier.
    *[(f'line-{i:02d}-720.webp', f'coloring/line-{i:02d}.webp', None, .5)
      for i in range(1, 5)],
    ('printable-960.webp', 'coloring/line-05.webp', None, .5),
    # Decors des lieux.
    ('path-5-1600.webp', 'scenes/map_sea.webp', 'land', .62),
    ('video-06-960.webp', 'scenes/beach.webp', None, .5),
    ('path-4-1600.webp', 'scenes/forest.webp', 'land', .62),
    ('story-05-720.webp', 'scenes/cave.webp', None, .5),
    ('night-1200.webp', 'scenes/library.webp', 'land', .55),
    ('path-2-1600.webp', 'scenes/lighthouse.webp', 'land', .6),
    ('path-3-1600.webp', 'scenes/shadows.webp', 'land', .7),
    ('video-02-960.webp', 'scenes/parents.webp', None, .5),
    # Puzzle : scenes ou les monstres sont bien visibles.
    ('path-1-1080.webp', 'puzzle/puzzle-01.webp', 'square', .5),
    ('story-04-720.webp', 'puzzle/puzzle-02.webp', 'square', .5),
    ('story-06-720.webp', 'puzzle/puzzle-03.webp', 'square', .5),
    ('path-5-1080.webp', 'puzzle/puzzle-04.webp', 'square', .5),
    ('story-07-720.webp', 'puzzle/puzzle-05.webp', 'square', .5),
    # Vignettes du phare (videos publiees sur la chaine).
    ('video-ep1-960.webp', 'videos/ep1.webp', None, .5),
    ('music-make-your-chance-fr-960.webp', 'videos/make-your-chance-fr.webp', None, .5),
    ('music-no-problem-fr-960.webp', 'videos/no-problem-fr.webp', None, .5),
]


def crop(im, mode, anchor):
    w, h = im.size
    if mode == 'land':
        ch = min(h, round(w * 10 / 16))
        top = round((h - ch) * anchor)
        return im.crop((0, top, w, top + ch))
    if mode == 'square':
        s = min(w, h)
        left, top = (w - s) // 2, round((h - s) * anchor)
        return im.crop((left, top, left + s, top + s))
    return im


def main():
    for src, dst, mode, anchor in JOBS:
        path = os.path.join(SRC, src)
        im = crop(Image.open(path), mode, anchor)
        if max(im.size) > MAX:
            im.thumbnail((MAX, MAX), Image.LANCZOS)
        out = os.path.join(OUT, dst)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        if mode is None and im.size == Image.open(path).size:
            # Deja optimise par le site : copie octet pour octet.
            with open(path, 'rb') as f, open(out, 'wb') as g:
                g.write(f.read())
        else:
            im.save(out, 'WEBP', quality=Q, method=6)
        print(f'{src} -> assets/images/{dst} {im.size[0]}x{im.size[1]} '
              f'{os.path.getsize(out) // 1024} Ko')


if __name__ == '__main__':
    main()
