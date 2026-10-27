"""Pip, vector redraw for the app icon / splash (Lil C Monsters, working draft).
Faithful to assets/images/monsters/pip.webp: blue fluffy ball, ONE big eye, yellow horns
with orange stripes, head tuft, smile with 2 teeth, pink/coral cheeks, stubby arms and feet.
Simplified for small sizes: no fur strands, thick plum outer contour (sticker look).
viewBox -100..100, motif centred near 0."""
import math
PLUM='#3A1752'; NIGHT='#1B1747'; PIP='#1B98D0'; PIP_LT='#5CC3F0'; PIP_DK='#1278AE'
SUN='#FFD60A'; CORAL='#FF7A5C'; ORANGE='#FC9313'; CREAM='#FFFDF8'

def blob(cx, cy, rx, ry, n=16, amp=4.5, rot=0.0):
    """Ellipse with soft scalloped (fluffy) edge, quadratic bumps."""
    pts=[]
    for i in range(n):
        a=rot+2*math.pi*i/n
        pts.append((cx+rx*math.cos(a), cy+ry*math.sin(a)))
    d=f'M {pts[0][0]:.2f},{pts[0][1]:.2f} '
    for i in range(n):
        a=rot+2*math.pi*(i+0.5)/n
        k=1+amp/min(rx,ry)*1.9
        c=(cx+rx*k*math.cos(a), cy+ry*k*math.sin(a))
        p=pts[(i+1)%n]
        d+=f'Q {c[0]:.2f},{c[1]:.2f} {p[0]:.2f},{p[1]:.2f} '
    return d+'Z'

def horn(sx):
    # base sits inside the head, tip curls up and outward
    def X(x): return sx*x
    return (f'M {X(-20)},-46 C {X(-38)},-54 {X(-50)},-68 {X(-55)},-88 '
            f'Q {X(-57)},-93 {X(-61)},-90 '
            f'C {X(-75)},-76 {X(-79)},-56 {X(-68)},-42 C {X(-62)},-32 {X(-50)},-26 {X(-38)},-24 Z')

BODY=blob(0,6,64,66,n=18,amp=4.2,rot=-math.pi/2)
TUFT=('M -18,-50 C -26,-66 -14,-76 -7,-66 C -8,-84 8,-84 7,-66 C 14,-76 26,-66 18,-50 Z')
ARM_L='M -58,22 C -76,18 -80,40 -66,48 C -60,52 -54,46 -52,40 Z'
ARM_R='M 58,22 C 76,18 80,40 66,48 C 60,52 54,46 52,40 Z'
FOOT_L='M -42,66 C -44,80 -6,82 -6,70 C -6,60 -40,56 -42,66 Z'
FOOT_R='M 42,66 C 44,80 6,82 6,70 C 6,60 40,56 42,66 Z'
SIL=[horn(1),horn(-1),TUFT,ARM_L,ARM_R,FOOT_L,FOOT_R,BODY]

EYE=(0,-12,29)          # cx, cy, r of the eye white
IRIS=(2,-10,16.5)
MOUTH='M -27,20 Q 0,40 27,20'

def motif_svg(outer=12, inner=5, shadow=False, flat=False):
    """Return the inner <g> markup (no <svg>)."""
    s=[]
    s.append(f'''<defs>
 <radialGradient id="fur" cx="-22" cy="-30" r="100" fx="-22" fy="-30" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="{PIP_LT}"/><stop offset="0.55" stop-color="{PIP}"/><stop offset="1" stop-color="{PIP_DK}"/></radialGradient>
 <linearGradient id="hornG" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="{SUN}"/><stop offset="1" stop-color="#FFE45C"/></linearGradient>
 <clipPath id="hl"><path d="{horn(1)}"/></clipPath><clipPath id="hr"><path d="{horn(-1)}"/></clipPath>
</defs>''')
    if shadow:
        s.append(f'<ellipse cx="0" cy="86" rx="58" ry="8" fill="#0B6E6A" opacity="0.28"/>')
    # thick outer contour: every silhouette shape stroked wide, behind
    for p in SIL:
        s.append(f'<path d="{p}" fill="{PLUM}" stroke="{PLUM}" stroke-width="{outer}" stroke-linejoin="round"/>')
    fur='url(#fur)' if not flat else PIP
    for cid,sx in (('hl',1),('hr',-1)):
        s.append(f'<path d="{horn(sx)}" fill="url(#hornG)" stroke="{PLUM}" stroke-width="{inner}" stroke-linejoin="round"/>')
        s.append(f'<g clip-path="url(#{cid})">')
        for (x,y) in [(-46,-48),(-58,-70)]:
            x*=sx
            s.append(f'<line x1="{x-16}" y1="{y}" x2="{x+16}" y2="{y}" stroke="{ORANGE}" stroke-width="7.5" transform="rotate({-35*sx} {x} {y})"/>')
        s.append('</g>')
        s.append(f'<path d="{horn(sx)}" fill="none" stroke="{PLUM}" stroke-width="{inner}" stroke-linejoin="round"/>')
    for p in (ARM_L,ARM_R,FOOT_L,FOOT_R,TUFT):
        s.append(f'<path d="{p}" fill="{PIP}" stroke="{PLUM}" stroke-width="{inner}" stroke-linejoin="round"/>')
    s.append(f'<path d="{BODY}" fill="{fur}" stroke="{PLUM}" stroke-width="{inner}" stroke-linejoin="round"/>')
    # belly light (very soft) to lift the face from the lagoon
    # cheeks
    for x in (-40,40):
        s.append(f'<ellipse cx="{x}" cy="14" rx="10.5" ry="7" fill="{CORAL}" opacity="0.95"/>')
    ex,ey,er=EYE; ix,iy,ir=IRIS
    s.append(f'<circle cx="{ex}" cy="{ey}" r="{er}" fill="{CREAM}" stroke="{PLUM}" stroke-width="{inner}"/>')
    s.append(f'<circle cx="{ix}" cy="{iy}" r="{ir}" fill="{NIGHT}"/>')
    s.append(f'<circle cx="{ix+6.5}" cy="{iy-7}" r="5.5" fill="#FFFFFF"/>')
    # teeth then mouth
    for x in (-10,10):
        s.append(f'<path d="M {x-6},27 L {x-5},36 Q {x},39 {x+5},36 L {x+6},27 Z" fill="{CREAM}" stroke="{PLUM}" stroke-width="2.6" stroke-linejoin="round"/>')
    s.append(f'<path d="{MOUTH}" fill="none" stroke="{PLUM}" stroke-width="{inner+0.8}" stroke-linecap="round"/>')
    return '\n'.join(s)

def holes_svg(inner=5):
    """Shapes punched out of the monochrome silhouette (eye white ring + mouth)."""
    ex,ey,er=EYE; ix,iy,ir=IRIS
    r_in=er-inner/2
    parts=''.join(f'<path d="{p}"/>' for p in (horn(1),horn(-1),ARM_L,ARM_R,FOOT_L,FOOT_R,TUFT))
    # thin cut along the body contour where it overlaps horns, tuft, arms and feet,
    # so the white silhouette keeps the horns readable
    seams=(f'<defs><clipPath id="parts">{parts}</clipPath></defs>'
           f'<path d="{BODY}" fill="none" stroke="#000" stroke-width="{inner}" clip-path="url(#parts)"/>')
    return (seams+f'<circle cx="{ex}" cy="{ey}" r="{r_in}" fill="#000"/>'
            f'<path d="{MOUTH}" fill="none" stroke="#000" stroke-width="{inner+1.5}" stroke-linecap="round"/>'), (ix,iy,ir)
