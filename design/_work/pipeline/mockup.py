import json, io, cairosvg, sys
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0,'/workspace/seamonsters/design/_work/pipeline')
from icons import svg_icon
A='/workspace/seamonsters/design/assets'
L=json.load(open('/workspace/seamonsters/design/_work/pipeline/map_layout.json'))
K=2  # render scale (px per dp)
LOCKED={'shadow','islets'}
NEW={'library'}
def icon(n,dp):
    px=int(dp*K); return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg_icon(n).encode(),output_width=px,output_height=px))).convert('RGBA')
def run(out, scale=K):
    m=Image.open(f'{A}/map/2.0x/map_island_morning.png').convert('RGBA')
    for k,(x,y) in L['spots'].items():
        st='locked' if k in LOCKED else 'unlocked'
        im=Image.open(f'{A}/places/2.0x/place_{k}_{st}.png')
        if k in NEW:  # sun ring "new" state drawn by the app, shown here for reference
            ring=Image.new('RGBA',m.size,(0,0,0,0)); d=ImageDraw.Draw(ring)
            r=68*K; d.ellipse((x*K-r,y*K-r,x*K+r,y*K+r),outline=(255,214,10,230),width=8*K//2)
            m.alpha_composite(ring)
        m.alpha_composite(im,(int((x-70)*K),int((y-70)*K)))
    # Fuzzle guide
    f=Image.open('/workspace/lilcmonsters/ref/fuzzle_c.png').convert('RGBA')
    h=int(92*K); f=f.resize((int(f.width*h/f.height),h),Image.LANCZOS)
    gx,gy=L['guide']; sh=Image.new('RGBA',m.size,(0,0,0,0)); ImageDraw.Draw(sh).ellipse(((gx-34)*K,(gy+40)*K,(gx+34)*K,(gy+52)*K),fill=(58,23,82,60))
    m.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3*K)))
    m.alpha_composite(f,(int(gx*K-f.width/2),int((gy+50)*K-h)))
    # top-right UI: sound (72 dp) + parental gate (44 dp)
    def button(cx,cy,dp,fill,edge):
        b=Image.new('RGBA',m.size,(0,0,0,0)); d=ImageDraw.Draw(b); r=dp/2*K
        d.ellipse((cx*K-r,cy*K-r+6*K,cx*K+r,cy*K+r+6*K),fill=edge,outline=(58,23,82),width=2*K)
        d.ellipse((cx*K-r,cy*K-r,cx*K+r,cy*K+r),fill=fill,outline=(58,23,82),width=2*K)
        m.alpha_composite(b)
    button(812-24-44-24-36,24+36,72,(212,244,238),(11,110,106))
    m.alpha_composite(icon('sound_on',50),(int((812-24-44-24-36-25)*K),int((60-25)*K)))
    m.alpha_composite(icon('parental_gate',44),(int((812-24-44)*K),int(24*K)))  # 44 dp, no button, no relief
    m.convert('RGB').save(out,optimize=True); return m
if __name__=='__main__':
    run('/workspace/seamonsters/design/map_sketch_v1.png')
