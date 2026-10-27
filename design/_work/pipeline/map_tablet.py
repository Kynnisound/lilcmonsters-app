"""Tablet 4:3 island map (1024x768 dp). Same island and decor vocabulary as map.py, redrawn (not stretched):
positions are remapped (x*1.06, y*1.22 around the island centre) while every object keeps its size,
then the frame is extended at top (sky haze, clouds) and bottom (lagoon, foam, small islets)."""
import math, random, json, os, io, cairosvg
import map as M
from map import cr, blobpts, tree, palm, rock, flower, ripple, cloud, pad, stepping, land, P, LAG, FOAM, SAND, SUN, CREAM, PAD_DY
W,H=1024,768
SX,SY=1.06,1.22
def X(x): return (x-406)*SX+512
def Y(y): return (y-200)*SY+410
def T(p): return (round(X(p[0]),1), round(Y(p[1]),1))
def TP(pts): return [T(p) for p in pts]
SPOTS={k:T(v) for k,v in M.SPOTS.items()}
GUIDE=T(M.GUIDE)
HUD=(844,0,1024,112)   # top-right HUD-safe zone (sound 72 dp + parent gate 44 dp + margins)
SMALL_ISLETS=[(118,694,42,20,21),(934,700,48,22,22),(596,722,30,14,23),(908,214,34,16,24),(150,176,26,12,25)]

def build():
    defs=(f'<defs><linearGradient id="sea" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6ED6C6"/><stop offset=".45" stop-color="{LAG}"/><stop offset="1" stop-color="#33AC9E"/></linearGradient>'
          f'<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E3F2FF"/><stop offset=".55" stop-color="{FOAM}" stop-opacity=".85"/><stop offset="1" stop-color="{FOAM}" stop-opacity="0"/></linearGradient>'
          f'<radialGradient id="sunglow" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(30 20) scale(560 460)"><stop offset="0" stop-color="{SUN}" stop-opacity=".55"/><stop offset=".35" stop-color="#FFF3B0" stop-opacity=".22"/><stop offset="1" stop-color="#FFF3B0" stop-opacity="0"/></radialGradient>'
          f'<linearGradient id="hiTL" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".55"/><stop offset=".5" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="{P}" stop-opacity=".10"/></linearGradient>'
          f'<radialGradient id="vig" cx=".35" cy=".3" r=".95"><stop offset=".6" stop-color="{P}" stop-opacity="0"/><stop offset="1" stop-color="{P}" stop-opacity=".16"/></radialGradient>'
          f'<clipPath id="cloudclip"><rect x="-60" y="-40" width="120" height="80"/></clipPath></defs>')
    s=f'<rect width="{W}" height="{H}" fill="url(#sea)"/>'
    # sky haze over the far lagoon at the top
    s+=f'<rect width="{W}" height="170" fill="url(#sky)"/>'
    for yy,op in [(118,.55),(138,.35)]:
        s+=f'<path d="M0,{yy} ' + ' '.join(f'q16,-5 32,0 t32,0' for _ in range(1)) + '" fill="none"/>'
    s+=''.join(f'<path d="M{x},{132+6*math.sin(x/37):.1f} q14,-4 28,0" stroke="{CREAM}" stroke-width="2.2" fill="none" stroke-linecap="round" opacity=".7"/>' for x in range(40,1000,70))
    # ripples
    bx0,by0,bx1,by1=X(55),Y(28),X(578),Y(372)
    rnd=random.Random(7)
    for i in range(130):
        x=rnd.uniform(0,W); y=rnd.uniform(150,H)
        ok=all(math.hypot(x-sx,(y-sy-20)*1.6)>95 for sx,sy in SPOTS.values()) and not (bx0<x<bx1 and by0<y<by1) \
           and all(math.hypot((x-a)/(b+30),(y-c)/(d+24))>1 for a,c,b,d,_ in SMALL_ISLETS)
        if ok: s+=ripple(x,y,rnd.uniform(14,26),rnd.uniform(.45,.8))
    # small decorative islets (no tap, no place)
    for (cx,cy,rx,ry,seed) in SMALL_ISLETS:
        s+=land(blobpts(cx,cy,rx,ry,10,0.08,seed),SAND,'#F3C994','#FFFFFF',outline=2.6,rid=f'si{seed}')
    s+=palm(122,690,.7)+rock(104,700,.7)+palm(940,696,.75,True)+rock(920,704,.8)+rock(598,722,.6)+rock(908,214,.6)+flower(150,175,'#FC647D')
    # main island + shadow islet (remapped geometry, same shapes)
    s+=land(TP(M.MAIN),SAND,'#F3C994','#FFFFFF',rid='main')
    s+=land(TP(M.ISLET_A),SAND,'#F3C994','#FFFFFF',rid='isA')
    md=cr(TP(M.MEADOW))
    s+=(f'<clipPath id="clmd"><path d="{md}"/></clipPath><g clip-path="url(#clmd)"><path d="{md}" fill="#A9D46A"/>'
        f'<path d="{md}" fill="#CFE8A8" transform="translate(-4,-6)"/></g><path d="{md}" fill="none" stroke="{P}" stroke-width="2.4" stroke-opacity=".7" stroke-linejoin="round"/>')
    for x,y,sc in [(108,146,1.3),(124,132,1.0),(214,150,1.2),(226,138,.9),(198,96,.8),(436,124,1.1),(446,110,.8),(540,126,1.2),(530,112,.9),(552,148,.8)]:
        # boulders stay glued to their pad: move with the pad, keep their offset unscaled
        k=min(M.SPOTS,key=lambda n:math.hypot(M.SPOTS[n][0]-x,M.SPOTS[n][1]+PAD_DY-y))
        px,py=M.SPOTS[k]; qx,qy=SPOTS[k]
        s+=rock(qx+(x-px),qy+(y-py),sc)
    rnd2=random.Random(11)
    for i in range(220):
        x=rnd2.uniform(70,560); y=rnd2.uniform(50,350)
        s+=f'<circle cx="{X(x):.1f}" cy="{Y(y):.1f}" r="{rnd2.uniform(.8,1.6):.1f}" fill="#E9B97E" opacity=".55"/>'
    for i in range(36):
        x,y=T((rnd2.uniform(225,415),rnd2.uniform(108,245)))
        s+=f'<path d="M{x-3:.1f},{y:.1f} q1,-4 2,-5 M{x:.1f},{y:.1f} q0,-5 0,-6 M{x+3:.1f},{y:.1f} q-1,-4 -2,-5" stroke="#86BE34" stroke-width="1.3" fill="none" stroke-linecap="round"/>'
    pc={k:(x,y+PAD_DY) for k,(x,y) in SPOTS.items()}; gp=(GUIDE[0],GUIDE[1]+PAD_DY)
    s+=stepping(pc['beach'],pc['library'],5,bend=-1.5)+stepping(pc['library'],gp,3)
    s+=stepping(pc['cave'],pc['forest'],3,bend=1)+stepping(pc['forest'],pc['library'],3,col='#F4E7C4')
    s+=stepping(gp,pc['lighthouse'],5,bend=-1)
    s+=stepping(T((540,170)),T((565,215)),3,r=3.6,col='#C9C2D9')
    s+=stepping(T((548,300)),T((598,330)),3,r=3.6,col='#C9C2D9')
    s+=stepping(pc['beach'],pc['cave'],4,bend=1.2)
    kinds={'cave':'rock','forest':'grass','lighthouse':'rock','beach':'sand','library':'sand','shadow':'sand','islets':'water'}
    for k,(x,y) in SPOTS.items(): s+=pad(x,y,kinds[k])
    s+=pad(GUIDE[0],GUIDE[1]-6,'sand')
    for x,y,sc in [(250,86,.8),(410,236,.85),(432,252,.7),(250,240,.75),(538,256,.75),(404,64,.7),(214,212,.7),(262,104,.6),(150,200,.7)]: s+=tree(*T((x,y)),sc)
    for x,y,sc,f in [(84,214,.9,False),(232,330,.8,True),(556,318,.8,False),(676,206,.75,True)]: s+=palm(*T((x,y)),sc,f)
    for x,y,sc in [(100,330,.8),(530,330,.9),(560,206,.7),(700,360,.9),(740,252,.8),(588,232,.7)]: s+=rock(*T((x,y)),sc)
    for x,y,c in [(370,250,'#FC647D'),(272,110,'#FFD60A'),(398,120,'#A75BAD'),(240,180,'#FC647D'),(425,180,'#FFD60A')]: s+=flower(*T((x,y)),c)
    s+=cloud(420,44,.9)+cloud(660,78,.65)+cloud(250,96,.55)+cloud(840,720,.7)+cloud(60,460,.6)
    s+=f'<rect width="{W}" height="{H}" fill="url(#sunglow)"/>'
    s+=(f'<g><circle cx="22" cy="18" r="60" fill="{SUN}" opacity=".25"/><circle cx="16" cy="12" r="44" fill="{SUN}" stroke="{P}" stroke-width="3.2"/>'
        f'<circle cx="5" cy="1" r="28" fill="#FFE866"/>'+''.join(f'<path d="M{16+57*math.cos(math.radians(a)):.1f},{12+57*math.sin(math.radians(a)):.1f} L{16+73*math.cos(math.radians(a)):.1f},{12+73*math.sin(math.radians(a)):.1f}" stroke="{SUN}" stroke-width="6" stroke-linecap="round" opacity=".85"/>' for a in [15,40,65,90])+'</g>')
    s+=f'<rect width="{W}" height="{H}" fill="url(#vig)"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{defs}{s}</svg>'

if __name__=='__main__':
    from PIL import Image
    OUT='/workspace/seamonsters/design/assets/map'
    svg=build(); open('/workspace/seamonsters/design/_work/pipeline/map_island_tablet43.svg','w').write(svg)
    for k,pre in [(1,''),(2,'2.0x/'),(3,'3.0x/')]:
        png=cairosvg.svg2png(bytestring=svg.encode(),output_width=W*k,output_height=H*k)
        Image.open(io.BytesIO(png)).convert('RGB').save(f'{OUT}/{pre}map_island_morning_tablet43.png',optimize=True)
    json.dump({'frame_dp':[W,H],'spots':SPOTS,'guide':GUIDE,'hud':HUD},open('/workspace/seamonsters/design/_work/pipeline/map_layout_tablet43.json','w'))
    ks=list(SPOTS); d=min((math.dist(SPOTS[a],SPOTS[b]),a,b) for i,a in enumerate(ks) for b in ks[i+1:])
    print('min dist',d); print(SPOTS, GUIDE)
    for k,(x,y) in SPOTS.items():
        inhud = x+70>HUD[0] and y-70<HUD[3]
        print(k,'box',(x-70,y-70,x+70,y+70),'HUD overlap' if inhud else '')
