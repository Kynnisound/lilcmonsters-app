"""Lil C Monsters · launch variants (BUG-018 follow-up, validated reserves by David).
A) deep lagoon background  -> design/assets/launch/variants/deep/
B) app name branding        -> design/assets/launch/splash/branding/
C) comparison sheet         -> design/assets/launch/_contact_variants.png
Never rewrites the v1 files (launch_assets.py is not imported). Writes only in design/.
Run: python3 design/_work/pipeline/launch_variants.py"""
import os, sys, json, shutil
sys.path.insert(0, os.path.dirname(__file__))
from launch_common import *
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import launch_motif as M

D = '/workspace/seamonsters/design'; L = f'{D}/assets/launch'; V = f'{L}/variants/deep'; B = f'{L}/splash/branding'
WORK = f'{D}/_work/launch/variants'
for p in (f'{V}/ios', f'{V}/android/play_store', f'{B}/2.0x', f'{B}/3.0x', WORK): os.makedirs(p, exist_ok=True)

PIP_BLUE = rgb('#1B98D0'); PLUM = rgb('#3A1752'); CREAM_TXT = rgb('#F5F1EA'); SUN = rgb('#FFD60A')
LAGOON = rgb('#3FC1B0'); CREAM = rgb('#FFF6E5')
DEEP_TOP, DEEP_BOT, DEEP_POOL = '#0B6E6A', '#06524F', '#04423F'
DEEP_FLAT = '#0B6E6A'          # flat equivalent quoted for the Android background colour
SPLASH_DEEP = '#075653'        # single splash colour: blue Pip >= 2.5:1 on it
IOS_R, IOS_C = 430, (512, 486)  # same framing as v1
FG_R = 128

def deep_bg(size, center=(.5, .5)):
    """Deep lagoon: vertical gradient + a darker pool behind Pip (inverse of the v1 foam glow),
    so the blue body stands out; corners stay at #0B6E6A."""
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    col = np.array(rgb(DEEP_TOP), np.float32) * (1 - y[..., None]) + np.array(rgb(DEEP_BOT), np.float32) * y[..., None]
    r = np.hypot(x - center[0], y - center[1])[..., None]
    g = np.clip(1 - r / .62, 0, 1) ** .8 * .95
    col = col * (1 - g) + np.array(rgb(DEEP_POOL), np.float32) * g
    return Image.fromarray(col.clip(0, 255).astype(np.uint8), 'RGB')

# ---------------- A) deep variant ----------------
ios_bg = deep_bg(1024, (IOS_C[0] / 1024, IOS_C[1] / 1024))
ios = ios_bg.convert('RGBA'); ios.alpha_composite(render(M.motif_svg(shadow=False), 1024, IOS_R, center=IOS_C))
ios = ios.convert('RGB'); ios.save(f'{V}/ios/app_icon_1024.png', optimize=True)
ios.resize((512, 512), Image.LANCZOS).save(f'{V}/android/play_store/play_store_512.png', optimize=True)
deep_bg(432).save(f'{V}/android/ic_launcher_background.png', optimize=True)

# foreground / monochrome / splash logos: compare with v1 and only copy if they would differ
fg_new = render(MOTIF, 432, FG_R)
fg_v1 = Image.open(f'{L}/android/ic_launcher_foreground.png')
fg_identical = np.array_equal(np.array(fg_new), np.array(fg_v1))
if not fg_identical:
    os.makedirs(f'{V}/android', exist_ok=True); fg_new.save(f'{V}/android/ic_launcher_foreground.png')

# contrast measurements: blue Pip vs the background ring just outside the silhouette
def ring_stats(bg_rgb, motif_alpha, inner=6, outer=40):
    a = motif_alpha
    near = np.array(a.filter(ImageFilter.MaxFilter(2 * outer + 1))) > 0
    core = np.array(a.filter(ImageFilter.MaxFilter(2 * inner + 1))) > 0
    ring = near & ~core
    px = np.array(bg_rgb)[ring].astype(float)
    ls = np.array([lum(p) for p in px[:: max(1, len(px) // 4000)]])
    lb = lum(PIP_BLUE)
    cr = (np.maximum(lb, ls) + .05) / (np.minimum(lb, ls) + .05)
    return {'ring_px': int(ring.sum()), 'mean_bg': hx(px.mean(0)), 'contrast_blue_min': round(float(cr.min()), 2),
            'contrast_blue_median': round(float(np.median(cr)), 2), 'contrast_blue_vs_mean': round(contrast(PIP_BLUE, px.mean(0)), 2),
            'contrast_plum_vs_mean': round(contrast(PLUM, px.mean(0)), 2)}
alpha_ios = render(MOTIF, 1024, IOS_R, center=IOS_C).getchannel('A')
v1_ios = Image.open(f'{L}/ios/app_icon_1024.png')
v1_bg_only = Image.open(f'{L}/android/ic_launcher_background.png').resize((1024, 1024), Image.LANCZOS)  # same gradient as v1 icon bg (approx.)
stats = {
    'deep_ios_ring': ring_stats(ios_bg, alpha_ios),
    'deep_android_ring': ring_stats(deep_bg(432), fg_new.getchannel('A'), 3, 16),
    'v1_android_ring': ring_stats(Image.open(f'{L}/android/ic_launcher_background.png'), fg_v1.getchannel('A'), 3, 16),
    'flat': {k: round(contrast(PIP_BLUE, rgb(v)), 2) for k, v in
             {'blue_on_#0B6E6A': DEEP_FLAT, 'blue_on_splash_' + SPLASH_DEEP: SPLASH_DEEP, 'blue_on_#3FC1B0': '#3FC1B0',
              'blue_on_pool_' + DEEP_POOL: DEEP_POOL}.items()},
    'splash_deep': {'plum_outline': round(contrast(PLUM, rgb(SPLASH_DEEP)), 2), 'blue': round(contrast(PIP_BLUE, rgb(SPLASH_DEEP)), 2),
                    'sun_horns': round(contrast(SUN, rgb(SPLASH_DEEP)), 2)},
    'fg_identical_to_v1': bool(fg_identical),
}

# ---------------- B) branding wordmark ----------------
FONT = f'{D}/_work/LuckiestGuy.ttf'
def wordmark(W=800, H=320, ss=4):
    """Stacked kid logo: 'LIL C' over 'MONSTERS', cream letters, sun 'C', plum contour + plum
    drop (sticker depth), small per-letter bounce. Drawn at ss x then reduced."""
    S = ss; img = Image.new('RGBA', (W * S, H * S), (0, 0, 0, 0))
    lines = [('LIL C', 128), ('MONSTERS', 148)]   # font size in 800-px units
    stroke = 9; drop = 8
    # measure
    sizes = []
    for txt, fs in lines:
        f = ImageFont.truetype(FONT, fs * S)
        widths = [f.getbbox(ch)[2] - f.getbbox(ch)[0] if ch != ' ' else fs * S * .32 for ch in txt]
        adv = [f.getlength(ch) * (1.6 if ch == ' ' else 1) for ch in txt]
        asc = f.getbbox('M')[1]; cap = f.getbbox('M')[3] - asc
        sizes.append((f, adv, sum(adv) - .04 * fs * S * (len(txt) - 1), asc, cap))
    gap = 16 * S
    tot_h = sum(s[4] for s in sizes) + gap
    y0 = (H * S - tot_h - drop * S) / 2
    layers = []
    for li, ((txt, fs), (f, adv, tw, asc, cap)) in enumerate(zip(lines, sizes)):
        x = (W * S - tw) / 2
        for i, chr_ in enumerate(txt):
            if chr_ != ' ':
                dy = (-1 if i % 2 else 1) * 3 * S   # gentle bounce
                rot = (-1 if i % 2 else 1) * 2.5
                fill = SUN if (li == 0 and chr_ == 'C') else CREAM_TXT
                layers.append((chr_, f, x, y0 - asc + dy, rot, fill))
            x += adv[i] - .04 * fs * S
        y0 += cap + gap
    # per-letter tiles so each glyph can rotate around its own centre
    def glyph(chr_, f, fill, outline, sw):
        bb = f.getbbox(chr_, stroke_width=sw); pad = 6 * S
        t = Image.new('RGBA', (bb[2] - bb[0] + 2 * pad, bb[3] - bb[1] + 2 * pad), (0, 0, 0, 0))
        ImageDraw.Draw(t).text((pad - bb[0], pad - bb[1]), chr_, font=f, fill=fill, stroke_width=sw, stroke_fill=outline)
        # close the tiny counters (O, R, C mouth...) left by the thick contour, per glyph: no pinholes
        from scipy.ndimage import binary_fill_holes
        arr = np.array(t); a = arr[..., 3] > 8
        arr[binary_fill_holes(a) & ~a] = outline
        return Image.fromarray(arr, 'RGBA'), bb, pad
    for pass_ in ('drop', 'face'):
        for chr_, f, x, y, rot, fill in layers:
            col = PLUM if pass_ == 'drop' else fill
            t, bb, pad = glyph(chr_, f, col + (255,), PLUM + (255,), stroke * S)
            t = t.rotate(rot, resample=Image.BICUBIC, expand=False)
            ox = int(x + bb[0] - pad); oy = int(y + bb[1] - pad) + (drop * S if pass_ == 'drop' else 0)
            img.alpha_composite(t, (ox, oy))
    return img
big = wordmark()
for w, path in ((800, f'{B}/branding_android12_800x320.png'), (200, f'{B}/branding.png'),
                (400, f'{B}/2.0x/branding.png'), (600, f'{B}/3.0x/branding.png')):
    big.resize((w, w * 320 // 800), Image.LANCZOS).save(path, optimize=True)
bm = Image.open(f'{B}/branding_android12_800x320.png'); a = np.array(bm.getchannel('A')); ys, xs = np.nonzero(a)
stats['branding'] = {'bbox_800': [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1],
                     'corner_alpha': int(a[0, 0]),
                     'cream_on_lagoon': round(contrast(CREAM_TXT, LAGOON), 2), 'plum_on_lagoon': round(contrast(PLUM, LAGOON), 2),
                     'cream_on_deep': round(contrast(CREAM_TXT, rgb(SPLASH_DEEP)), 2), 'plum_on_deep': round(contrast(PLUM, rgb(SPLASH_DEEP)), 2),
                     'cream_vs_plum': round(contrast(CREAM_TXT, PLUM), 2), 'sun_vs_plum': round(contrast(SUN, PLUM), 2)}

# ---------------- checks ----------------
def chk(path, size, mode):
    im = Image.open(path); return {'file': path.replace(L + '/', ''), 'size': list(im.size), 'mode': im.mode,
                                   'ok': im.size == size and im.mode == mode}
stats['files'] = [chk(f'{V}/ios/app_icon_1024.png', (1024, 1024), 'RGB'), chk(f'{V}/android/ic_launcher_background.png', (432, 432), 'RGB'),
                  chk(f'{V}/android/play_store/play_store_512.png', (512, 512), 'RGB'),
                  chk(f'{B}/branding.png', (200, 80), 'RGBA'), chk(f'{B}/2.0x/branding.png', (400, 160), 'RGBA'),
                  chk(f'{B}/3.0x/branding.png', (600, 240), 'RGBA'), chk(f'{B}/branding_android12_800x320.png', (800, 320), 'RGBA')]
json.dump(stats, open(f'{WORK}/checks_variants.json', 'w'), indent=2)

# ---------------- C) comparison sheet ----------------
F = f'{D}/_work/'
ft = ImageFont.truetype(F + 'LuckiestGuy.ttf', 46); fb = ImageFont.truetype(F + 'Baloo2-700.ttf', 24); fs = ImageFont.truetype(F + 'Baloo2-600.ttf', 19)
W = 2400; sheet = Image.new('RGBA', (W, 3000), CREAM + (255,)); d = ImageDraw.Draw(sheet)
d.text((60, 36), 'LIL C MONSTERS · VARIANTES ICÔNE + SPLASH (BUG-018)', font=ft, fill=PLUM)
d.text((60, 96), f'Version de travail, validation David · actuelle lagon #3FC1B0 vs profonde {DEEP_FLAT} (splash {SPLASH_DEEP}) · nom en bas du splash · 27/10/2026', font=fb, fill=(90, 63, 107))
y = 160
icons = [('ACTUELLE · lagon', Image.open(f'{L}/ios/app_icon_1024.png')), ('PROFONDE · lagon profond', Image.open(f'{V}/ios/app_icon_1024.png'))]
for label, im in icons:
    d.text((60, y), label, font=fb, fill=PLUM)
    sheet.alpha_composite(masked(im.resize((420, 420), Image.LANCZOS), superellipse(420, 5)), (60, y + 40))
    x = 520
    for bgcol, lab in (((240, 236, 230), 'écran clair'), ((28, 30, 44), 'écran sombre')):
        p = Image.new('RGBA', (430, 200), bgcol + (255,)); px = 30
        for s in (120, 60, 29):
            p.alpha_composite(masked(im.resize((s, s), Image.LANCZOS), superellipse(s, 5)), (px, (200 - s) // 2)); px += s + 50
        sheet.alpha_composite(p, (x, y + 40)); d.text((x, y + 244), lab + ' · 120 / 60 / 29 px', font=fs, fill=PLUM); x += 470
    # x6 loupe of the 29 px
    z = masked(im.resize((29, 29), Image.LANCZOS), superellipse(29, 5)).resize((174, 174), Image.NEAREST)
    sheet.alpha_composite(z, (x + 10, y + 52)); d.text((x + 10, y + 244), 'loupe ×6 · 29 px', font=fs, fill=PLUM)
    # android circle mask on a wallpaper
    bgA = (Image.open(f'{L}/android/ic_launcher_background.png') if 'ACT' in label else Image.open(f'{V}/android/ic_launcher_background.png')).convert('RGBA')
    bgA.alpha_composite(fg_v1); v = bgA.crop((72, 72, 360, 360))
    sheet.alpha_composite(masked(v.resize((150, 150), Image.LANCZOS), circle_mask(150)), (x + 220, y + 52))
    sheet.alpha_composite(masked(v.resize((48, 48), Image.LANCZOS), circle_mask(48)), (x + 270, y + 214))
    d.text((x + 220, y + 270), 'Android cercle 150 / 48', font=fs, fill=PLUM)
    y += 500
y += 10
s = stats
d.text((60, y - 30), f"Contraste bleu Pip / fond autour de la silhouette (médiane) : actuelle {s['v1_android_ring']['contrast_blue_median']}:1 · profonde {s['deep_android_ring']['contrast_blue_median']}:1 (min {s['deep_android_ring']['contrast_blue_min']}:1)", font=fb, fill=PLUM)
y += 30
d.text((60, y), 'SPLASH · Android 12+ (logo dans le cercle 240 dp) + nom en bas (branding 200×80 dp)', font=fb, fill=PLUM); y += 40
logo = Image.open(f'{L}/splash/splash_android12_1152.png'.replace('splash/', 'splash/android12/'))
brand = Image.open(f'{B}/branding_android12_800x320.png')
def phone(bg, with_brand, label, x0, k=1.25):
    pw, ph = int(360 * k), int(780 * k)
    frame = Image.new('RGBA', (pw + 28, ph + 28), (0, 0, 0, 0)); ImageDraw.Draw(frame).rounded_rectangle((0, 0, pw + 27, ph + 27), 56, fill=(30, 30, 36, 255))
    scr = Image.new('RGBA', (pw, ph), bg + (255,))
    sz = int(288 * k); lg = logo.resize((sz, sz), Image.LANCZOS)
    scr.alpha_composite(lg, ((pw - sz) // 2, (ph - sz) // 2))
    if with_brand:
        bw, bh = int(200 * k), int(80 * k); b = brand.resize((bw, bh), Image.LANCZOS)
        scr.alpha_composite(b, ((pw - bw) // 2, ph - bh - int(48 * k)))
    sd = ImageDraw.Draw(scr); sd.rounded_rectangle((pw / 2 - 55, ph - 18, pw / 2 + 55, ph - 12), 3, fill=(255, 255, 255, 150))  # nav pill
    m = Image.new('L', (pw, ph), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, pw - 1, ph - 1), 44, fill=255); scr.putalpha(m)
    frame.alpha_composite(scr, (14, 14)); sheet.alpha_composite(frame, (x0, y)); d.text((x0, y + ph + 34), label, font=fs, fill=PLUM)
    return pw + 28
x = 60
x += phone(LAGOON, False, 'actuel · #3FC1B0', x) + 40
x += phone(LAGOON, True, 'actuel + nom · #3FC1B0', x) + 40
x += phone(rgb(SPLASH_DEEP), True, f'profond + nom · {SPLASH_DEEP}', x) + 40
# branding at real size and x2 on both backgrounds
by = y
for bgc, lab in ((LAGOON, 'lagon'), (rgb(SPLASH_DEEP), 'profond')):
    p = Image.new('RGBA', (440, 300), bgc + (255,))
    p.alpha_composite(Image.open(f'{B}/2.0x/branding.png'), (20, 10))
    p.alpha_composite(Image.open(f'{B}/branding.png'), (20, 200))
    sheet.alpha_composite(p, (x, by)); d.text((x, by + 302), f'nom sur {lab} · 400×160 (@2x) et 200×80 (@1x, taille réelle 1 dp = 1 px)', font=fs, fill=PLUM)
    by += 350
bs = stats['branding']
for ln in ['Contrastes du nom :', f"crème/lagon {bs['cream_on_lagoon']}:1 · prune/lagon {bs['plum_on_lagoon']}:1",
           f"crème/profond {bs['cream_on_deep']}:1 · prune/profond {bs['plum_on_deep']}:1",
           f"crème/prune {bs['cream_vs_plum']}:1 · soleil/prune {bs['sun_vs_plum']}:1",
           f"Splash profond : bleu {stats['splash_deep']['blue']}:1, cornes {stats['splash_deep']['sun_horns']}:1"]:
    d.text((x, by), ln, font=fs, fill=PLUM); by += 28
sheet = sheet.crop((0, 0, W, y + int(780 * 1.25) + 80))
sheet.convert('RGB').save(f'{L}/_contact_variants.png', optimize=True)
print(json.dumps(stats, indent=1, ensure_ascii=False))
