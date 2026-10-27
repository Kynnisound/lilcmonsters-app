from PIL import Image, ImageDraw, ImageFont
import os
A='/workspace/seamonsters/design/assets'
F='/workspace/seamonsters/design/_work/'
ft=ImageFont.truetype(F+'LuckiestGuy.ttf',44); fb=ImageFont.truetype(F+'Baloo2-700.ttf',22); fs=ImageFont.truetype(F+'Baloo2-600.ttf',18)
PL=(58,23,82); CR=(255,246,229)
places=['beach','cave','forest','library','lighthouse','islets','shadow']
icons=['beach_shell','cave_palette','forest_magnifier','library_book','lighthouse_play','islets_puzzle','shadow_lantern','sound_on','sound_off','parental_gate','back','home','padlock','padlock_badge']
W=2400; c=Image.new('RGBA',(W,3400),CR); d=ImageDraw.Draw(c)
d.text((60,40),'LIL C MONSTERS · ASSETS v1.2 (WORKING DRAFT)',font=ft,fill=PL)
d.text((60,100),'design/assets · places 200 dp export, shown at 140 dp × map scale (120 to 200 dp) · icons 44 to 96 dp · map 812×375 dp · 27 Oct 2026 · not final art',font=fb,fill=(90,63,107))
y=150
d.text((60,y),'1 · MAP DECOR (morning lagoon, empty spots) + phone-safe 16:9 crop (dashed)',font=fb,fill=PL); y+=36
m=Image.open(A+'/map/2.0x/map_island_morning.png').convert('RGBA'); mw=1500; m=m.resize((mw,int(m.height*mw/m.width)),Image.LANCZOS)
c.alpha_composite(m,(60,y)); x0=60+int(mw*(812-667)/2/812); x1=60+mw-int(mw*(812-667)/2/812)
for yy in range(y,y+m.height,18): d.line((x0,yy,x0,yy+9),fill=PL,width=3); d.line((x1,yy,x1,yy+9),fill=PL,width=3)
mk=Image.open('/workspace/seamonsters/design/map_sketch_v1.png').convert('RGBA'); mk=mk.resize((760,int(mk.height*760/mk.width)),Image.LANCZOS)
c.alpha_composite(mk.resize((780, int(mk.height*780/760))) if False else mk,(1600,y)); d.text((1600,y+mk.height+6),'mockup: design/map_sketch_v1.png',font=fs,fill=PL)
y+=m.height+20
d.text((60,y),'1b · TABLET 4:3 MAP (1024×768 dp) + mockup · places 140 dp × map scale (120 to 200 dp), HUD fixed dp, no pictograms on places',font=fb,fill=PL); y+=36
tm=Image.open(A+'/map/2.0x/map_island_morning_tablet43.png').convert('RGBA'); tm=tm.resize((900,675),Image.LANCZOS); c.alpha_composite(tm,(60,y))
tk=Image.open('/workspace/seamonsters/design/map_sketch_tablet43_v1.png').convert('RGBA').resize((900,675),Image.LANCZOS); c.alpha_composite(tk,(1000,y))
d.text((60,y+680),'design/assets/map/map_island_morning_tablet43.png',font=fs,fill=PL); d.text((1000,y+680),'mockup: design/map_sketch_tablet43_v1.png',font=fs,fill=PL)
y+=675+50
d.text((60,y),'2 · PLACES · unlocked (top) / locked (mist + plum padlock) · on lagoon, at 140 dp @2x',font=fb,fill=PL); y+=36
T=320
for row,st in enumerate(['unlocked','locked']):
    for i,p in enumerate(places):
        x=60+i*(T+12); t=Image.new('RGBA',(T,T),(63,193,176,255)); im=Image.open(f'{A}/places/2.0x/place_{p}_{st}.png'); t.alpha_composite(im,((T-280)//2,(T-280)//2))
        c.alpha_composite(t,(x,y))
        if row==0: d.text((x+8,y+T-30),p,font=fs,fill=PL)
    y+=T+12
y+=10
d.text((60,y),'legibility check · 120 dp @1x on foam and sand (real pixel size)',font=fb,fill=PL); y+=34
for i,p in enumerate(places):
    for j,st in enumerate(['unlocked','locked']):
        x=60+i*300+j*140; bg=(212,244,238,255) if j==0 else (255,228,191,255)
        t=Image.new('RGBA',(130,130),bg); im=Image.open(f'{A}/places/place_{p}_{st}.png').resize((120,120),Image.LANCZOS); t.alpha_composite(im,(5,5)); c.alpha_composite(t,(x,y))
y+=160
d.text((60,y),'3 · ICONS (drawn objects) · on lagoon, coral, cream tiles · then at 40 dp @1x',font=fb,fill=PL); y+=36
S=150
bgs=[(63,193,176,255),(255,122,92,255),(255,246,229,255)]
for i,n in enumerate(icons):
    col=i%7; row=i//7
    for k,bg in enumerate(bgs):
        x=60+col*330+k*104; yy=y+row*(S+70)
        t=Image.new('RGBA',(100,100),bg); im=Image.open(f'{A}/icons/3.0x/icon_{n}.png').convert('RGBA').resize((88,88),Image.LANCZOS); t.alpha_composite(im,(6,6)); c.alpha_composite(t,(x,yy))
    d.text((60+col*330,y+row*(S+70)+104),n,font=fs,fill=PL)
y+=2*(S+70)+10
for i,n in enumerate(icons):
    x=60+i*60; t=Image.new('RGBA',(52,52),bgs[i%2]); im=Image.open(f'{A}/icons/3.0x/icon_{n}.png').convert('RGBA').resize((40,40),Image.LANCZOS); t.alpha_composite(im,(6,6)); c.alpha_composite(t,(x,y))
y+=80
c=c.crop((0,0,W,y)); c.convert('RGB').save(A+'/_contact.png',optimize=True); print(c.size)
