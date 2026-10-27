"""Lil C Monsters · launch assets (BUG-018): app icon iOS, Android adaptive icon, splash.
Working draft for AD review (Margaux Vérany), validation David. Writes ONLY into
design/assets/launch/ (+ manifest.json 'launch' entry) and design/_work/launch/.
Run: python3 design/_work/pipeline/launch_assets.py"""
import os, sys, json, math
import numpy as np, cairosvg, io
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from scipy.spatial import ConvexHull
from scipy.optimize import minimize
sys.path.insert(0, os.path.dirname(__file__))
import launch_motif as M

D = '/workspace/seamonsters/design'
OUT = f'{D}/assets/launch'
WORK = f'{D}/_work/launch'
for sub in ('ios', 'android', 'android/play_store', 'splash', 'splash/2.0x', 'splash/3.0x', 'splash/android12'):
    os.makedirs(f'{OUT}/{sub}', exist_ok=True)
os.makedirs(WORK, exist_ok=True)

LAGOON = (0x3F, 0xC1, 0xB0); LAGOON_TOP = (0x6C, 0xD8, 0xCA); LAGOON_BOT = (0x2F, 0xAE, 0x9E)
FOAM = (0xD4, 0xF4, 0xEE); PLUM = (0x3A, 0x17, 0x52); CREAM = (0xFF, 0xF6, 0xE5)
SPLASH_BG = LAGOON           # one colour for the splash
ICON_BG_HEX = '#3FC1B0'      # flat equivalent of the Android background layer
def hx(c): return '#%02X%02X%02X' % c[:3]

# ---------- motif geometry: minimal enclosing circle of the drawn silhouette ----------
def _svg(inner, w, h, vb):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="{vb[0]:.4f} {vb[1]:.4f} {vb[2]:.4f} {vb[3]:.4f}">{inner}</svg>')
def _png(svg): return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert('RGBA')

def enclosing_circle(inner, res=2000):
    im = _png(_svg(inner, res, res, (-130, -130, 260, 260)))
    a = np.array(im)[..., 3]
    ys, xs = np.nonzero(a > 0)
    pts = np.stack([xs + .5, ys + .5], 1)
    hull = pts[ConvexHull(pts).vertices]
    f = lambda c: np.max(np.hypot(hull[:, 0] - c[0], hull[:, 1] - c[1]))
    c = minimize(f, pts.mean(0), method='Nelder-Mead', options={'xatol': .01, 'fatol': .01}).x
    s = 260 / res
    a_edge = a[0].any() or a[-1].any() or a[:, 0].any() or a[:, -1].any()
    assert not a_edge, 'motif touches the render border'
    return (c[0] * s - 130, c[1] * s - 130, f(c) * s + s)   # +1px safety

MOTIF = M.motif_svg()
MC = enclosing_circle(MOTIF)

def render(inner, size, radius, center=None, circ=MC):
    """Render motif so that its enclosing circle (circ) lands at `center` with `radius` px."""
    cx, cy = center or (size / 2, size / 2)
    k = radius / circ[2]
    vb = (circ[0] - cx / k, circ[1] - cy / k, size / k, size / k)
    return _png(_svg(inner, size, size, vb))

def lagoon_bg(size):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    t = y[..., None]
    col = np.array(LAGOON_TOP, np.float32) * (1 - t) + np.array(LAGOON_BOT, np.float32) * t
    # soft foam glow behind the hero (lifts blue Pip off the lagoon)
    r = np.hypot(x - .5, y - .47)[..., None]
    g = np.clip(1 - r / .42, 0, 1) ** 2 * .30
    col = col * (1 - g) + np.array(FOAM, np.float32) * g
    return Image.fromarray(col.clip(0, 255).astype(np.uint8), 'RGB')

def monochrome(size, radius):
    """White silhouette, eye white + mouth punched out (eye pupil kept)."""
    sil = render(MOTIF, size, radius).getchannel('A')
    holes, (ix, iy, ir) = M.holes_svg()
    h = render(holes, size, radius).getchannel('A')
    pupil = render(f'<circle cx="{ix}" cy="{iy}" r="{ir}" fill="#000"/>', size, radius).getchannel('A')
    a = np.array(sil, np.float32) * (1 - np.array(h, np.float32) / 255)
    a = np.maximum(a, np.array(pupil, np.float32))
    out = Image.new('RGBA', (size, size), (255, 255, 255, 0)); out.putalpha(Image.fromarray(a.astype(np.uint8)))
    return out

# ---------------------------------- exports ----------------------------------
ART = {}
# 1. iOS 1024, RGB, no alpha. Enclosing circle radius 430 px (motif bbox inside the central 80 % square).
IOS_R = 430
IOS_C = (512, 486)   # lifted 26 px so the bbox (and ground shadow) stays inside 102..922
ios = lagoon_bg(1024).convert('RGBA')
ios.alpha_composite(render(M.motif_svg(shadow=True), 1024, IOS_R, center=IOS_C, circ=MC))
ios = ios.convert('RGB'); ios.save(f'{OUT}/ios/app_icon_1024.png', optimize=True)
# Play Store 512 (full square, Play applies its own mask)
ios.resize((512, 512), Image.LANCZOS).save(f'{OUT}/android/play_store/play_store_512.png', optimize=True)

# 2. Android adaptive (432 px = 108 dp @ xxxhdpi). Safe circle 264 px (66 dp). Motif radius 128 px.
FG_R = 128
lagoon_bg(432).save(f'{OUT}/android/ic_launcher_background.png', optimize=True)
fg = render(MOTIF, 432, FG_R); fg.save(f'{OUT}/android/ic_launcher_foreground.png', optimize=True)
mono = monochrome(432, FG_R); mono.save(f'{OUT}/android/ic_launcher_monochrome.png', optimize=True)

# 3. Splash logo 288 dp box, motif in a 192 dp circle (inside the 240 dp Android 12 mask).
SPL_R_DP = 96
for scale, path in ((1, 'splash/splash_logo.png'), (2, 'splash/2.0x/splash_logo.png'), (3, 'splash/3.0x/splash_logo.png')):
    render(MOTIF, 288 * scale, SPL_R_DP * scale).save(f'{OUT}/{path}', optimize=True)
# flutter_native_splash android_12 image without icon background: 1152 px, fit in a 768 px circle
render(MOTIF, 1152, 384).save(f'{OUT}/splash/android12/splash_android12_1152.png', optimize=True)

# ---------------------------------- checks ----------------------------------
def max_r(img, cx=None, cy=None, thr=0):
    a = np.array(img.getchannel('A')); ys, xs = np.nonzero(a > thr)
    cx = img.width / 2 if cx is None else cx; cy = img.height / 2 if cy is None else cy
    return float(np.max(np.hypot(xs + .5 - cx, ys + .5 - cy)))

def lum(c):
    def ch(v):
        v /= 255; return v / 12.92 if v <= .03928 else ((v + .055) / 1.055) ** 2.4
    r, g, b = (ch(float(x)) for x in c[:3]); return .2126 * r + .7152 * g + .0722 * b
def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True); return (la + .05) / (lb + .05)

checks = {}
def chk(name, path, size, mode):
    im = Image.open(f'{OUT}/{path}')
    ok = im.size == size and im.mode == mode
    checks[name] = {'file': path, 'size': list(im.size), 'mode': im.mode, 'ok_size_mode': ok}
    return im
im = chk('ios', 'ios/app_icon_1024.png', (1024, 1024), 'RGB')
checks['ios']['has_alpha'] = 'A' in im.getbands()
chk('play_store', 'android/play_store/play_store_512.png', (512, 512), 'RGB')
im = chk('bg', 'android/ic_launcher_background.png', (432, 432), 'RGB')
for n, p in (('fg', 'android/ic_launcher_foreground.png'), ('mono', 'android/ic_launcher_monochrome.png')):
    im = chk(n, p, (432, 432), 'RGBA'); a = np.array(im.getchannel('A'))
    checks[n].update(max_dist_px=round(max_r(im), 2), limit_px=132, inside=max_r(im) <= 132,
                     corner_alpha=int(a[0, 0]), transparent_share=round(float((a == 0).mean()), 3))
    if n == 'mono':
        rgb = np.array(im)[..., :3][a > 0]; checks[n]['all_white'] = bool((rgb == 255).all())
for n, p, s in (('splash1x', 'splash/splash_logo.png', 288), ('splash2x', 'splash/2.0x/splash_logo.png', 576),
                ('splash3x', 'splash/3.0x/splash_logo.png', 864), ('splash_a12', 'splash/android12/splash_android12_1152.png', 1152)):
    im = chk(n, p, (s, s), 'RGBA'); r = max_r(im)
    checks[n].update(max_dist_px=round(r, 2), circle240_limit_px=round(s * 120 / 288, 2), inside240=r <= s * 120 / 288,
                     dp_radius=round(r * 288 / s, 2), inside192=r <= s * 96 / 288 + 0.5)
# iOS: motif extent in the 1024 square (ignoring the soft ground shadow -> use fg-only render)
ios_only = render(MOTIF, 1024, IOS_R, center=IOS_C); a = np.array(ios_only.getchannel('A')); ys, xs = np.nonzero(a)
checks['ios'].update(motif_bbox=[int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1],
                     motif_max_dist_px=round(max_r(ios_only, *IOS_C), 1), central80_box=[102, 102, 922, 922])
checks['contrast'] = {
    'plum_on_lagoon': round(contrast(PLUM, LAGOON), 2), 'plum_on_cream': round(contrast(PLUM, CREAM), 2),
    'pip_blue_on_lagoon': round(contrast((0x1B, 0x98, 0xD0), LAGOON), 2),
    'plum_on_splash_bg': round(contrast(PLUM, SPLASH_BG), 2)}
checks['motif_enclosing_circle_viewbox'] = [round(v, 2) for v in MC]
json.dump(checks, open(f'{WORK}/checks.json', 'w'), indent=2)

# ---------------------------------- contact sheet ----------------------------------
F = f'{D}/_work/'
ft = ImageFont.truetype(F + 'LuckiestGuy.ttf', 46); fb = ImageFont.truetype(F + 'Baloo2-700.ttf', 24); fs = ImageFont.truetype(F + 'Baloo2-600.ttf', 19)

def superellipse(size, n, ss=4):
    S = size * ss; y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    u = np.abs((x + .5) / S * 2 - 1); v = np.abs((y + .5) / S * 2 - 1)
    m = ((u ** n + v ** n) <= 1).astype(np.uint8) * 255
    return Image.fromarray(m).resize((size, size), Image.LANCZOS)
def circle_mask(size, ss=4):
    m = Image.new('L', (size * ss, size * ss), 0); ImageDraw.Draw(m).ellipse((0, 0, size * ss - 1, size * ss - 1), fill=255)
    return m.resize((size, size), Image.LANCZOS)
def rrect_mask(size, rad, ss=4):
    m = Image.new('L', (size * ss, size * ss), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, size * ss - 1, size * ss - 1), rad * size * ss, fill=255)
    return m.resize((size, size), Image.LANCZOS)
def masked(img, mask):
    o = img.convert('RGBA').copy(); o.putalpha(mask); return o
def dashed_circle(d, cx, cy, r, col, w=3, seg=40):
    for i in range(seg):
        if i % 2: continue
        a0 = 360 * i / seg; d.arc((cx - r, cy - r, cx + r, cy + r), a0, a0 + 360 / seg, fill=col, width=w)
def checker(w, h, s=12):
    c = Image.new('RGBA', (w, h), (235, 235, 235, 255)); d = ImageDraw.Draw(c)
    for y in range(0, h, s):
        for x in range(0, w, s):
            if (x // s + y // s) % 2: d.rectangle((x, y, x + s - 1, y + s - 1), fill=(205, 205, 205, 255))
    return c

W, H = 2400, 3330
sheet = Image.new('RGBA', (W, H), CREAM + (255,)); d = ImageDraw.Draw(sheet)
d.text((60, 36), 'LIL C MONSTERS · ICÔNE + ÉCRAN DE DÉMARRAGE (BUG-018)', font=ft, fill=PLUM)
d.text((60, 96), 'Version de travail, validation David · héros : Pip (redessiné en vectoriel) · fond lagon ' + ICON_BG_HEX +
       ' · splash ' + hx(SPLASH_BG) + ' · 27/10/2026', font=fb, fill=(90, 63, 107))
y = 160
# --- iOS row
d.text((60, y), '1 · iOS · app_icon_1024.png (RGB, sans alpha) sous masque arrondi iOS simulé · tailles réelles en px', font=fb, fill=PLUM); y += 40
ios_img = Image.open(f'{OUT}/ios/app_icon_1024.png')
big = 600
sheet.alpha_composite(masked(ios_img.resize((big, big), Image.LANCZOS), superellipse(big, 5)), (60, y))
d.text((60, y + big + 6), '1024 (affiché à 600)', font=fs, fill=PLUM)
x = 720
for bgcol, label in (((240, 236, 230), 'fond clair'), ((28, 30, 44), 'fond sombre')):
    panel = Image.new('RGBA', (780, 290), bgcol + (255,)); px = 24
    for s in (180, 120, 60, 29):
        panel.alpha_composite(masked(ios_img.resize((s, s), Image.LANCZOS), superellipse(s, 5)), (px, (290 - s) // 2)); px += s + 40
    sheet.alpha_composite(panel, (x, y)); d.text((x, y + 292), f'{label} · 180 · 120 · 60 · 29 px', font=fs, fill=PLUM); y_ios_mid = y
    y += 330
# zoomed 29 & 60 px (nearest neighbour x6) to judge pixels
z = Image.new('RGBA', (60 * 6 + 29 * 6 + 30, 360), CREAM + (255,))
z.alpha_composite(masked(ios_img.resize((60, 60), Image.LANCZOS), superellipse(60, 5)).resize((360, 360), Image.NEAREST), (0, 0))
z.alpha_composite(masked(ios_img.resize((29, 29), Image.LANCZOS), superellipse(29, 5)).resize((174, 174), Image.NEAREST), (390, 93))
sheet.alpha_composite(z, (1540, y - 660 + 10 if False else 160 + 40))
d.text((1540, 160 + 40 + 362), 'loupe ×6 : 60 px et 29 px', font=fs, fill=PLUM)
y = 160 + 40 + big + 50
# --- Android row
d.text((60, y), '2 · ANDROID adaptive · fond + premier plan sous masques cercle / squircle / carré arrondi (vue 72 dp) · vue de contrôle 108 dp', font=fb, fill=PLUM); y += 40
bgA = Image.open(f'{OUT}/android/ic_launcher_background.png').convert('RGBA'); fgA = Image.open(f'{OUT}/android/ic_launcher_foreground.png')
comp = bgA.copy(); comp.alpha_composite(fgA); view = comp.crop((72, 72, 360, 360))   # 288 px = 72 dp viewport
x = 60; T = 340
for name, mk in (('cercle', circle_mask(T)), ('squircle', superellipse(T, 3)), ('carré arrondi', rrect_mask(T, .22))):
    sheet.alpha_composite(masked(view.resize((T, T), Image.LANCZOS), mk), (x, y)); dd = ImageDraw.Draw(sheet)
    dashed_circle(dd, x + T / 2, y + T / 2, 132 * T / 288, (255, 255, 255, 255), 2, 48)
    d.text((x, y + T + 4), name + ' · cercle 264 px en pointillé', font=fs, fill=PLUM); x += T + 40
# control view: full 432 with viewport + safe circle
cv = comp.copy(); cd = ImageDraw.Draw(cv)
cd.rectangle((72, 72, 359, 359), outline=(255, 255, 255, 255), width=2)
dashed_circle(cd, 216, 216, 132, PLUM + (255,), 3, 48)
dashed_circle(cd, 216, 216, 144, (255, 255, 255, 255), 2, 60)
fgc = checker(432, 432); fgc.alpha_composite(fgA); fd = ImageDraw.Draw(fgc); dashed_circle(fd, 216, 216, 132, (220, 0, 80, 255), 3, 48)
sheet.alpha_composite(cv.resize((360, 360), Image.LANCZOS), (x, y - 10)); d.text((x, y + 354), '432 complet : carré 72 dp, cercle 264 (prune)', font=fs, fill=PLUM)
sheet.alpha_composite(fgc.resize((360, 360), Image.LANCZOS), (x + 390, y - 10)); d.text((x + 390, y + 354), 'premier plan seul, cercle 264', font=fs, fill=PLUM)
# small real sizes
sx = 2350 - 160; sm = Image.new('RGBA', (170, 360), (28, 30, 44, 255)); py = 20
for s in (96, 48):
    sm.alpha_composite(masked(view.resize((s, s), Image.LANCZOS), circle_mask(s)), ((170 - s) // 2, py)); py += s + 30
sheet.alpha_composite(sm, (sx - 0, y - 10)); d.text((sx, y + 354), '96 / 48 px', font=fs, fill=PLUM)
y += T + 70
# --- Monochrome row
d.text((60, y), '3 · ANDROID 13 icône thématique · ic_launcher_monochrome.png (blanc sur transparent) + teintes simulées', font=fb, fill=PLUM); y += 40
mono_img = Image.open(f'{OUT}/android/ic_launcher_monochrome.png')
ck = checker(432, 432); ck.alpha_composite(mono_img); ckd = ImageDraw.Draw(ck); dashed_circle(ckd, 216, 216, 132, (220, 0, 80, 255), 3, 48)
ck2 = Image.new('RGBA', (432, 432), (40, 40, 40, 255)); ck2.alpha_composite(mono_img)
sheet.alpha_composite(ck.resize((300, 300), Image.LANCZOS), (60, y)); d.text((60, y + 302), 'sur damier, cercle 264', font=fs, fill=PLUM)
sheet.alpha_composite(ck2.resize((300, 300), Image.LANCZOS), (400, y)); d.text((400, y + 302), 'blanc sur gris', font=fs, fill=PLUM)
x = 740
for bgc, fgc_ in (((0xCF, 0xEC, 0xE7), (0x0B, 0x4F, 0x4A)), ((0x1E, 0x33, 0x31), (0xA6, 0xEB, 0xE0)), ((0xEA, 0xDD, 0xFF), (0x3A, 0x17, 0x52))):
    t = Image.new('RGBA', (432, 432), bgc + (255,)); tint = Image.new('RGBA', (432, 432), fgc_ + (255,)); tint.putalpha(mono_img.getchannel('A'))
    t.alpha_composite(tint); v = t.crop((72, 72, 360, 360))
    sheet.alpha_composite(masked(v.resize((240, 240), Image.LANCZOS), circle_mask(240)), (x, y + 30))
    sheet.alpha_composite(masked(v.resize((48, 48), Image.LANCZOS), circle_mask(48)), (x + 96, y + 290 - 10))
    x += 290
d.text((740, y + 302 + 30), 'teintes Material You simulées (clair, sombre, violet) · 240 et 48 px', font=fs, fill=PLUM)
y += 380
# --- Splash row
d.text((60, y), f'4 · SPLASH · fond {hx(SPLASH_BG)} · logo 288 dp (cadre), cercle 240 dp (masque Android 12, pointillé blanc), cercle 192 dp (prune)', font=fb, fill=PLUM); y += 40
logo3 = Image.open(f'{OUT}/splash/3.0x/splash_logo.png')
def phone(bg, a12, label, x0):
    k = 1.25                     # px per dp on the sheet
    pw, ph = int(360 * k), int(780 * k)
    frame = Image.new('RGBA', (pw + 28, ph + 28), (0, 0, 0, 0)); fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, pw + 27, ph + 27), 56, fill=(30, 30, 36, 255))
    scr = Image.new('RGBA', (pw, ph), bg + (255,))
    s = int(288 * k); lg = logo3.resize((s, s), Image.LANCZOS)
    if a12: lg = masked(lg, Image.fromarray(np.minimum(np.array(lg.getchannel('A')), np.array(_cm(s, 240 / 288)))))
    scr.alpha_composite(lg, ((pw - s) // 2, (ph - s) // 2)); sd = ImageDraw.Draw(scr)
    cx, cy = pw / 2, ph / 2
    sd.rectangle((cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2), outline=(255, 255, 255, 140), width=1)
    dashed_circle(sd, cx, cy, 120 * k, (255, 255, 255, 255), 2, 48); dashed_circle(sd, cx, cy, 96 * k, PLUM + (255,), 2, 40)
    m = Image.new('L', (pw, ph), 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, pw - 1, ph - 1), 44, fill=255); scr.putalpha(m)
    frame.alpha_composite(scr, (14, 14)); sheet.alpha_composite(frame, (x0, y)); d.text((x0, y + ph + 34), label, font=fs, fill=PLUM)
    return pw + 28
def _cm(s, frac):
    m = Image.new('L', (s * 4, s * 4), 0); r = s * 2 * frac
    ImageDraw.Draw(m).ellipse((s * 2 - r, s * 2 - r, s * 2 + r, s * 2 + r), fill=255); return m.resize((s, s), Image.LANCZOS)
x = 60
x += phone(SPLASH_BG, True, f'Android 12+ (masque cercle 240 dp) · {hx(SPLASH_BG)}', x) + 50
x += phone(SPLASH_BG, False, f'iOS / Android < 12 (logo entier) · {hx(SPLASH_BG)}', x) + 50
x += phone(CREAM, False, 'variante écartée : crème #FFF6E5', x) + 50
# legend with measures
c = checks
lines = [
    'Mesures (PIL, pixels alpha > 0) :',
    f"iOS 1024 : RGB, alpha = {c['ios']['has_alpha']}, motif bbox {c['ios']['motif_bbox']}",
    f"  (zone 80 % = 102..922), rayon max {c['ios']['motif_max_dist_px']} px",
    f"Android fg : rayon max {c['fg']['max_dist_px']} px ≤ 132 → {c['fg']['inside']}",
    f"Android mono : rayon max {c['mono']['max_dist_px']} px ≤ 132 → {c['mono']['inside']}",
    f"Splash 1x : rayon max {c['splash1x']['max_dist_px']} px (limite 120)",
    f"  = {c['splash1x']['dp_radius']} dp → dans 240 dp : {c['splash1x']['inside240']}",
    f"  dans 192 dp : {c['splash1x']['inside192']}",
    f"Contraste prune / lagon : {c['contrast']['plum_on_lagoon']}:1",
    f"Contraste prune / crème : {c['contrast']['plum_on_cream']}:1",
    f"Bleu Pip / lagon : {c['contrast']['pip_blue_on_lagoon']}:1",
    '  (faible : séparation portée par le contour prune)',
]
ly = y + 10
for ln in lines:
    d.text((x, ly), ln, font=fs, fill=PLUM); ly += 30
sheet = sheet.crop((0, 0, W, y + int(780 * 1.25) + 90))
sheet.convert('RGB').save(f'{OUT}/_contact.png', optimize=True)

# ---------------------------------- manifest ----------------------------------
mp = f'{D}/assets/manifest.json'
raw = open(mp, encoding='utf-8').read(); man = json.loads(raw)
man['launch'] = {
    'version': 'v1 (27/10/2026, BUG-018): working draft, validation David',
    'hero': 'Pip (one eye), vector redraw from assets/images/monsters/pip.webp, script design/_work/pipeline/launch_motif.py',
    'readme': 'launch/README.md', 'contact_sheet': 'launch/_contact.png',
    'colors': {'android_icon_background': ICON_BG_HEX, 'android_icon_background_gradient': [hx(LAGOON_TOP), hx(LAGOON_BOT)],
               'splash_background': hx(SPLASH_BG), 'outline': '#3A1752'},
    'ios': {'app_icon_1024': {'file': 'launch/ios/app_icon_1024.png', 'px': [1024, 1024], 'mode': 'RGB, no alpha',
                              'motif': 'inside the central 80 %, iOS applies the rounded mask'}},
    'android': {
        'adaptive_foreground': {'file': 'launch/android/ic_launcher_foreground.png', 'px': [432, 432], 'dp': [108, 108], 'mode': 'RGBA transparent',
                                'safe_zone': 'circle 264 px (66 dp) centred', 'max_radius_px': c['fg']['max_dist_px']},
        'adaptive_background': {'file': 'launch/android/ic_launcher_background.png', 'px': [432, 432], 'mode': 'RGB opaque', 'flat_color': ICON_BG_HEX},
        'adaptive_monochrome': {'file': 'launch/android/ic_launcher_monochrome.png', 'px': [432, 432], 'mode': 'RGBA white on transparent',
                                'safe_zone': 'circle 264 px (66 dp) centred', 'max_radius_px': c['mono']['max_dist_px']},
        'play_store_512': {'file': 'launch/android/play_store/play_store_512.png', 'px': [512, 512], 'mode': 'RGB'}},
    'splash': {'logo': {'name': 'splash_logo.png', 'dp': [288, 288], 'files': {
        '1x': {'file': 'launch/splash/splash_logo.png', 'px': [288, 288]},
        '2x': {'file': 'launch/splash/2.0x/splash_logo.png', 'px': [576, 576]},
        '3x': {'file': 'launch/splash/3.0x/splash_logo.png', 'px': [864, 864]}},
        'safe_zone': 'motif inside a 192 dp circle (Android 12 mask = 240 dp circle)', 'max_radius_dp': c['splash1x']['dp_radius']},
        'android12_image': {'file': 'launch/splash/android12/splash_android12_1152.png', 'px': [1152, 1152], 'safe_zone': 'circle 768 px'},
        'background': hx(SPLASH_BG)},
}
new = json.dumps(man, indent=2, ensure_ascii=False)
json.loads(new)
assert {k: v for k, v in json.loads(new).items() if k != 'launch'} == {k: v for k, v in json.loads(raw).items() if k != 'launch'}
open(mp, 'w', encoding='utf-8').write(new)
print(json.dumps(checks, indent=1))
