"""Shared helpers for the launch variants (copy of the render helpers of launch_assets.py,
kept separate so importing them never re-exports the v1 files)."""
import io, os, sys
import numpy as np, cairosvg
from PIL import Image, ImageDraw
from scipy.spatial import ConvexHull
from scipy.optimize import minimize
sys.path.insert(0, os.path.dirname(__file__))
import launch_motif as M

def _svg(inner, w, h, vb):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="{vb[0]:.4f} {vb[1]:.4f} {vb[2]:.4f} {vb[3]:.4f}">{inner}</svg>')
def _png(svg): return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert('RGBA')

def enclosing_circle(inner, res=2000):
    im = _png(_svg(inner, res, res, (-130, -130, 260, 260)))
    a = np.array(im)[..., 3]; ys, xs = np.nonzero(a > 0)
    pts = np.stack([xs + .5, ys + .5], 1); hull = pts[ConvexHull(pts).vertices]
    f = lambda c: np.max(np.hypot(hull[:, 0] - c[0], hull[:, 1] - c[1]))
    c = minimize(f, pts.mean(0), method='Nelder-Mead', options={'xatol': .01, 'fatol': .01}).x
    s = 260 / res
    return (c[0] * s - 130, c[1] * s - 130, f(c) * s + s)

MOTIF = M.motif_svg()
MC = enclosing_circle(MOTIF)
def render(inner, size, radius, center=None, circ=MC):
    cx, cy = center or (size / 2, size / 2); k = radius / circ[2]
    return _png(_svg(inner, size, size, (circ[0] - cx / k, circ[1] - cy / k, size / k, size / k)))

def ch(v):
    v /= 255; return v / 12.92 if v <= .03928 else ((v + .055) / 1.055) ** 2.4
def lum(c): r, g, b = (ch(float(x)) for x in c[:3]); return .2126 * r + .7152 * g + .0722 * b
def contrast(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True); return (la + .05) / (lb + .05)
def hx(c): return '#%02X%02X%02X' % tuple(int(round(v)) for v in c[:3])
def rgb(h): return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))

def superellipse(size, n, ss=4):
    S = size * ss; y, x = np.mgrid[0:S, 0:S].astype(np.float32)
    u = np.abs((x + .5) / S * 2 - 1); v = np.abs((y + .5) / S * 2 - 1)
    return Image.fromarray(((u ** n + v ** n) <= 1).astype(np.uint8) * 255).resize((size, size), Image.LANCZOS)
def circle_mask(size, ss=4):
    m = Image.new('L', (size * ss, size * ss), 0); ImageDraw.Draw(m).ellipse((0, 0, size * ss - 1, size * ss - 1), fill=255)
    return m.resize((size, size), Image.LANCZOS)
def masked(img, mask):
    o = img.convert('RGBA').copy(); o.putalpha(mask); return o
def dashed_circle(d, cx, cy, r, col, w=3, seg=40):
    for i in range(0, seg, 2):
        a0 = 360 * i / seg; d.arc((cx - r, cy - r, cx + r, cy + r), a0, a0 + 360 / seg, fill=col, width=w)
