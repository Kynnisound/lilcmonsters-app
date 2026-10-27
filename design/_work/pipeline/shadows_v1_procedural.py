"""Shadow-game silhouettes (BUG-005). Body = brand cutout alpha mask, plus exaggerated drawn features.
Framing = Webboy's shadow module: square slot, BoxFit.contain, centred (tool/shadow_similarity.py uses 200x200).
Output: flat plum #3A1752 at 85 % alpha (spec §7: plum silhouettes 85 %), transparent background."""
import numpy as np, cv2, itertools, json, math, os, sys
from PIL import Image, ImageDraw
REF='/workspace/lilcmonsters/ref'
OUT='/workspace/seamonsters/design/assets/shadows'
N=1400  # work canvas
NAMES=['fuzzle','pip','dottie','zib','bitsy']
PLUM=(58,23,82)

def body(name, width, cx, base_y):
    a=np.array(Image.open(f'{REF}/{name}_c.png').convert('RGBA'))[...,3]
    m=(a>150).astype(np.uint8)*255
    m=cv2.morphologyEx(m,cv2.MORPH_OPEN,np.ones((5,5),np.uint8))   # drop the soft ground shadow
    ys,xs=np.nonzero(m); m=m[ys.min():ys.max()+1, xs.min():xs.max()+1]
    h=int(m.shape[0]*width/m.shape[1]); m=cv2.resize(m,(width,h),interpolation=cv2.INTER_CUBIC)
    c=np.zeros((N,N),np.uint8); x0=cx-width//2; y0=base_y-h
    c[y0:y0+h, x0:x0+width]=np.maximum(c[y0:y0+h, x0:x0+width], m)
    return c, (x0,y0,width,h)

class Pen:
    def __init__(s,m): s.im=Image.fromarray(m); s.d=ImageDraw.Draw(s.im)
    def disc(s,x,y,r,v=255): s.d.ellipse((x-r,y-r,x+r,y+r),fill=v)
    def ell(s,x,y,rx,ry,v=255): s.d.ellipse((x-rx,y-ry,x+rx,y+ry),fill=v)
    def poly(s,pts,v=255): s.d.polygon([tuple(p) for p in pts],fill=v)
    def stroke(s,pts,r0,r1=None,v=255):
        """tapered thick stroke through points (quadratic/cubic sampled by caller)"""
        r1=r0 if r1 is None else r1; n=len(pts)
        for i,(x,y) in enumerate(pts):
            r=r0+(r1-r0)*i/max(1,n-1); s.disc(x,y,r,v)
    def capsule(s,a,b,r,v=255):
        n=int(math.dist(a,b)/3)+2
        s.stroke([(a[0]+(b[0]-a[0])*t/(n-1),a[1]+(b[1]-a[1])*t/(n-1)) for t in range(n)],r,r,v)
    def arr(s): return np.array(s.im)

def bez(p0,p1,p2,p3=None,n=60):
    out=[]
    for i in range(n):
        t=i/(n-1)
        if p3 is None: x=(1-t)**2*p0[0]+2*(1-t)*t*p1[0]+t*t*p2[0]; y=(1-t)**2*p0[1]+2*(1-t)*t*p1[1]+t*t*p2[1]
        else: x=(1-t)**3*p0[0]+3*(1-t)**2*t*p1[0]+3*(1-t)*t*t*p2[0]+t**3*p3[0]; y=(1-t)**3*p0[1]+3*(1-t)**2*t*p1[1]+3*(1-t)*t*t*p2[1]+t**3*p3[1]
        out.append((x,y))
    return out
def fluff(p,cx,cy,rx,ry,n,r,start=0,end=360):
    for k in range(n):
        a=math.radians(start+(end-start)*k/max(1,n-1)); p.disc(cx+rx*math.cos(a),cy+ry*math.sin(a),r)

def fuzzle(P):
    # big hug: wide arms flung out, huge curled horns, fluffy ruff -> the widest, lowest shape
    m,(x0,y0,w,h)=body('fuzzle',560,700,1000); p=Pen(m); cx=700
    for sgn in (-1,1):
        sh=(cx+sgn*230,y0+h*0.52)
        hand=(cx+sgn*(420*P.get('arm',1)),y0+h*0.26)
        p.capsule(sh,hand,76)
        fluff(p,hand[0],hand[1],62,62,8,34)
        for k in range(3): p.disc(hand[0]+sgn*40,hand[1]-50+k*45,24)     # fluffy fingers
        # big curled horn
        hb=(cx+sgn*170,y0+80)
        p.stroke(bez(hb,(cx+sgn*230,y0+10),(cx+sgn*250,y0-90),(cx+sgn*300,y0-150)),66,22)
    fluff(p,cx,y0+h*0.55,w*0.52,h*0.45,40,30)
    return p.arr()

def pip(P):
    # cyclops: one huge eye hole with pupil, one arm waving high, horns curving outward
    m,(x0,y0,w,h)=body('pip',440,700,1060); p=Pen(m); cx=700
    for sgn in (-1,1):
        hb=(cx+sgn*150,y0+40)
        p.stroke(bez(hb,(cx+sgn*185,y0-5),(cx+sgn*230,y0-30)),24,10)
    # waving arm (right): from the shoulder, up and out, with a fluffy hand
    p.capsule((cx+180,y0+h*0.62),(cx+340,y0+h*0.30),44)
    fluff(p,cx+350,y0+h*0.26,40,40,7,26)
    # eye: ring hole (keeps pupil) -> reads as a single eye in silhouette
    ex,ey,er=cx-6,y0+h*0.36,P.get('eye',105)
    p.disc(ex,ey,er,0); p.disc(ex+10,ey+8,er*0.46,255)
    return p.arr()

def dottie(P):
    # tall painter: giant paintbrush held up in her hand, tall straight horns, polka-dot holes
    m,(x0,y0,w,h)=body('dottie',360,640,1200); p=Pen(m); cx=640
    for sgn in (-1,1):
        p.stroke(bez((cx+sgn*105,y0+80),(cx+sgn*135,y0-10),(cx+sgn*145,y0-110)),40,14)
    hand=(cx+250,y0+h*0.22)
    p.capsule((cx+140,y0+h*0.50),hand,40); fluff(p,hand[0],hand[1],30,30,6,22)
    p.capsule((cx+215,y0+h*0.45),(cx+330,y0-150),17)        # brush handle through the hand
    p.ell(cx+335,y0-165,34,26)                              # ferrule
    p.ell(cx+340,y0-250,52,80)                              # fat bristle tuft
    p.poly([(cx+300,y0-270),(cx+345,y0-380),(cx+385,y0-270)])     # pointed tip
    p.disc(cx+300,y0-130,20); p.disc(cx+292,y0-95,13)       # paint drops
    for (dx,dy,r) in [(-70,0.62,30),(60,0.72,24),(-20,0.82,20)]:
        p.disc(cx+dx,y0+h*dy,r,0)
    return p.arr()

def zib(P):
    # curly-antenna finder: two tall springy antennae with bobbles, magnifier held out to the left
    m,(x0,y0,w,h)=body('zib',420,760,1060); p=Pen(m); cx=760
    for sgn,ph in ((-1,0),(1,1.3)):
        base=(cx+sgn*40,y0+40); pts=[]
        for i in range(120):
            t=i/119; yy=base[1]-t*330; xx=base[0]+sgn*t*90+math.sin(t*4*math.pi+ph)*38
            pts.append((xx,yy))
        p.stroke(pts,16,12); p.disc(pts[-1][0],pts[-1][1],34)
    for sgn in (-1,1): p.stroke(bez((cx+sgn*150,y0+90),(cx+sgn*200,y0+20),(cx+sgn*190,y0-40)),38,12)
    # magnifier (ring with hole) held out on the left
    p.capsule((cx-180,y0+h*0.55),(cx-330,y0+h*0.48),38)
    mx,my=cx-470,y0+h*0.30
    p.capsule((cx-330,y0+h*0.50),(mx+60,my+70),22)
    p.disc(mx,my,110); p.disc(mx,my,72,0)
    return p.arr()

def bitsy(P):
    # tiny Bitsy floating under her leaf parachute (site intro), holding the stem with both arms up, pigtail tufts
    m,(x0,y0,w,h)=body('bitsy',300,700,1250); p=Pen(m); cx=700
    for sgn in (-1,1):
        p.capsule((cx+sgn*110,y0+h*0.45),(cx+sgn*40,y0-90),30)
        p.stroke(bez((cx+sgn*100,y0+50),(cx+sgn*180,y0+10),(cx+sgn*190,y0-60)),34,10)
    p.capsule((cx,y0-60),(cx,y0-300),16)              # leaf stem held in both hands
    # big almond leaf (pointed at both ends), tilted, with a mid-rib gap
    pts=[]
    L,Wd,ang=400,170,math.radians(-18)
    for i in range(81):
        t=-1+2*i/80; x=t*L; y=-Wd*(1-t*t)**0.8; pts.append((x,y))
    for i in range(81):
        t=1-2*i/80; x=t*L; y=Wd*0.55*(1-t*t)**0.8; pts.append((x,y))
    ox,oy=cx,y0-330
    pts=[(ox+x*math.cos(ang)-y*math.sin(ang), oy+x*math.sin(ang)+y*math.cos(ang)) for x,y in pts]
    p.poly(pts)
    R=lambda x,y:(ox+x*math.cos(ang)-y*math.sin(ang), oy+x*math.sin(ang)+y*math.cos(ang))
    p.stroke([R(x,-8) for x in range(-340,341,6)],8,8,0)                       # mid-rib
    for x0v in (-220,-90,40,170):                                              # side veins
        p.stroke([R(x0v+t*1.2,-8-t) for t in range(0,95,4)],6,4,0)
    p.stroke([R(400+t*0.6,-math.sin(t/12)*14) for t in range(0,70,3)],14,9)   # curly leaf tip
    return p.arr()

FN={'fuzzle':fuzzle,'pip':pip,'dottie':dottie,'zib':zib,'bitsy':bitsy}

def finish(m, size=512, pad=0.04):
    m=cv2.GaussianBlur(m,(0,0),3); m=((m>127)*255).astype(np.uint8)
    m=cv2.GaussianBlur(m,(0,0),1.2)
    ys,xs=np.nonzero(m>8); m=m[ys.min():ys.max()+1, xs.min():xs.max()+1]
    inner=int(size*(1-2*pad)); s=inner/max(m.shape)
    r=cv2.resize(m,(max(1,round(m.shape[1]*s)),max(1,round(m.shape[0]*s))),interpolation=cv2.INTER_AREA)
    c=np.zeros((size,size),np.uint8); y0=(size-r.shape[0])//2; x0=(size-r.shape[1])//2
    c[y0:y0+r.shape[0],x0:x0+r.shape[1]]=r
    return c

def iou_table(masks):
    t={}
    for a,b in itertools.combinations(NAMES,2):
        A=masks[a]>128; B=masks[b]>128; t[(a,b)]=float((A&B).sum()/(A|B).sum())
    return t

def webboy_iou(paths):
    """same method as tool/shadow_similarity.py: contain in 200x200, alpha>128"""
    ms={}
    for n,pth in paths.items():
        im=Image.open(pth).convert('RGBA'); w,h=im.size; s=200/max(w,h)
        im=im.resize((max(1,round(w*s)),max(1,round(h*s)))); c=Image.new('RGBA',(200,200)); c.paste(im,((200-im.size[0])//2,(200-im.size[1])//2))
        ms[n]=np.array(c)[...,3]
    return iou_table(ms)

if __name__=='__main__':
    P=json.loads(sys.argv[1]) if len(sys.argv)>1 else {}
    masks={n:finish(FN[n](P)) for n in NAMES}
    os.makedirs(OUT+'/512',exist_ok=True); os.makedirs(OUT+'/2.0x',exist_ok=True); os.makedirs(OUT+'/3.0x',exist_ok=True)
    paths={}
    for n,m in masks.items():
        a=(m.astype(float)*0.85).astype(np.uint8)
        rgba=np.dstack([np.full_like(m,PLUM[0]),np.full_like(m,PLUM[1]),np.full_like(m,PLUM[2]),a])
        im=Image.fromarray(rgba,'RGBA'); p512=f'{OUT}/512/shadow_{n}_512.png'; im.save(p512,optimize=True); paths[n]=p512
        for k,pre in [(1,''),(2,'2.0x/'),(3,'3.0x/')]:
            mk=finish(FN[n](P),size=170*k) if k==3 else cv2.resize(m,(170*k,170*k),interpolation=cv2.INTER_AREA)
            ak=(mk.astype(float)*0.85).astype(np.uint8)
            Image.fromarray(np.dstack([np.full_like(mk,PLUM[0]),np.full_like(mk,PLUM[1]),np.full_like(mk,PLUM[2]),ak]),'RGBA').save(f'{OUT}/{pre}shadow_{n}.png',optimize=True)
    t=iou_table(masks); tw=webboy_iou(paths)
    for k in t: print(f'{k[0]:>7}-{k[1]:<7} 512:{t[k]:.3f}  200(webboy method):{tw[k]:.3f}')
    print('max',max(t.values()),max(tw.values()))
    json.dump({f'{a}-{b}':{'iou_512':round(t[(a,b)],3),'iou_200':round(tw[(a,b)],3)} for a,b in t},open(OUT+'/../../_work/pipeline/shadow_iou.json','w'),indent=1)
