import json
from PIL import Image, ImageDraw, ImageFont
F='/workspace/seamonsters/design/_work/'; A='/workspace/seamonsters/design/assets/shadows'
ft=ImageFont.truetype(F+'LuckiestGuy.ttf',40); fb=ImageFont.truetype(F+'Baloo2-700.ttf',22); fs=ImageFont.truetype(F+'Baloo2-600.ttf',18)
PL=(58,23,82); MU=(90,63,107); names=['fuzzle','pip','dottie','zib','bitsy']
feat={'fuzzle':'giant hug arms (T), striped horns','pip':'one arm waving high, single eye (hole)','dottie':'giant paintbrush, polka dots + eye (holes)',
      'zib':'magnifier ring held out, curly antennae','bitsy':'tiny, under one huge leaf parachute'}
T=json.load(open(F+'pipeline/shadow_iou_v2.json')); P=T['pairs']; X=T['shadow_vs_colour']
W=1900; c=Image.new('RGBA',(W,1700),(255,246,229,255)); d=ImageDraw.Draw(c)
d.text((50,30),'SHADOW GAME · POSES + SILHOUETTES v2 (BUG-005 RETEST)',font=ft,fill=PL)
d.text((50,84),'Row 1: book cutout (identity ref). Row 2: new colour shadow-game pose (assets/shadows/color). Row 3: its silhouette, built from that alpha (plum #3A1752 at 85 %), on the dusk slot.',font=fs,fill=MU)
S=330
for i,n in enumerate(names):
    x=50+i*(S+35); y=125
    ref=Image.open(f'/workspace/lilcmonsters/ref/{n}_c.png').convert('RGBA'); ref.thumbnail((150,150),Image.LANCZOS)
    c.alpha_composite(ref,(x+(S-ref.width)//2,y+(150-ref.height)))
    y+=165; t=Image.new('RGBA',(S,S),(255,236,205,255)); col=Image.open(f'{A}/color/512/{n}_512.png').resize((S-30,S-30),Image.LANCZOS); t.alpha_composite(col,(15,15)); c.alpha_composite(t,(x,y))
    y+=S+12; t=Image.new('RGBA',(S,S),(234,217,245,255)); dd=ImageDraw.Draw(t); dd.ellipse((5,5,S-5,S-5),fill=(255,197,107,90),outline=PL,width=4)
    im=Image.open(f'{A}/512/shadow_{n}_512.png').resize((S-30,S-30),Image.LANCZOS); t.alpha_composite(im,(15,15)); c.alpha_composite(t,(x,y))
    y+=S+8; d.text((x,y),n.capitalize(),font=fb,fill=PL); d.text((x,y+28),feat[n],font=fs,fill=MU)
y=125+165+2*S+12+80
def grid(y,title,val,hl):
    d.text((50,y),title,font=fb,fill=PL); y+=40; cw=150
    for j,n in enumerate(names): d.text((230+j*cw,y),n,font=fb,fill=PL)
    for i,a in enumerate(names):
        yy=y+40+i*44; d.text((50,yy),a,font=fb,fill=PL)
        for j,b in enumerate(names):
            x=230+j*cw; v=val(a,b)
            if v is None: d.text((x,yy),'-',font=fb,fill=(150,140,170)); continue
            colr,bg=hl(a,b,v); d.rounded_rectangle((x-8,yy-2,x+128,yy+34),8,fill=bg); d.text((x,yy),v if isinstance(v,str) else f'{v:.3f}',font=fb,fill=colr)
    return y+40+5*44
def pv(a,b):
    if a==b: return None
    k=f'{a}-{b}' if f'{a}-{b}' in P else f'{b}-{a}'; return f"{P[k]['iou_512']:.3f} ({P[k]['iou_200']:.3f})"
def ph(a,b,v):
    f=float(v.split()[0]); return ((46,125,50),(220,240,222)) if f<0.5 else (((200,120,0),(255,236,200)) if f<0.6 else ((200,40,40),(255,215,215)))
y2=grid(y,'Shadow vs shadow IoU · 512 px (200 px, Webboy tool method) · target < 0.6, ideal < 0.5',pv,ph)
mx=max(v['iou_512'] for v in P.values()); mk=max(P,key=lambda k:P[k]['iou_512'])
d.text((1080,y+40),f'max pair: {mx:.3f} ({mk.replace("-"," / ")}), all 10 < 0.5',font=fb,fill=PL)
d.text((1080,y+76),'v1 silhouettes vs book cutouts: own monster was the',font=fs,fill=MU)
d.text((1080,y+100),'closest match for Dottie only (QA retest 27/10).',font=fs,fill=MU)
d.text((1080,y+136),'v2: shadow = alpha of its colour pose (minus holes);',font=fs,fill=MU)
d.text((1080,y+160),'own match 0.945-1.000, every shadow matches its own monster best.',font=fs,fill=MU)
def xv(a,b): return X[a][b]
def xh(a,b,v): return ((255,255,255),(46,125,50)) if a==b else (((46,125,50),(220,240,222)) if v<0.5 else ((200,120,0),(255,236,200)))
y3=grid(y2+30,'Shadow (row) vs colour pose alpha (column) IoU · 512 px · diagonal = own monster',xv,xh)
c=c.crop((0,0,W,y3+30)); c.convert('RGB').save(A+'/_contact.png',optimize=True); print(c.size)
