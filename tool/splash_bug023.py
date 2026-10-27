#!/usr/bin/env python3
"""BUG-023 : nom de l'appli en bas du splash sans toucher Pip.

Trois etapes, dans cet ordre (python3 tool/splash_bug023.py all) :

  images      Genere, depuis les copies de design/ dans assets/launch/
              (design/ n'est jamais modifie), deux logos de splash 1152 px
              (@4x, 288 dp) dans assets/launch/splash/bug023/ :
              - splash_android12_1152.png : Android 12 et plus. Pip reduit
                (x K12) et remonte : bas de Pip a BOTTOM12_DP sous le centre,
                tout le motif dans le cercle de 192 dp (rayon <= celui de
                l'original, 95,95 dp).
              - splash_logo_1152.png : Android 11 et avant, iOS. Pip a sa
                taille d'origine, remonte de SHIFT_DP.
  storyboard  Apres `dart run flutter_native_splash:create` (qui reecrit le
              storyboard) : colle le nom au bas de la zone sure iOS
              (safeAreaLayoutGuide) au lieu du bas de la vue.
  measure     Tableau des ecarts logo / nom (meme modele que
              captures/retest6/splash_planche_mesures.json de la QA).

A relancer apres chaque `dart run flutter_native_splash:create` :
    python3 tool/splash_bug023.py storyboard
(test/qa_retest6_test.dart echoue sinon).
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LAUNCH = ROOT / 'assets/launch/splash'
OUT = LAUNCH / 'bug023'
SRC12 = LAUNCH / 'android12/splash_android12_1152.png'
BRANDING = LAUNCH / 'branding/branding_android12_800x320.png'
STORYBOARD = ROOT / 'ios/Runner/Base.lproj/LaunchScreen.storyboard'

PX_PER_DP = 4          # images @4x
CANVAS = 1152          # 288 dp
BOTTOM12_DP = 38       # bas de Pip sous le centre, Android 12+
SHIFT_DP = 14          # remontee de Pip, Android <= 11 et iOS
BRANDING_DP = (200, 80)

SAFE_ID = 'Bg3-Sa-Fe1'


def alpha_rows(img):
    a = np.array(img.convert('RGBA'))[:, :, 3]
    ys, xs = np.nonzero(a > 0)
    return a, ys, xs


def premul_resize(img, size):
    return img.convert('RGBa').resize(size, Image.LANCZOS).convert('RGBA')


def make_android12(src):
    """Pip reduit et remonte, motif dans le cercle d'origine."""
    a, ys, xs = alpha_rows(src)
    c = CANVAS / 2
    rmax = np.sqrt((xs + .5 - c) ** 2 + (ys + .5 - c) ** 2).max()
    box = src.getchannel('A').getbbox()
    crop = src.crop(box)
    k = 1.0
    while k > .5:
        w, h = round(crop.width * k), round(crop.height * k)
        x = round(c - w / 2)
        y = round(c + BOTTOM12_DP * PX_PER_DP - h)
        out = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
        out.alpha_composite(premul_resize(crop, (w, h)), (x, y))
        _, oy, ox = alpha_rows(out)
        r = np.sqrt((ox + .5 - c) ** 2 + (oy + .5 - c) ** 2).max()
        if r <= rmax and oy.max() + 1 <= c + BOTTOM12_DP * PX_PER_DP:
            return out, k
        k -= .005
    raise SystemExit('pas de facteur valable')


def make_general(src):
    """Taille d'origine, remonte de SHIFT_DP (decalage entier, sans
    reechantillonnage)."""
    out = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
    out.alpha_composite(src, (0, -SHIFT_DP * PX_PER_DP))
    return out


def images():
    src = Image.open(SRC12).convert('RGBA')
    OUT.mkdir(parents=True, exist_ok=True)
    a12, k = make_android12(src)
    a12.save(OUT / 'splash_android12_1152.png', optimize=True)
    make_general(src).save(OUT / 'splash_logo_1152.png', optimize=True)
    print(f'android12 : Pip x{k:.3f}, bas a {BOTTOM12_DP} dp sous le centre')
    print(f'general   : Pip x1, remonte de {SHIFT_DP} dp')


def storyboard():
    s = STORYBOARD.read_text()
    if f'id="{SAFE_ID}"' not in s:
        s = s.replace(
            '<deployment identifier="iOS"/>',
            '<deployment identifier="iOS"/>\n'
            '        <capability name="Safe area layout guides" '
            'minToolsVersion="9.0"/>',
            1,
        )
        s = s.replace(
            '                        </constraints>\n                    </view>',
            '                        </constraints>\n'
            f'                        <viewLayoutGuide key="safeArea" id="{SAFE_ID}"/>\n'
            '                    </view>',
            1,
        )
    # Nom : bas de la zone sure (barre d'accueil), et non bas de la vue.
    s, n = re.subn(
        r'<constraint firstAttribute="bottom" secondItem="Uyq-Kz-ftE" '
        r'secondAttribute="bottom" constant="[^"]*" id="8Yb-q4-8bl"/>',
        f'<constraint firstItem="{SAFE_ID}" firstAttribute="bottom" '
        'secondItem="Uyq-Kz-ftE" secondAttribute="bottom" id="8Yb-q4-8bl"/>',
        s,
    )
    if n == 0 and f'firstItem="{SAFE_ID}" firstAttribute="bottom"' not in s:
        raise SystemExit('contrainte du nom introuvable dans le storyboard')
    STORYBOARD.write_text(s)
    print('storyboard : nom contraint au bas de la zone sure')


def measure():
    """Meme modele que la QA (retest 6) : logo centre dans l'ecran, image
    du logo a 288 dp, nom 200 x 80 dp ; Android 12/12L : nom a 60 dp du bas ;
    Android 13+ : marge ramenee a (H - 352) / 4 dp (valeurs de la QA : 2 dp
    a 360, 15 dp a 412) ; Android <= 11 : nom colle en bas ; iOS : nom au bas
    de la zone sure (0 pt sur iPhone SE et iPad, 21 pt avec barre d'accueil,
    barre de 5 pt a 8 pt du bas)."""
    c = CANVAS / 2

    def logo(path):
        _, ys, _ = alpha_rows(Image.open(path))
        return (ys.min() - c) / PX_PER_DP, (ys.max() + 1 - c) / PX_PER_DP

    _, bys, _ = alpha_rows(Image.open(BRANDING))
    let_top = bys.min() / PX_PER_DP
    let_bot = BRANDING_DP[1] - (bys.max() + 1) / PX_PER_DP
    l12 = logo(OUT / 'splash_android12_1152.png')
    lg = logo(OUT / 'splash_logo_1152.png')
    cases = [
        # (nom, W, H, logo, marge du nom, barre d'accueil)
        ('Android 12/12L telephone 640 x 360 dp', 640, 360, l12, 60, None),
        ('Android 12/12L telephone 915 x 412 dp', 915, 412, l12, 60, None),
        ('Android 12+ tablette 1280 x 800 dp', 1280, 800, l12, 60, None),
        ('Android 13+ telephone 640 x 360 dp', 640, 360, l12, 2, None),
        ('Android 13+ telephone 915 x 412 dp', 915, 412, l12, 15, None),
        ('Android 11 et avant 640 x 360 dp', 640, 360, lg, 0, None),
        ('Android 11 et avant 533 x 320 dp', 533, 320, lg, 0, None),
        ('iPhone SE 568 x 320 pt', 568, 320, lg, 0, None),
        ('iPhone barre d accueil 812 x 375 pt', 812, 375, lg, 21, 8 + 5),
        ('iPhone barre d accueil 844 x 390 pt', 844, 390, lg, 21, 8 + 5),
        ('iPhone barre d accueil 932 x 430 pt', 932, 430, lg, 21, 8 + 5),
        ('iPad 1024 x 768 pt', 1024, 768, lg, 0, None),
        ('iPad Air 1180 x 820 pt', 1180, 820, lg, 20, 8 + 5),
    ]
    rows = []
    for name, w, h, (top, bottom), m, bar in cases:
        logo_bottom = h / 2 + bottom
        letters_top = h - m - BRANDING_DP[1] + let_top
        letters_bottom_margin = m + let_bot
        row = {
            'ecran': name,
            'bas_du_logo': round(logo_bottom, 2),
            'haut_des_lettres': round(letters_top, 2),
            'ecart': round(letters_top - logo_bottom, 2),
            'haut_du_logo': round(h / 2 + top, 2),
            'marge_bas_lettres': round(letters_bottom_margin, 2),
        }
        if bar is not None:
            row['ecart_barre_accueil'] = round(letters_bottom_margin - bar, 2)
        rows.append(row)
    out = ROOT / 'tool/splash_bug023_mesures.json'
    out.write_text(json.dumps(rows, indent=1, ensure_ascii=False) + '\n')
    print('| Ecran | Bas du logo | Haut des lettres | Ecart | Marge sous les lettres |')
    print('|---|---|---|---|---|')
    for r in rows:
        extra = (f" (barre d'accueil degagee de {r['ecart_barre_accueil']})"
                 if 'ecart_barre_accueil' in r else '')
        print(f"| {r['ecran']} | {r['bas_du_logo']} | {r['haut_des_lettres']} "
              f"| {r['ecart']} | {r['marge_bas_lettres']}{extra} |")
    bad = [r for r in rows if r['ecart'] <= 0 or r['haut_du_logo'] < 0]
    if bad:
        raise SystemExit(f'chevauchement : {bad}')


if __name__ == '__main__':
    steps = sys.argv[1:] or ['all']
    if 'all' in steps:
        steps = ['images', 'measure']
    for s in steps:
        {'images': images, 'storyboard': storyboard, 'measure': measure}[s]()
