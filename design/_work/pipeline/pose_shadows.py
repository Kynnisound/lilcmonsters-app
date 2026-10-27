"""BUG-005 v2: colour 'shadow-game pose' illustrations + silhouettes built DIRECTLY from their alpha.
Source: _work/poses/{name}_X.jpg (GenerateImage, brand cutout as reference, plain white bg).
Out: assets/shadows/color/{name}.png (170 dp, 2.0x, 3.0x, 512/) and assets/shadows/shadow_{name}.png (same frame).
IoU: own implementation of the tool/shadow_similarity.py method (contain 200x200, alpha>128) + 512 px masks."""
import numpy as np, cv2, json, os, sys, itertools
from PIL import Image
D='/workspace/seamonsters/design'; SRC=D+'/_work/poses'; OUT=D+'/assets/shadows'
NAMES=['fuzzle','pip','dottie','zib','bitsy']
PICK=json.load(open(SRC+'/pick.json')) if os.path.exists(SRC+'/pick.json') else {n:'a' for n in NAMES}
PLUM=(58,23,82); PAD=0.04; MASTER=1024

def cutout(n):
    v=PICK[n]; im=np.array(Image.open(f'{SRC}/{n}_{v.rstrip("~")}.jpg').convert('RGB')).astype(float)
    if v.endswith('~'): im=im[:,::-1].copy()   # mirrored variant
    d=np.sqrt(((im-255)**2).sum(2))
    nw=(d<30).astype(np.uint8)
    k,lab,st,_=cv2.connectedComponentsWithStats(nw,connectivity=4)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bg=np.isin(lab,list(border))
    for i in range(1,k):                       # enclosed pure-white pockets (under the leaf, behind a handle)
        if i not in border and st[i,4]>800 and d[lab==i].mean()<7: bg|=lab==i
    fg=(~bg).astype(np.uint8)
    k,lab,st,_=cv2.connectedComponentsWithStats(fg,connectivity=8)
    big=np.argmax(st[1:,4])+1; fg=(lab==big).astype(np.uint8)
    # fill small interior specks only (keep real pockets open)
    inv=(1-fg).astype(np.uint8); k,lab,st,_=cv2.connectedComponentsWithStats(inv,connectivity=4)
    for i in range(1,k):
        if st[i,4]<400 and not (lab==i)[0].any(): fg[lab==i]=1
    fg=cv2.erode(fg,np.ones((3,3),np.uint8),iterations=2)   # drop the white fringe
    a=cv2.GaussianBlur(fg.astype(np.float32),(0,0),1.4); a=np.clip((a-0.5)*2.0+0.5,0,1)
    glass=np.zeros_like(a,bool)
    if n=='zib':                               # magnifier lens = see-through glass (35 %): the shadow keeps the ring
        cyan=((im[...,2]>im[...,0]+12)&(d<110)|(d<45)).astype(np.uint8)
        cyan[bg]=0
        k,lab,st,_=cv2.connectedComponentsWithStats(cyan,connectivity=4)
        if k>1:
            i=np.argmax(st[1:,4])+1; L=(lab==i).astype(np.uint8)
            cn,_=cv2.findContours(L,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE); hull=np.zeros_like(L)
            cv2.drawContours(hull,[cv2.convexHull(max(cn,key=cv2.contourArea))],-1,1,-1)
            hull=cv2.dilate(hull,np.ones((5,5),np.uint8),iterations=1)
            gold=(im[...,0]>150)&(im[...,2]<130)            # stop at the golden rim
            glass=(hull>0)&~gold
            g=cv2.GaussianBlur(glass.astype(np.float32),(0,0),1.0)
            a=a*(1-g)+np.minimum(a,0.40)*g                   # see-through glass, 40 % (< 50 % mask threshold)
            glass=g>0.5
    return np.dstack([im,a*255]).clip(0,255).astype(np.uint8), glass

def holes(n,rgba):
    """interior features punched through the shadow (Pip + Dottie single eye, Dottie's dots)"""
    im=rgba[...,:3].astype(float); a=rgba[...,3]>128; h=np.zeros(a.shape,np.uint8)
    d=np.sqrt(((im-255)**2).sum(2))
    if n in ('pip','dottie'):                 # eye white (largest cream blob) -> filled disc incl. pupil
        cw=((d<40)&a).astype(np.uint8); k,lab,st,_=cv2.connectedComponentsWithStats(cw,connectivity=4)
        i=np.argmax(st[1:,4])+1; x,y,w,hh=st[i,:4]; cx,cy=x+w/2,y+hh/2; r=max(w,hh)/2
        cv2.circle(h,(int(cx),int(cy)),int(r*0.80),1,-1)
    if n=='dottie':                            # light-green polka dots -> round holes
        hsv=cv2.cvtColor(rgba[...,:3],cv2.COLOR_RGB2HSV).astype(int)
        lite=((hsv[...,0]>25)&(hsv[...,0]<45)&(hsv[...,2]>200)&(hsv[...,1]<170)&a).astype(np.uint8)
        lite=cv2.morphologyEx(lite,cv2.MORPH_OPEN,np.ones((7,7),np.uint8))
        k,lab,st,cen=cv2.connectedComponentsWithStats(lite,connectivity=8)
        for i in range(1,k):
            x,y,w,hh,ar=st[i]
            if ar>900 and 0.6<w/max(hh,1)<1.6 and y>420:
                cv2.circle(h,(int(cen[i][0]),int(cen[i][1])),int(min(w,hh)/2*0.78),1,-1)
    return h>0

def frame(arr,bbox,size):
    x0,y0,x1,y1=bbox; c=arr[y0:y1,x0:x1]
    inner=int(round(size*(1-2*PAD))); s=inner/max(c.shape[:2])
    r=cv2.resize(c,(max(1,round(c.shape[1]*s)),max(1,round(c.shape[0]*s))),interpolation=cv2.INTER_AREA)
    out=np.zeros((size,size)+arr.shape[2:],arr.dtype); oy=(size-r.shape[0])//2; ox=(size-r.shape[1])//2
    out[oy:oy+r.shape[0],ox:ox+r.shape[1]]=r; return out

def premult_resize(rgba,size):
    f=rgba.astype(np.float32); f[...,:3]*=f[...,3:]/255
    r=frame(f,BB,size); a=r[...,3:]; rgb=np.where(a>0,r[...,:3]*255/np.maximum(a,1e-3),0)
    return np.dstack([rgb,a]).clip(0,255).astype(np.uint8)

def mask200(path):  # same method as tool/shadow_similarity.py, own code
    im=Image.open(path).convert('RGBA'); w,h=im.size; s=200/max(w,h)
    im=im.resize((max(1,round(w*s)),max(1,round(h*s)))); c=Image.new('RGBA',(200,200)); c.paste(im,((200-im.size[0])//2,(200-im.size[1])//2))
    return np.array(c)[...,3]>128
def iou(A,B): return float((A&B).sum()/(A|B).sum())

if __name__=='__main__':
    res={}; m512={}; p512={}; holes_px={}
    for n in NAMES:
        rgba,glass=cutout(n); a=rgba[...,3]
        ys,xs=np.nonzero(a>8); BB=(xs.min(),ys.min(),xs.max()+1,ys.max()+1)
        hl=holes(n,rgba)
        # shadow alpha = colour alpha (exact), minus holes; glass counts as see-through
        sa=a.astype(np.float32)/255
        if hl.any(): sa=np.minimum(sa,1-cv2.GaussianBlur(hl.astype(np.float32),(0,0),1.4))
        sa=np.where(glass,0,sa)
        sh=np.dstack([np.full(a.shape,PLUM[0]),np.full(a.shape,PLUM[1]),np.full(a.shape,PLUM[2]),sa*255]).astype(np.float32)
        for size,folder in [(512,'512/'),(170,''),(340,'2.0x/'),(510,'3.0x/')]:
            col=premult_resize(rgba,size)
            Image.fromarray(col,'RGBA').save(f'{OUT}/color/{folder}{n}{"_512" if size==512 else ""}.png',optimize=True)
            s=frame(sh,BB,size); s[...,:3]=PLUM; s[...,3]*=0.85
            sp=f'{OUT}/{folder}shadow_{n}{"_512" if size==512 else ""}.png'
            Image.fromarray(s.clip(0,255).astype(np.uint8),'RGBA').save(sp,optimize=True)
            if size==512: p512[n]=sp; m512[n]=s[...,3]>128*0.85; m512[n+'_col']=col[...,3]>128
        # match check: shadow vs own colour alpha at 512 (holes only differ)
    t={}
    for a_,b_ in itertools.combinations(NAMES,2):
        t[f'{a_}-{b_}']={'iou_512':round(iou(m512[a_],m512[b_]),3),'iou_200':round(iou(mask200(p512[a_]),mask200(p512[b_])),3)}
    for k,v in t.items(): print(f'{k:15} 512:{v["iou_512"]:.3f} 200:{v["iou_200"]:.3f}')
    print('max 512',max(v['iou_512'] for v in t.values()),'max 200',max(v['iou_200'] for v in t.values()))
    own={n:round(iou(m512[n],m512[n+'_col']),3) for n in NAMES}; print('shadow vs own colour alpha',own)
    # cross: each shadow vs each colour alpha (QA retest table): own must be the best match
    cross={s:{c:round(iou(m512[s],m512[c+'_col']),3) for c in NAMES} for s in NAMES}
    for s in NAMES: print('shadow',s,cross[s],'best:',max(cross[s],key=cross[s].get))
    json.dump({'pairs':t,'shadow_vs_own_colour':own,'shadow_vs_colour':cross},open(D+'/_work/pipeline/shadow_iou_v2.json','w'),indent=1)
