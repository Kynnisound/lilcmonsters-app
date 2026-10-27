"""Map mockups: decor + 7 places (mixed states) + Fuzzle guide + fixed-size HUD. No module pictograms on places
(the drawn place + spoken label is the identifier). Places = 140 dp x map scale, clamped 120..200 dp; HUD never scales."""
import json, io, cairosvg, sys
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0,'/workspace/seamonsters/design/_work/pipeline')
from icons import svg_icon
A='/workspace/seamonsters/design/assets'; PL='/workspace/seamonsters/design/_work/pipeline/'
LOCKED={'shadow','islets'}; NEW={'library'}
def run(out, layout, mapfile, K=2, map_scale=1.0):
    L=json.load(open(PL+layout)); W,H=L['frame_dp']
    m=Image.open(f'{A}/map/3.0x/{mapfile}').convert('RGBA').resize((W*K,H*K),Image.LANCZOS)
    place=max(120,min(200,140*map_scale))
    def icon(n,dp):
        px=int(dp*K); return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg_icon(n).encode(),output_width=px,output_height=px))).convert('RGBA')
    for k,(x,y) in L['spots'].items():
        st='locked' if k in LOCKED else 'unlocked'
        im=Image.open(f'{A}/places/3.0x/place_{k}_{st}.png').resize((int(place*K),)*2,Image.LANCZOS)
        if k in NEW:  # "new" sun ring, drawn by the app
            ring=Image.new('RGBA',m.size,(0,0,0,0)); d=ImageDraw.Draw(ring); r=place*0.49*K
            d.ellipse((x*K-r,y*K-r,x*K+r,y*K+r),outline=(255,214,10,230),width=4*K)
            m.alpha_composite(ring)
        m.alpha_composite(im,(int((x-place/2)*K),int((y-place/2)*K)))
    f=Image.open('/workspace/lilcmonsters/ref/fuzzle_c.png').convert('RGBA')
    h=int(92*place/140*K); f=f.resize((int(f.width*h/f.height),h),Image.LANCZOS)
    gx,gy=L['guide']; sh=Image.new('RGBA',m.size,(0,0,0,0)); ImageDraw.Draw(sh).ellipse(((gx-34)*K,(gy+40)*K,(gx+34)*K,(gy+52)*K),fill=(58,23,82,60))
    m.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3*K)))
    m.alpha_composite(f,(int(gx*K-f.width/2),int((gy+50)*K-h)))
    # HUD, fixed dp (does not scale with the map): sound 72 dp button, parent gear 44 dp
    def button(cx,cy,dp,fill,edge):
        b=Image.new('RGBA',m.size,(0,0,0,0)); d=ImageDraw.Draw(b); r=dp/2*K
        d.ellipse((cx*K-r,cy*K-r+6*K,cx*K+r,cy*K+r+6*K),fill=edge,outline=(58,23,82),width=2*K)
        d.ellipse((cx*K-r,cy*K-r,cx*K+r,cy*K+r),fill=fill,outline=(58,23,82),width=2*K)
        m.alpha_composite(b)
    sx=W-24-44-24-36
    button(sx,24+36,72,(212,244,238),(11,110,106))
    m.alpha_composite(icon('sound_on',50),(int((sx-25)*K),int((60-25)*K)))
    m.alpha_composite(icon('parental_gate',44),(int((W-24-44)*K),int(24*K)))
    m.convert('RGB').save(out,optimize=True); return m
if __name__=='__main__':
    run('/workspace/seamonsters/design/map_sketch_v1.png','map_layout.json','map_island_morning.png')
    run('/workspace/seamonsters/design/map_sketch_tablet43_v1.png','map_layout_tablet43.json','map_island_morning_tablet43.png')
