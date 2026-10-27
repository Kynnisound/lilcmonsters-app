"""Map mockups: decor + 7 places (mixed states) + Fuzzle guide + fixed-size HUD. No module pictograms on places
(the drawn place + spoken label is the identifier). Places = 140 dp x map scale, clamped 120..200 dp; HUD never scales."""
import json, io, cairosvg, sys
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0,'/workspace/seamonsters/design/_work/pipeline')
from icons import svg_icon
A='/workspace/seamonsters/design/assets'; PL='/workspace/seamonsters/design/_work/pipeline/'
LOCKED={'shadow','islets'}; NEW={'library'}
def run(out, layout, mapfile, K=2, map_scale=1.0, base=140, lo=120, screen=None):
    L=json.load(open(PL+layout)); FW,FH=L['frame_dp']
    if screen is None: screen=(FW,FH)
    W,H=screen; sc=max(W/FW,H/FH); ox=(W-FW*sc)/2; oy=(H-FH*sc)/2
    full=Image.open(f'{A}/map/3.0x/{mapfile}').convert('RGBA').resize((round(FW*sc*K),round(FH*sc*K)),Image.LANCZOS)
    m=Image.new('RGBA',(W*K,H*K)); m.alpha_composite(full,(round(ox*K),round(oy*K))) if ox>=0 and oy>=0 else m.paste(full,(round(ox*K),round(oy*K)))
    place=max(lo,min(200,base*sc))
    L['spots']={k:(ox+x*sc,oy+y*sc) for k,(x,y) in L['spots'].items()}; L['guide']=(ox+L['guide'][0]*sc,oy+L['guide'][1]*sc)
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
    gx,gy=L['guide']; sh=Image.new('RGBA',m.size,(0,0,0,0)); f2=place/140; ImageDraw.Draw(sh).ellipse(((gx-34*f2)*K,(gy+40*f2)*K,(gx+34*f2)*K,(gy+52*f2)*K),fill=(58,23,82,60))
    m.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3*K)))
    m.alpha_composite(f,(int(gx*K-f.width/2),int((gy+50*f2)*K-h)))
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
    run('/workspace/seamonsters/design/map_sketch_compact_568x320_v1.png','map_layout_compact.json','map_island_morning_compact.png',K=3,base=120,lo=100,screen=(568,320))
