"""Island map hub background, morning lagoon. Vector (SVG) in dp units 812x375, rendered @1x/@2x/@3x."""
import cairosvg, math, json, os, random
P='#3A1752'; LAG='#3FC1B0'; FOAM='#D4F4EE'; SAND='#FFE4BF'; SUN='#FFD60A'; CREAM='#FFF6E5'
W,H=812,375
# landmark anchors (centre of the 140 dp landmark box), dp in the 812x375 frame
SPOTS={'cave':(165,112),'forest':(328,150),'lighthouse':(486,100),'beach':(150,272),
       'library':(318,290),'shadow':(610,176),'islets':(662,300)}
GUIDE=(480,296)   # free sand spot for Fuzzle (guide), no landmark
PAD_DY=40          # pad centre sits under the landmark base

def cr(pts,closed=True,t=0.5):
    """Catmull-Rom -> cubic bezier path"""
    n=len(pts); d=f'M{pts[0][0]:.1f},{pts[0][1]:.1f} '
    rng=range(n) if closed else range(n-1)
    for i in rng:
        p0=pts[(i-1)%n]; p1=pts[i]; p2=pts[(i+1)%n]; p3=pts[(i+2)%n]
        c1=(p1[0]+(p2[0]-p0[0])*t/3, p1[1]+(p2[1]-p0[1])*t/3)
        c2=(p2[0]-(p3[0]-p1[0])*t/3, p2[1]-(p3[1]-p1[1])*t/3)
        d+=f'C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f} '
    return d+('Z' if closed else '')
def blobpts(cx,cy,rx,ry,n=10,j=0.08,seed=1):
    r=random.Random(seed)
    return [(cx+rx*math.cos(a)*(1+r.uniform(-j,j)), cy+ry*math.sin(a)*(1+r.uniform(-j,j))) for a in [2*math.pi*k/n for k in range(n)]]

MAIN=[(92,150),(106,84),(170,48),(236,52),(262,72),(300,52),(380,46),(440,54),(470,36),(530,34),(566,70),(552,138),(526,180),(548,236),(562,300),(526,346),(440,358),(352,364),(272,354),(244,334),(214,352),(140,352),(80,322),(60,262),(74,200)]
MEADOW=[(232,104),(300,96),(380,104),(424,142),(418,210),(392,246),(330,252),(262,240),(226,196),(214,148)]
ISLET_A=blobpts(614,214,82,46,12,0.06,3)
ROCKHILL=[(108,128),(122,92),(162,72),(206,84),(226,120),(214,160),(170,168),(124,160)]
CAPE_ROCK=[(440,120),(456,86),(500,74),(540,92),(546,130),(512,146),(466,146)]

def expand(pts,cx,cy,k):
    return [(cx+(x-cx)*k, cy+(y-cy)*k) for x,y in pts]
def centroid(pts): return (sum(p[0] for p in pts)/len(pts), sum(p[1] for p in pts)/len(pts))

def land(pts,fill,shade,hi,outline=3.2,ring=True,rid='x'):
    cx,cy=centroid(pts); d=cr(pts)
    shallow=cr(expand(pts,cx,cy,1.10)); foam=cr(expand(pts,cx,cy,1.035))
    s=''
    if ring:
        s+=f'<path d="{shallow}" fill="#7DD8CB" opacity=".75"/>'
        s+=f'<path d="{foam}" fill="{FOAM}"/>'
        s+=f'<path d="{foam}" fill="none" stroke="#A9E7DE" stroke-width="2"/>'
    s+=(f'<clipPath id="cl{rid}"><path d="{d}"/></clipPath><g clip-path="url(#cl{rid})">'
        f'<path d="{d}" fill="{shade}"/><path d="{d}" fill="{fill}" transform="translate(-4,-6)"/>'
        f'<path d="{d}" fill="url(#hiTL)" opacity=".55"/></g>'
        f'<path d="{d}" fill="none" stroke="{P}" stroke-width="{outline}" stroke-linejoin="round"/>')
    return s

def tree(x,y,s=1.0,c1='#9ED05A',c2='#6FA83A'):
    t=f'<g transform="translate({x} {y}) scale({s})">'
    t+=f'<ellipse cx="0" cy="16" rx="13" ry="4" fill="{P}" opacity=".12"/>'
    t+=f'<path d="M-3,16 L-2.5,4 L2.5,4 L3,16 Z" fill="#B07A4A" stroke="{P}" stroke-width="2" stroke-linejoin="round"/>'
    blobs=[(-7,-2,8),(7,-2,8),(0,-10,10),(0,0,9)]
    for bx,by,r in blobs: t+=f'<circle cx="{bx}" cy="{by}" r="{r+1.6}" fill="{P}"/>'
    for bx,by,r in blobs: t+=f'<circle cx="{bx}" cy="{by}" r="{r}" fill="{c2}"/>'
    for bx,by,r in blobs: t+=f'<circle cx="{bx-1.5}" cy="{by-2}" r="{r-1.5}" fill="{c1}"/>'
    t+=f'<ellipse cx="-4" cy="-13" rx="4" ry="2.2" fill="#E3F5B8" opacity=".8" transform="rotate(-25 -4 -13)"/></g>'
    return t
def palm(x,y,s=1.0,flip=False):
    f=-1 if flip else 1
    t=f'<g transform="translate({x} {y}) scale({s*f} {s})">'
    t+=f'<ellipse cx="2" cy="1" rx="11" ry="3.5" fill="{P}" opacity=".12"/>'
    t+=f'<path d="M0,0 C1,-10 4,-20 9,-28" fill="none" stroke="{P}" stroke-width="6" stroke-linecap="round"/>'
    t+=f'<path d="M0,0 C1,-10 4,-20 9,-28" fill="none" stroke="#C58A55" stroke-width="3" stroke-linecap="round"/>'
    for a in [-160,-115,-60,-20,25]:
        r=math.radians(a); ex=9+15*math.cos(r); ey=-28+10*math.sin(r)+6
        t+=(f'<path d="M9,-28 Q{9+8*math.cos(r)},{-34+6*math.sin(r)} {ex:.1f},{ey:.1f} Q{9+6*math.cos(r)},{-26+4*math.sin(r)} 9,-28 Z" '
            f'fill="#86BE34" stroke="{P}" stroke-width="1.8" stroke-linejoin="round"/>')
    t+=f'<circle cx="9" cy="-28" r="2.4" fill="#B07A4A" stroke="{P}" stroke-width="1.4"/></g>'
    return t
def rock(x,y,s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})"><path d="M-9,4 C-10,-3 -5,-8 0,-8 C6,-8 10,-3 9,4 Z" fill="#A79FBE" stroke="{P}" stroke-width="2" stroke-linejoin="round"/>'
            f'<ellipse cx="-3" cy="-4" rx="3" ry="1.5" fill="#D8D3E6"/></g>')
def flower(x,y,c='#FC647D'):
    return ''.join(f'<circle cx="{x+3*math.cos(a)}" cy="{y+3*math.sin(a)}" r="2" fill="{c}" stroke="{P}" stroke-width=".9"/>' for a in [0,2.1,4.2])+f'<circle cx="{x}" cy="{y}" r="1.4" fill="{SUN}"/>'
def ripple(x,y,w=22,op=.75):
    return f'<path d="M{x},{y} q{w/4},-4 {w/2},0 t{w/2},0" fill="none" stroke="{FOAM}" stroke-width="2.4" stroke-linecap="round" opacity="{op}"/>'
def cloud(x,y,s=1.0):
    d='M-30,6 C-36,6 -38,-4 -30,-6 C-30,-16 -16,-20 -10,-12 C-6,-22 12,-22 14,-10 C24,-14 34,-6 28,4 C30,8 26,10 22,10 L-26,10 C-30,10 -32,8 -30,6 Z'
    return (f'<g transform="translate({x+10} {y+34}) scale({s*1.05} {s*.6})" opacity=".13"><path d="{d}" fill="{P}"/></g>'
            f'<g transform="translate({x} {y}) scale({s})"><path d="{d}" fill="#F2EBF3"/><path d="{d}" fill="{CREAM}" transform="translate(-1.5,-2.5)" clip-path="url(#cloudclip)"/>'
            f'<path d="{d}" fill="none" stroke="{P}" stroke-width="{2.6/s:.2f}" stroke-linejoin="round"/></g>')
def pad(x,y,kind='sand'):
    cy=y+PAD_DY
    if kind=='water':
        return (f'<ellipse cx="{x}" cy="{cy-6}" rx="66" ry="30" fill="#8FE0D4" opacity=".9"/>'
                f'<ellipse cx="{x}" cy="{cy-6}" rx="66" ry="30" fill="none" stroke="{FOAM}" stroke-width="3" stroke-dasharray="10 7" stroke-linecap="round"/>')
    fill,rim={'sand':('#FFF0D9','#EFC48C'),'grass':('#E6F4C8','#9FC860'),'rock':('#E4DFEE','#A79FBE')}[kind]
    return (f'<ellipse cx="{x}" cy="{cy+3}" rx="60" ry="23" fill="{rim}" opacity=".9"/>'
            f'<ellipse cx="{x}" cy="{cy}" rx="58" ry="21" fill="{fill}"/>'
            f'<ellipse cx="{x-14}" cy="{cy-7}" rx="24" ry="6" fill="#FFFFFF" opacity=".35"/>'
            f'<ellipse cx="{x}" cy="{cy}" rx="58" ry="21" fill="none" stroke="{P}" stroke-width="1.6" opacity=".35"/>')
def stepping(a,b,n,r=3.2,col='#F7D8A8',bend=0):
    (x1,y1),(x2,y2)=a,b; s=''
    mx,my=(x1+x2)/2+bend*(y2-y1)/100*10,(y1+y2)/2-bend*(x2-x1)/100*10
    for i in range(1,n+1):
        t=i/(n+1); x=(1-t)**2*x1+2*(1-t)*t*mx+t*t*x2; y=(1-t)**2*y1+2*(1-t)*t*my+t*t*y2
        s+=f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{r*1.4}" ry="{r}" fill="{col}" stroke="{P}" stroke-width="1.3" stroke-opacity=".45"/>'
    return s

def build():
    defs=(f'<defs><linearGradient id="sea" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6ED6C6"/><stop offset=".45" stop-color="{LAG}"/><stop offset="1" stop-color="#33AC9E"/></linearGradient>'
          f'<radialGradient id="sunglow" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(30 20) scale(430 330)"><stop offset="0" stop-color="{SUN}" stop-opacity=".55"/><stop offset=".35" stop-color="#FFF3B0" stop-opacity=".22"/><stop offset="1" stop-color="#FFF3B0" stop-opacity="0"/></radialGradient>'
          f'<linearGradient id="hiTL" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".55"/><stop offset=".5" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="{P}" stop-opacity=".10"/></linearGradient>'
          f'<radialGradient id="vig" cx=".35" cy=".3" r=".95"><stop offset=".6" stop-color="{P}" stop-opacity="0"/><stop offset="1" stop-color="{P}" stop-opacity=".16"/></radialGradient>'
          f'<clipPath id="cloudclip"><rect x="-60" y="-40" width="120" height="80"/></clipPath></defs>')
    s=f'<rect width="{W}" height="{H}" fill="url(#sea)"/>'
    # caustic ripples
    rnd=random.Random(7)
    for i in range(70):
        x=rnd.uniform(0,W); y=rnd.uniform(0,H)
        ok=all(math.hypot(x-sx,(y-sy-20)*1.6)>95 for sx,sy in SPOTS.values()) and not (60<x<575 and 30<y<370)
        if ok: s+=ripple(x,y,rnd.uniform(14,26),rnd.uniform(.45,.8))
    # puzzle sandbars (tiny dots of sand under shallow water)
    s+=land(MAIN,SAND,'#F3C994','#FFFFFF',rid='main')
    s+=land(ISLET_A,SAND,'#F3C994','#FFFFFF',rid='isA')
    # meadow
    md=cr(MEADOW)
    s+=(f'<clipPath id="clmd"><path d="{md}"/></clipPath><g clip-path="url(#clmd)"><path d="{md}" fill="#A9D46A"/>'
        f'<path d="{md}" fill="#CFE8A8" transform="translate(-4,-6)"/></g><path d="{md}" fill="none" stroke="{P}" stroke-width="2.4" stroke-opacity=".7" stroke-linejoin="round"/>')
    # boulder clusters behind the cave and lighthouse pads (rocky ground, no dome)
    for x,y,sc in [(108,146,1.3),(124,132,1.0),(214,150,1.2),(226,138,.9),(198,96,.8),(436,124,1.1),(446,110,.8),(540,126,1.2),(530,112,.9),(552,148,.8)]:
        s+=rock(x,y,sc)
    # sand speckles and grass tufts (texture)
    rnd2=random.Random(11)
    for i in range(160):
        x=rnd2.uniform(70,560); y=rnd2.uniform(50,350)
        s+=f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rnd2.uniform(.8,1.6):.1f}" fill="#E9B97E" opacity=".55"/>'
    for i in range(28):
        x=rnd2.uniform(225,415); y=rnd2.uniform(108,245)
        s+=f'<path d="M{x-3:.1f},{y:.1f} q1,-4 2,-5 M{x:.1f},{y:.1f} q0,-5 0,-6 M{x+3:.1f},{y:.1f} q-1,-4 -2,-5" stroke="#86BE34" stroke-width="1.3" fill="none" stroke-linecap="round"/>'
    # stepping-stone path linking the places (decorative, no implied order)
    pad_c={k:(x,y+PAD_DY) for k,(x,y) in SPOTS.items()}
    s+=stepping(pad_c['beach'],pad_c['library'],4,bend=-1.5)+stepping(pad_c['library'],(GUIDE[0],GUIDE[1]+PAD_DY),3)
    s+=stepping(pad_c['cave'],pad_c['forest'],3,bend=1)+stepping(pad_c['forest'],pad_c['library'],2,col='#F4E7C4')
    s+=stepping((GUIDE[0],GUIDE[1]+PAD_DY),pad_c['lighthouse'],4,bend=-1)
    s+=stepping((540,170),(565,215),3,r=3.6,col='#C9C2D9')       # stones to the shadow islet
    s+=stepping((548,300),(598,330),3,r=3.6,col='#C9C2D9')       # stones to the puzzle sandbars
    s+=stepping(pad_c['beach'],pad_c['cave'],3,bend=1.2)
    # pads (clear empty spot for each place)
    kinds={'cave':'rock','forest':'grass','lighthouse':'rock','beach':'sand','library':'sand','shadow':'sand','islets':'water'}
    for k,(x,y) in SPOTS.items(): s+=pad(x,y,kinds[k])
    s+=pad(GUIDE[0],GUIDE[1]-6,'sand')
    # decor (kept outside the 130 dp hit circles)
    for x,y,sc in [(250,86,.8),(410,236,.85),(432,252,.7),(250,240,.75),(538,256,.75),(404,64,.7),(214,212,.7),(262,104,.6)]: s+=tree(x,y,sc)
    for x,y,sc,f in [(84,214,.9,False),(232,330,.8,True),(556,318,.8,False),(676,206,.75,True)]: s+=palm(x,y,sc,f)
    for x,y,sc in [(100,330,.8),(530,330,.9),(560,206,.7),(700,360,.9),(740,252,.8),(588,232,.7)]: s+=rock(x,y,sc)
    for x,y,c in [(370,250,'#FC647D'),(272,110,'#FFD60A'),(398,120,'#A75BAD'),(240,180,'#FC647D'),(425,180,'#FFD60A')]: s+=flower(x,y,c)
    # clouds (top centre-left, bottom right corner), not over places nor the top-right UI zone
    s+=cloud(395,22,.85)+cloud(770,350,.7)+cloud(40,120,.6)
    # morning light top-left + gentle vignette
    s+=f'<rect width="{W}" height="{H}" fill="url(#sunglow)"/>'
    s+=(f'<g><circle cx="18" cy="14" r="52" fill="{SUN}" opacity=".25"/><circle cx="12" cy="8" r="38" fill="{SUN}" stroke="{P}" stroke-width="3.2"/>'
        f'<circle cx="2" cy="-2" r="24" fill="#FFE866"/>'+''.join(f'<path d="M{12+50*math.cos(math.radians(a)):.1f},{8+50*math.sin(math.radians(a)):.1f} L{12+64*math.cos(math.radians(a)):.1f},{8+64*math.sin(math.radians(a)):.1f}" stroke="{SUN}" stroke-width="6" stroke-linecap="round" opacity=".85"/><path d="M{12+50*math.cos(math.radians(a)):.1f},{8+50*math.sin(math.radians(a)):.1f} L{12+64*math.cos(math.radians(a)):.1f},{8+64*math.sin(math.radians(a)):.1f}" stroke="{P}" stroke-width="1.6" stroke-linecap="round" opacity="0"/>' for a in [15,40,65,90])+'</g>')
    s+=f'<rect width="{W}" height="{H}" fill="url(#vig)"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{defs}{s}</svg>'

if __name__=='__main__':
    OUT='/workspace/seamonsters/design/assets/map'
    os.makedirs(OUT+'/2.0x',exist_ok=True); os.makedirs(OUT+'/3.0x',exist_ok=True)
    svg=build(); open('/workspace/seamonsters/design/_work/pipeline/map_island.svg','w').write(svg)
    from PIL import Image; import io
    for k,pre in [(1,''),(2,'2.0x/'),(3,'3.0x/')]:
        png=cairosvg.svg2png(bytestring=svg.encode(),output_width=W*k,output_height=H*k)
        im=Image.open(io.BytesIO(png)).convert('RGB')
        im.save(f'{OUT}/{pre}map_island_morning.png',optimize=True)
        # phone-safe crop: centred 16:9 (667x375 dp), the part every landscape phone shows with BoxFit.cover
        cw=round(667*k); x0=(W*k-cw)//2
        im.crop((x0,0,x0+cw,H*k)).save(f'{OUT}/{pre}map_island_morning_safe16x9.png',optimize=True)
    json.dump({'frame_dp':[W,H],'spots':SPOTS,'guide':GUIDE},open('/workspace/seamonsters/design/_work/pipeline/map_layout.json','w'))
    print('ok')
