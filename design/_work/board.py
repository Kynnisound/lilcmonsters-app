from PIL import Image,ImageDraw,ImageFont,ImageFilter
S=2; W,H=2400,1350
def s(v): return int(round(v*S))
LG=lambda z: ImageFont.truetype('LuckiestGuy.ttf',s(z))
B=lambda z,w=700: ImageFont.truetype(f'Baloo2-{w}.ttf',s(z))
PLUM='#3a1752'; CREAM='#fff6e5'; SUN='#ffd60a'
img=Image.new('RGB',(s(W),s(H)),CREAM); d=ImageDraw.Draw(img)
def txt(x,y,t,f,fill=PLUM,anchor='la'): d.text((s(x),s(y)),t,font=f,fill=fill,anchor=anchor)
def rr(x,y,w,h,r,fill,outline=None,width=0): d.rounded_rectangle([s(x),s(y),s(x+w),s(y+h)],radius=s(r),fill=fill,outline=outline,width=s(width) if width else 0)
def lum(h):
    h=h.lstrip('#'); c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    c=[x/12.92 if x<=0.03928 else ((x+0.055)/1.055)**2.4 for x in c]; return .2126*c[0]+.7152*c[1]+.0722*c[2]
def cr(a,b):
    la,lb=sorted([lum(a),lum(b)],reverse=True); return (la+.05)/(lb+.05)
# header
title="LIL C MONSTERS  ·  DIRECTION V1"
txt(64+4,40+5,title,LG(64),fill=SUN); txt(64,40,title,LG(64))
txt(66,118,"SeaMonsters app (kids 3 to 7, Flutter + Firebase) · visual system draft v0 · research board, not final mockups · 27 Oct 2026",B(24,500))
d.line([s(60),s(166),s(W-60),s(166)],fill=PLUM,width=s(3))
# sections
def head(x,y,t): txt(x,y,t,LG(30))
# ---- palette
head(60,186,"1 · PALETTE  (turquoise + coral, on brand tokens)")
core=[('LAGOON','#3fc1b0','sea, primary surface'),('LAGOON DEEP','#0b6e6a','icons, text on light'),('FOAM','#d4f4ee','light background'),
('CORAL','#ff7a5c','main action / play'),('CORAL DEEP','#c8432a','button edge, pressed'),('SAND','#ffe4bf','beach, cards'),
('PLUM','#3a1752','ink, outlines'),('CREAM','#fff6e5','paper background'),('SUN','#ffd60a','reward, star, unlock'),
('NIGHT','#1b1747','bedtime, library'),('MIST','#b9b3c7','locked state'),('SKY','#e3f2ff','daylight sky')]
x0,y0=60,232; cw,ch=196,112
for i,(n,hx,role) in enumerate(core):
    x=x0+(i%4)*(cw+12); y=y0+(i//4)*(ch+12)
    rr(x,y,cw,ch,18,hx,outline=PLUM,width=3)
    tc=PLUM if cr(PLUM,hx)>=4.5 else '#ffffff'
    if cr('#ffffff',hx)>cr(PLUM,hx): tc='#ffffff'
    txt(x+14,y+10,n,B(19,800),fill=tc); txt(x+14,y+36,hx.upper(),B(19,600),fill=tc)
    txt(x+14,y+62,role,B(15,500),fill=tc)
    best=max(cr(PLUM,hx),cr('#ffffff',hx)); txt(x+cw-12,y+ch-10,f"{'plum' if tc==PLUM else 'white'} {best:.1f}:1",B(14,600),fill=tc,anchor='rd')
y=y0+3*(ch+12)+4
txt(60,y,"Character colours (fur only, never carry text alone):",B(18,700))
chars=[('Fuzzle','#fc9313'),('Pip','#1b98d0'),('Dottie','#86be34'),('Zib','#a75bad'),('Bitsy','#fc647d')]
for i,(n,hx) in enumerate(chars):
    x=60+i*158; rr(x,y+32,146,52,26,hx,outline=PLUM,width=3)
    txt(x+73,y+58,f"{n} {hx}",B(16,800),fill=PLUM if cr(PLUM,hx)>4.4 else '#fff',anchor='mm')
txt(60,y+96,"Rules: coral on lagoon = 1.2:1 luminance → always split them with a plum outline.",B(16,500))
txt(60,y+120,"Body/ink text = plum on light (13.7:1) or cream on night (15.5:1). Never white on lagoon/coral (2.2 to 2.6:1).",B(16,500))
# ---- moods
my=y+160
head(60,my,"2 · ONE MOOD PER PLACE  (colour + light)")
moods=[('ISLAND MAP','Fuzzle','morning lagoon','#bfeee6','#3fc1b0','#ffd9a0'),
('BEACH · SOUND','Pip','midday sparkle','#e3f2ff','#7fd8cc','#ffe4bf'),
('CAVE · COLOUR','Dottie','crystal + lantern','#3b2a5c','#6b4fa0','#ffc56b'),
('FOREST · HUNT','Zib','dappled sunbeams','#cfe8a8','#86be34','#2f6b3a'),
('LIBRARY · BOOKS','book narrator','bedtime lamp','#2a2470','#1b1747','#ffc56b'),
('LIGHTHOUSE · TV','whole crew','sunset glow','#ffc9a3','#ff7a5c','#ffd60a'),
('ISLETS PUZZLE','Fuzzle','shallow noon','#d4f4ee','#3fc1b0','#ffe4bf'),
('SHADOW GAME','Bitsy','dusk lantern','#ead9f5','#2a2470','#ffd60a')]
tw,th=196,118
for i,(n,g,m,c1,c2,c3) in enumerate(moods):
    x=60+(i%4)*(tw+12); yy=my+46+(i//4)*(th+12)
    tile=Image.new('RGB',(s(tw),s(th)),c1); td=ImageDraw.Draw(tile)
    for k in range(s(th)):
        t=k/s(th); a=tuple(int(int(c1[j:j+2],16)*(1-t)+int(c2[j:j+2],16)*t) for j in (1,3,5)); td.line([0,k,s(tw),k],fill=a)
    td.ellipse([s(tw-58),s(10),s(tw-14),s(54)],fill=c3)
    mask=Image.new('L',tile.size,0); ImageDraw.Draw(mask).rounded_rectangle([0,0,tile.size[0]-1,tile.size[1]-1],radius=s(18),fill=255)
    img.paste(tile,(s(x),s(yy)),mask); rr(x,yy,tw,th,18,None,outline=PLUM,width=3)
    dark=lum(c1)<0.2
    tc='#fff6e5' if dark else PLUM
    txt(x+12,yy+12,n,B(17,800),fill=tc); txt(x+12,yy+40,m,B(16,600),fill=tc); txt(x+12,yy+th-12,"guide: "+g,B(14,700),fill=('#fff6e5' if lum(c2)<0.2 else PLUM),anchor='ld')
# ---- type
X2=900
head(X2,186,"3 · TYPE")
txt(X2+3,234+4,"BEACH",LG(72),fill=SUN); txt(X2,234,"BEACH",LG(72))
txt(X2+260,248,"Luckiest Guy · titles & place names",B(18,700)); txt(X2+260,274,"caps only (no lowercase) · 1 or 2 words",B(16,500))
txt(X2,330,"Let's find Zib in the forest!",B(38,700))
txt(X2,382,"Baloo 2 · 500 to 800 · labels, parent area · single-storey a, g (good) · I and l alike (watch)",B(16,500))
txt(X2,408,"Pre-readers (3 to 5) don't read: every label is also spoken by a guide.",B(16,600))
# ---- buttons
head(X2,450,"4 · BIG BUTTON  (min 72 dp, main 96 dp)")
def bigbtn(cx,cy,r,state):
    if state=='idle':
        d.ellipse([s(cx-r),s(cy-r+12),s(cx+r),s(cy+r+12)],fill='#c8432a',outline=PLUM,width=s(4))
        d.ellipse([s(cx-r),s(cy-r),s(cx+r),s(cy+r)],fill='#ff7a5c',outline=PLUM,width=s(4))
        d.ellipse([s(cx-r*0.55),s(cy-r*0.8),s(cx-r*0.05),s(cy-r*0.5)],fill='#ffb39f')
        tri=[(cx-r*0.28,cy-r*0.42),(cx-r*0.28,cy+r*0.42),(cx+r*0.45,cy)]
        d.polygon([(s(a),s(b)) for a,b in tri],fill='#fff6e5',outline=PLUM,width=s(4))
    elif state=='pressed':
        cy2=cy+10
        d.ellipse([s(cx-r*0.96),s(cy2-r*0.96+2),s(cx+r*0.96),s(cy2+r*0.96+2)],fill='#c8432a',outline=PLUM,width=s(4))
        d.ellipse([s(cx-r*0.96),s(cy2-r*0.96),s(cx+r*0.96),s(cy2+r*0.96)],fill='#ee6446',outline=PLUM,width=s(4))
        tri=[(cx-r*0.26,cy2-r*0.4),(cx-r*0.26,cy2+r*0.4),(cx+r*0.43,cy2)]
        d.polygon([(s(a),s(b)) for a,b in tri],fill='#fff6e5',outline=PLUM,width=s(4))
    else:
        d.ellipse([s(cx-r),s(cy-r+12),s(cx+r),s(cy+r+12)],fill='#8f88a3',outline=PLUM,width=s(4))
        d.ellipse([s(cx-r),s(cy-r),s(cx+r),s(cy+r)],fill='#b9b3c7',outline=PLUM,width=s(4))
        d.rounded_rectangle([s(cx-r*0.34),s(cy-r*0.05),s(cx+r*0.34),s(cy+r*0.45)],radius=s(8),fill=PLUM)
        d.arc([s(cx-r*0.22),s(cy-r*0.42),s(cx+r*0.22),s(cy+r*0.12)],180,360,fill=PLUM,width=s(9))
        d.ellipse([s(cx-5),s(cy+r*0.12),s(cx+5),s(cy+r*0.12+10)],fill='#b9b3c7')
r=62
for i,(st,lab,sub) in enumerate([('idle','IDLE','coral, 12 dp edge'),('pressed','PRESSED','sinks 12 dp, 120 ms'),('locked','LOCKED','mist + padlock, wobble')]):
    cx=X2+80+i*180; cy=560
    bigbtn(cx,cy,r,st); txt(cx,cy+r+28,lab,B(20,800),anchor='mt'); txt(cx,cy+r+54,sub,B(14,500),anchor='mt')
# unlocked glow node
cx=X2+80+3*180; cy=560
for k,a in enumerate([46,30,18]):
    pass
d.ellipse([s(cx-r-14),s(cy-r-14),s(cx+r+14),s(cy+r+26)],outline=SUN,width=s(8))
bigbtn(cx,cy,r,'idle'); txt(cx,cy+r+28,'NEW!',B(20,800),anchor='mt'); txt(cx,cy+r+54,'sun ring, 1.6 s pulse',B(14,500),anchor='mt')
txt(X2,712,"Targets: 72 dp min · 96 dp primary · 120 to 140 dp map places · 24 dp gaps · 4 dp outlines.",B(16,600))
# ---- icons
head(X2,748,"5 · ICONS")
icx=X2
def iconbase(x,y,fill):
    d.rounded_rectangle([s(x),s(y),s(x+84),s(y+84)],radius=s(28),fill=fill,outline=PLUM,width=s(4))
labels=[('#7fd8cc','shell'),('#a88ad1','crayon'),('#b6dd7a','magnifier'),('#5a55a8','book'),('#ffb39f','lighthouse'),('#ffe4bf','puzzle')]
for i,(c,lab) in enumerate(labels):
    x=X2+i*104; y=792; iconbase(x,y,c)
    cx,cy=x+42,y+42
    if lab=='shell':
        d.pieslice([s(cx-26),s(cy-24),s(cx+26),s(cy+28)],180,360,fill='#fff6e5',outline=PLUM,width=s(3))
        for a in (-14,0,14): d.line([s(cx),s(cy+2),s(cx+a),s(cy-20)],fill=PLUM,width=s(3))
        d.rectangle([s(cx-26),s(cy+2),s(cx+26),s(cy+8)],fill=PLUM)
    if lab=='crayon':
        d.polygon([(s(cx-24),s(cy+14)),(s(cx+12),s(cy-22)),(s(cx+22),s(cy-12)),(s(cx-14),s(cy+24))],fill='#ff7a5c',outline=PLUM)
        d.polygon([(s(cx-24),s(cy+14)),(s(cx-14),s(cy+24)),(s(cx-30),s(cy+30))],fill=PLUM)
    if lab=='magnifier':
        d.ellipse([s(cx-24),s(cy-24),s(cx+8),s(cy+8)],fill='#fff6e5',outline=PLUM,width=s(5)); d.line([s(cx+6),s(cy+6),s(cx+24),s(cy+24)],fill=PLUM,width=s(9))
    if lab=='book':
        d.polygon([(s(cx-28),s(cy-18)),(s(cx),s(cy-12)),(s(cx),s(cy+22)),(s(cx-28),s(cy+16))],fill='#fff6e5',outline=PLUM)
        d.polygon([(s(cx+28),s(cy-18)),(s(cx),s(cy-12)),(s(cx),s(cy+22)),(s(cx+28),s(cy+16))],fill='#ffd60a',outline=PLUM)
    if lab=='lighthouse':
        d.polygon([(s(cx-12),s(cy+28)),(s(cx-7),s(cy-14)),(s(cx+7),s(cy-14)),(s(cx+12),s(cy+28))],fill='#fff6e5',outline=PLUM)
        d.rectangle([s(cx-10),s(cy+2),s(cx+10),s(cy+10)],fill='#ff7a5c'); d.rectangle([s(cx-9),s(cy-24),s(cx+9),s(cy-14)],fill=SUN,outline=PLUM)
        d.polygon([(s(cx-8),s(cy-24)),(s(cx+8),s(cy-24)),(s(cx),s(cy-32))],fill='#ff7a5c',outline=PLUM)
    if lab=='puzzle':
        d.rounded_rectangle([s(cx-22),s(cy-18),s(cx+18),s(cy+22)],radius=s(6),fill='#3fc1b0',outline=PLUM,width=s(3))
        d.ellipse([s(cx-6),s(cy-30),s(cx+6),s(cy-16)],fill='#3fc1b0',outline=PLUM,width=s(3)); d.ellipse([s(cx+14),s(cy-4),s(cx+28),s(cy+8)],fill='#3fc1b0',outline=PLUM,width=s(3))
    txt(cx,y+94,lab,B(14,600),anchor='mt')
txt(X2,912,"Chunky filled objects, 2 fills + plum outline, no thin lines, no letters; tap = guide says it.",B(16,500))
# ---- motion
head(X2,950,"6 · MOTION")
for i,l in enumerate(["Slow and round: 300 / 600 / 1000 / 1600 ms; ease-boing taps, ease-soft arrivals.",
"One thing moves at a time; idle = breathing loop of 1.6 s or slower; no flashing.",
"Camera pans between places (about 1 s); rewards = hug + soft sparkles, no confetti.",
"No timers, no fail buzzers; Calm mode stops loops; sound gentle and capped."]):
    txt(X2,994+i*28,"• "+l,B(16,500))
# ---- characters band
head(60,1112-24,"7 · GUIDES & NARRATORS")
cx=60
cmap={'fuzzle':'Fuzzle · map, islets','pip':'Pip · beach','dottie':'Dottie · cave','zib':'Zib · forest','bitsy':'Bitsy · shadows'}
x=60
for k in ['fuzzle','pip','dottie','zib','bitsy']:
    m=Image.open(f'/workspace/lilcmonsters/ref/{k}_c.png').convert('RGBA')
    hh=s(190 if k!='bitsy' else 150); m=m.resize((int(m.width*hh/m.height),hh),Image.LANCZOS)
    img.paste(m,(s(x)+ (s(150)-m.width)//2, s(1328)-m.height),m)
    txt(x+75,1124,cmap[k],B(15,800),anchor='mt')
    x+=166
# ---- refs
X3=1690
head(X3,186,"8 · REFERENCES (MOBBIN)")
refs=[('01_duolingo_path_next','Duolingo','path nodes'),('03_duolingo_foundations_locked','Duolingo','locked unit'),('09_finch_forest_nodes','Finch','forest nodes'),
('06_duolingo_abc_bigarrow','Duolingo ABC','one big button'),('10_finch_narrator_bubbles','Finch','narrator hunt'),('14_lake_colouring','Lake','colouring dots'),
('13_gac_music_notes','Google Arts & Culture','sound toys'),('16_elevate_shape_puzzle','Elevate','shape puzzle'),('18_calm_night_program','Calm','night library')]
rw,rh=214,300
for i,(f,app,what) in enumerate(refs):
    x=X3+(i%3)*(rw+14); y=232+(i//3)*(rh+68)
    m=Image.open(f'/workspace/seamonsters/design/refs/{f}.png').convert('RGB')
    m=m.resize((s(rw),int(m.height*s(rw)/m.width)),Image.LANCZOS).crop((0,0,s(rw),s(rh)))
    mask=Image.new('L',m.size,0); ImageDraw.Draw(mask).rounded_rectangle([0,0,m.size[0]-1,m.size[1]-1],radius=s(16),fill=255)
    img.paste(m,(s(x),s(y)),mask); rr(x,y,rw,rh,16,None,outline=PLUM,width=3)
    txt(x+4,y+rh+8,app,B(16,800)); txt(x+4,y+rh+32,what,B(14,500))
txt(X3,232+3*(rh+68)-6,"Screens © their owners, via mobbin.com, for internal reference only.",B(13,500))
rr(X2,1100,740,200,24,'#d4f4ee',outline=PLUM,width=3)
txt(X2+24,1118,"STATUS",LG(26))
for i,l in enumerate(["Draft v0 for art-director review. Nothing here is tested with children yet.",
"Guides per place, coral CTA and dp sizes are proposals to validate in the mockup phase.",
"Next: map sketch (8 places, locked islets + shadow game), then 1 screen per module.",
"Full spec + reference list: VISUAL_SYSTEM_v0.md · thumbnails: design/refs/"]):
    txt(X2+24,1160+i*30,"• "+l,B(17,600))
# sun accent
d.ellipse([s(W-150),s(28),s(W-62),s(116)],fill=SUN,outline=PLUM,width=s(4))
img=img.resize((W,H),Image.LANCZOS); img.save('/workspace/seamonsters/design/direction_v1.png',optimize=True); print('ok')
