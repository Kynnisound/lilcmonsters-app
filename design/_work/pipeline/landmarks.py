"""Cut out generated landmark stickers, normalise outline colour to plum,
build locked variants, export @1x/@2x/@3x. Source: _work/assets_gen/*.jpg"""
import numpy as np, cv2, json, sys, os
from PIL import Image, ImageFilter
import cairosvg, io
sys.path.insert(0, os.path.dirname(__file__))
from icons import svg_icon  # padlock badge shared with the icon set

G='/workspace/seamonsters/design/_work/assets_gen'
OUT='/workspace/seamonsters/design/assets/landmarks'
PLUM=np.array([58,23,82],float); BORDER=np.array([108,52,115],float)
MIST=np.array([0xB9,0xB3,0xC7],float)
DP=140  # landmark box in dp (hit area 120-140 dp centred in it)
SRC={'beach':'lm_beach_b','cave':'lm_cave_a','forest':'lm_forest_a','library':'lm_library_a',
     'lighthouse':'lm_lighthouse_a','islets':'lm_islets_a','shadow':'lm_shadow_b'}
SRC.update(json.loads(os.environ.get('LM_OVERRIDE','{}')))

def cutout(path):
    im=np.array(Image.open(path).convert('RGB')).astype(float)
    h,w,_=im.shape
    d=np.sqrt(((im-255)**2).sum(2))
    nearwhite=(d<38).astype(np.uint8)
    # background = near-white connected to the border
    n,lab=cv2.connectedComponents(nearwhite,connectivity=4)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bg=np.isin(lab,list(border))
    fg=(~bg).astype(np.uint8)
    # keep the largest blob (+ anything big touching it), fill holes
    n,lab,st,_=cv2.connectedComponentsWithStats(fg,connectivity=8)
    keep=np.zeros_like(fg)
    big=np.argmax(st[1:,cv2.CC_STAT_AREA])+1
    for i in range(1,n):
        if i==big or st[i,cv2.CC_STAT_AREA]>0.02*st[big,cv2.CC_STAT_AREA]: keep[lab==i]=1
    cnts,_=cv2.findContours(keep,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
    solid=np.zeros_like(keep); cv2.drawContours(solid,cnts,-1,1,-1)
    # eat 2px into the border to drop the white fringe, then smooth the edge
    solid=cv2.erode(solid,np.ones((3,3),np.uint8),iterations=2)
    a=cv2.GaussianBlur(solid.astype(np.float32),(0,0),1.6)
    a=np.clip((a-0.5)*2.2+0.5,0,1)
    # outline normalisation: mauve border family -> plum
    dist=np.sqrt(((im-BORDER)**2).sum(2))
    wgt=np.clip((70-dist)/30,0,1)
    im=im*(1-wgt[...,None])+np.clip(im-BORDER+PLUM,0,255)*wgt[...,None]
    # any pixel in the outer 14px band that is dark becomes plum too (uniform sticker rim)
    dt=cv2.distanceTransform(solid,cv2.DIST_L2,5)
    lum=im@[0.299,0.587,0.114]
    band=(dt<14*w/1024)&(lum<150)
    im[band]=PLUM
    # rim under the soft edge is plum, never white
    edge=(dt<4)
    im[edge]=PLUM
    rgba=np.dstack([im,a*255]).clip(0,255).astype(np.uint8)
    return Image.fromarray(rgba,'RGBA')

def fit_square(img,margin=0.04):
    bb=img.getbbox(); img=img.crop(bb)
    s=int(max(img.size)*(1+2*margin))
    c=Image.new('RGBA',(s,s),(0,0,0,0))
    # sit the art on the bottom of the box (base = ground contact), centred horizontally
    c.paste(img,((s-img.width)//2,s-img.height-int(s*margin)),img)
    return c

def locked(img):
    a=np.array(img).astype(float); rgb=a[...,:3]; al=a[...,3]
    lum=rgb@[0.299,0.587,0.114]
    plumness=np.clip((95-np.sqrt(((rgb-PLUM)**2).sum(2)))/40,0,1)
    # map luminance onto a mist ramp (dark mist -> light mist), keep value structure
    t=(lum/255.0)[...,None]
    lo=np.array([0x8F,0x88,0xA3],float); hi=np.array([0xE4,0xE0,0xEC],float)
    ramp=lo*(1-t)+hi*t
    out=ramp*0.88+rgb*0.12
    out=out*(1-plumness[...,None])+np.array([0x5A,0x3F,0x6B])*plumness[...,None]  # outline stays plum-ish (inkSoft)
    return Image.fromarray(np.dstack([out,al]).clip(0,255).astype(np.uint8),'RGBA')

def badge(img,size):
    # plum padlock badge, top-right, 40% of the box: readable at 120 dp (=48 dp badge)
    bs=int(size*0.40)
    png=cairosvg.svg2png(bytestring=svg_icon('padlock_badge').encode(),output_width=bs,output_height=bs)
    b=Image.open(io.BytesIO(png)).convert('RGBA')
    img=img.copy(); img.alpha_composite(b,(size-bs,0)); return img

def export(img,name,state):
    os.makedirs(OUT,exist_ok=True); files=[]
    for k,suf in [(3,'@3x'),(2,'@2x'),(1,'')]:
        px=DP*k
        im=img.resize((px,px),Image.LANCZOS)
        if state=='locked': im=badge(im,px)
        fn=f'{OUT}/{"" if k==1 else f"{k}.0x/"}place_{name}_{state}.png'
        os.makedirs(os.path.dirname(fn),exist_ok=True)
        im.save(fn,optimize=True); files.append(fn)
    return files

if __name__=='__main__':
    os.makedirs(G+'/cut',exist_ok=True)
    for name,src in SRC.items():
        c=fit_square(cutout(f'{G}/{src}.jpg'))
        c.save(f'{G}/cut/{name}.png')
        export(c,name,'unlocked'); export(locked(c),name,'locked')
        print(name,c.size)
