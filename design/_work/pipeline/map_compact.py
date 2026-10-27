"""Compact phone map (640x360 dp frame, 16:9) for screens <= 360 dp tall (568x320, 640x360).
Same vocabulary as map.py, re-laid out: places at nominal 120 dp, lighthouse pulled inland,
shadow and puzzle islets out at sea, HUD zone top-right kept clear.
v1.1: puzzle islet (550,276) + shadow islet (466,186) pulled in: puzzle art >= 24 dp from right/bottom edges."""
import math, random, json, io, cairosvg
from map import cr, blobpts, tree, palm, rock, flower, ripple, cloud, pad, stepping, land, P, LAG, FOAM, SAND, SUN, CREAM
W,H=640,360
BOX=120; K=BOX/140; PDY=round(40*K)   # pad offset scales with the place box
SPOTS={'cave':(92,104),'forest':(226,124),'lighthouse':(360,104),'beach':(96,268),
       'library':(240,280),'shadow':(466,186),'islets':(550,276)}
GUIDE=(374,290)
HUD=(468,0,640,112)   # sound 72 dp + gear 44 dp, 24 dp margins (+ button edge)
MAIN=[(40,120),(52,62),(110,34),(180,40),(214,58),(262,40),(330,36),(392,44),(420,84),(412,140),(394,176),(396,224),(426,292),(400,336),(320,346),(250,344),(196,350),(170,330),(140,348),(70,340),(32,300),(22,220),(30,170)]
MEADOW=[(160,74),(226,66),(290,78),(306,124),(292,176),(240,196),(184,188),(152,150)]
ISLET_S=blobpts(474,224,68,40,12,0.06,3)
SMALL=[(600,140,22,10,31),(28,24,0,0,0)]

def padk(x,y,kind):
    return f'<g transform="translate({x} {y+PDY}) scale({K:.3f}) translate({-x} {-(y+40)})">{pad(x,y,kind)}</g>'

def build():
    defs=(f'<defs><linearGradient id="sea" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6ED6C6"/><stop offset=".45" stop-color="{LAG}"/><stop offset="1" stop-color="#33AC9E"/></linearGradient>'
          f'<radialGradient id="sunglow" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(24 16) scale(340 300)"><stop offset="0" stop-color="{SUN}" stop-opacity=".55"/><stop offset=".35" stop-color="#FFF3B0" stop-opacity=".22"/><stop offset="1" stop-color="#FFF3B0" stop-opacity="0"/></radialGradient>'
          f'<linearGradient id="hiTL" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".55"/><stop offset=".5" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="{P}" stop-opacity=".10"/></linearGradient>'
          f'<radialGradient id="vig" cx=".35" cy=".3" r=".95"><stop offset=".6" stop-color="{P}" stop-opacity="0"/><stop offset="1" stop-color="{P}" stop-opacity=".16"/></radialGradient>'
          f'<clipPath id="cloudclip"><rect x="-60" y="-40" width="120" height="80"/></clipPath></defs>')
    s=f'<rect width="{W}" height="{H}" fill="url(#sea)"/>'
    rnd=random.Random(5)
    for i in range(60):
        x=rnd.uniform(0,W); y=rnd.uniform(0,H)
        ok=all(math.hypot(x-sx,(y-sy-18)*1.6)>82 for sx,sy in SPOTS.values()) and not (15<x<440 and 25<y<355)
        if ok: s+=ripple(x,y,rnd.uniform(12,22),rnd.uniform(.45,.8))
    s+=land(MAIN,SAND,'#F3C994','#FFFFFF',rid='main')
    s+=land(ISLET_S,SAND,'#F3C994','#FFFFFF',rid='isS')
    s+=land(blobpts(608,150,22,10,9,.08,31),SAND,'#F3C994','#FFFFFF',outline=2.4,rid='sm1')+rock(608,148,.6)
    md=cr(MEADOW)
    s+=(f'<clipPath id="clmd"><path d="{md}"/></clipPath><g clip-path="url(#clmd)"><path d="{md}" fill="#A9D46A"/>'
        f'<path d="{md}" fill="#CFE8A8" transform="translate(-4,-6)"/></g><path d="{md}" fill="none" stroke="{P}" stroke-width="2.4" stroke-opacity=".7" stroke-linejoin="round"/>')
    for x,y,sc in [(40,128,1.1),(52,116,.8),(146,134,1.0),(152,120,.7),(312,124,1.0),(318,110,.7),(410,130,.9),(404,116,.7)]: s+=rock(x,y,sc)
    rnd2=random.Random(11)
    for i in range(110):
        x=rnd2.uniform(40,420); y=rnd2.uniform(50,340)
        s+=f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rnd2.uniform(.8,1.5):.1f}" fill="#E9B97E" opacity=".55"/>'
    for i in range(20):
        x=rnd2.uniform(168,296); y=rnd2.uniform(84,186)
        s+=f'<path d="M{x-3:.1f},{y:.1f} q1,-4 2,-5 M{x:.1f},{y:.1f} q0,-5 0,-6 M{x+3:.1f},{y:.1f} q-1,-4 -2,-5" stroke="#86BE34" stroke-width="1.3" fill="none" stroke-linecap="round"/>'
    pc={k:(x,y+PDY) for k,(x,y) in SPOTS.items()}; gp=(GUIDE[0],GUIDE[1]+PDY)
    s+=stepping(pc['beach'],pc['library'],3,bend=-1.2)+stepping(pc['library'],gp,2)
    s+=stepping(pc['cave'],pc['forest'],2,bend=1)+stepping(pc['forest'],pc['lighthouse'],2,bend=1)
    s+=stepping(pc['beach'],pc['cave'],2,bend=1.2)
    s+=stepping((402,232),(416,246),2,r=3.4,col='#C9C2D9')+stepping((432,304),(492,312),3,r=3.4,col='#C9C2D9')
    kinds={'cave':'rock','forest':'grass','lighthouse':'rock','beach':'sand','library':'sand','shadow':'sand','islets':'water'}
    for k,(x,y) in SPOTS.items(): s+=padk(x,y,kinds[k])
    s+=padk(GUIDE[0],GUIDE[1]-6,'sand')
    for x,y,sc in [(160,206,.7),(306,206,.75),(330,226,.6),(186,62,.6),(300,60,.6),(400,250,.6)]: s+=tree(x,y,sc)
    for x,y,sc,f in [(30,206,.8,False),(170,316,.7,True),(424,320,.7,False),(530,206,.62,True)]: s+=palm(x,y,sc,f)
    for x,y,sc in [(60,330,.7),(620,345,.8),(612,232,.6),(630,250,.7)]: s+=rock(x,y,sc)
    for x,y,c in [(200,90,'#FFD60A'),(286,96,'#A75BAD'),(170,170,'#FC647D')]: s+=flower(x,y,c)
    s+=cloud(300,16,.7)
    s+=f'<rect width="{W}" height="{H}" fill="url(#sunglow)"/>'
    s+=(f'<g><circle cx="14" cy="10" r="42" fill="{SUN}" opacity=".25"/><circle cx="8" cy="4" r="30" fill="{SUN}" stroke="{P}" stroke-width="3"/>'
        f'<circle cx="0" cy="-4" r="19" fill="#FFE866"/>'+''.join(f'<path d="M{8+40*math.cos(math.radians(a)):.1f},{4+40*math.sin(math.radians(a)):.1f} L{8+52*math.cos(math.radians(a)):.1f},{4+52*math.sin(math.radians(a)):.1f}" stroke="{SUN}" stroke-width="5" stroke-linecap="round" opacity=".85"/>' for a in [20,45,70])+'</g>')
    s+=f'<rect width="{W}" height="{H}" fill="url(#vig)"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{defs}{s}</svg>'

if __name__=='__main__':
    from PIL import Image
    OUT='/workspace/seamonsters/design/assets/map'
    svg=build(); open('/workspace/seamonsters/design/_work/pipeline/map_island_compact.svg','w').write(svg)
    for k,pre in [(1,''),(2,'2.0x/'),(3,'3.0x/')]:
        png=cairosvg.svg2png(bytestring=svg.encode(),output_width=W*k,output_height=H*k)
        Image.open(io.BytesIO(png)).convert('RGB').save(f'{OUT}/{pre}map_island_morning_compact.png',optimize=True)
    json.dump({'frame_dp':[W,H],'spots':SPOTS,'guide':GUIDE,'hud':HUD,'box':BOX,'pad_dy':PDY},open('/workspace/seamonsters/design/_work/pipeline/map_layout_compact.json','w'))
    ks=list(SPOTS)
    print('min dist',min((round(math.dist(SPOTS[a],SPOTS[b]),1),a,b) for i,a in enumerate(ks) for b in ks[i+1:]))
    for scr in [(568,320),(640,360)]:
        s=max(scr[0]/W,scr[1]/H); place=max(100,min(200,BOX*s)); tap=max(96,place*130/140)
        md=min(math.dist(SPOTS[a],SPOTS[b]) for i,a in enumerate(ks) for b in ks[i+1:])*s
        dx=(scr[0]-W*s)/2; dy=(scr[1]-H*s)/2
        inside=all(0<=dx+(x)*s-place/2 and dx+x*s+place/2<=scr[0] and 0<=dy+y*s-place/2 and dy+y*s+place/2<=scr[1] for x,y in SPOTS.values())
        hud_ok=all(not (dx+(x)*s+tap/2>dx+HUD[0]*s and dy+y*s-tap/2<dy+HUD[3]*s) for x,y in SPOTS.values())
        print(scr,'s=%.4f place=%.1f tap=%.1f min centre dist=%.1f taps overlap=%s inside=%s hud_clear=%s'%(s,place,tap,md,md<tap,inside,hud_ok))
