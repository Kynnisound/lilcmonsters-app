"""Lil C Monsters icon objects, hand-written SVG (viewBox 96x96 dp-like units).
Rules: plump filled objects, 4-unit plum outline, 2 fills (base + shade) + soft highlight,
no letters/numbers, no pure white; any light part is separated from turquoise/coral by plum."""
import cairosvg, os, io
P='#3A1752'; P2='#6E28A0'; CREAM='#FFF6E5'; SAND='#FFE4BF'; SANDD='#F2C58F'
SUN='#FFD60A'; SUND='#E8B400'; CORAL='#FF7A5C'; CORALD='#C8432A'; CORALL='#FFA48C'
LAG='#3FC1B0'; LAGD='#0B6E6A'; FOAM='#D4F4EE'; PIP='#1B98D0'; PIPD='#127AA8'
MIST='#B9B3C7'; MISTD='#8F88A3'; FUZ='#FC9313'; FUZD='#D97706'; FUZL='#FFC56B'
DOT='#86BE34'; ZIB='#A75BAD'; ZIBD='#7E3F86'; BIT='#FC647D'; SHELL='#FFB3A1'; SHELLD='#EE8670'
_n=[0]
def shape(d, fill, shade, hl=None, hlop=.55, off=(-3,-3.5), sw=4, rule='nonzero'):
    _n[0]+=1; i=f'c{_n[0]}'
    h=''
    if hl: h=f'<g opacity="{hlop}">{hl}</g>'
    return (f'<clipPath id="{i}"><path d="{d}" clip-rule="{rule}"/></clipPath>'
            f'<g clip-path="url(#{i})"><path d="{d}" fill="{shade}" fill-rule="{rule}"/>'
            f'<path d="{d}" fill="{fill}" fill-rule="{rule}" transform="translate({off[0]},{off[1]})"/>{h}</g>'
            f'<path d="{d}" fill="none" stroke="{P}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"/>')
def circ(cx,cy,r): return f'M{cx-r},{cy} a{r},{r} 0 1,0 {2*r},0 a{r},{r} 0 1,0 {-2*r},0 Z'
def ell(cx,cy,rx,ry): return f'M{cx-rx},{cy} a{rx},{ry} 0 1,0 {2*rx},0 a{rx},{ry} 0 1,0 {-2*rx},0 Z'
def blob(cx,cy,rx,ry,c=CREAM,rot=-25): return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{c}" transform="rotate({rot} {cx} {cy})"/>'
def line(d,w=3.5,c=P): return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'

def beach_shell():
    shell='M30,78 C14,68 8,46 18,30 C27,17 39,12 48,12 C57,12 69,17 78,30 C88,46 82,68 66,78 Z'
    ribs=''.join(line(f'M48,80 L{x},{y}',3) for x,y in [(16,46),(24,24),(38,13),(58,13),(72,24),(80,46)])
    s=shape(shell,SHELL,SHELLD,blob(32,32,9,5))
    s=s.replace('</g><path d="'+shell+'" fill="none"', ribs+'</g><path d="'+shell+'" fill="none"',1)
    hinge=shape('M36,74 h24 a5,5 0 0 1 5,5 v3 a5,5 0 0 1 -5,5 h-24 a5,5 0 0 1 -5,-5 v-3 a5,5 0 0 1 5,-5 Z',SHELL,SHELLD)
    note=(shape('M72,4 L92,10 L92,20 L72,14 Z',SUN,SUND,off=(0,0),sw=3.5)+
          shape('M68,5 h7 v34 h-7 Z',SUN,SUND,off=(0,0),sw=3.5)+
          shape(ell(64,40,11,9),SUN,SUND,blob(61,37,4,2.4,c=CREAM),hlop=.8))
    return '<g transform="translate(-4 6) scale(.9)">'+s+hinge+'</g>'+note

def cave_palette():
    pal=('M50,14 C76,14 90,30 88,50 C86,66 72,70 64,66 C56,62 49,66 54,75 C58,83 50,87 42,85 '
         'C22,81 8,67 8,48 C8,28 26,14 50,14 Z '+circ(30,62,7))
    out=shape(pal,SAND,SANDD,blob(36,26,12,6),rule='evenodd')
    for (x,y,c,d) in [(30,36,FUZ,FUZD),(50,28,PIP,PIPD),(70,36,DOT,'#5E8E1E'),(74,54,BIT,'#D9435C')]:
        out+=shape(circ(x,y,7.5),c,d,blob(x-2,y-2.5,2.6,1.6),off=(-1.5,-1.8),sw=3.5)
    # brush
    out+=shape('M40,50 L58,68 a4,4 0 0 1 -5,5 L35,55 Z',P2,'#4E1A75',off=(-1,-1),sw=3.5)
    out+=shape('M33,52 C29,48 31,42 36,43 C41,44 43,50 40,53 Z',FUZ,FUZD,off=(-1,-1),sw=3.5)
    return out

def forest_magnifier():
    handle='M56,62 L66,52 L88,74 a7,7 0 0 1 0,10 l0,0 a7,7 0 0 1 -10,0 Z'
    ring=circ(40,40,28)+' '+circ(40,40,18)
    lens=circ(40,40,18)
    return (shape(handle,SUN,SUND,blob(72,62,6,2.5,rot=45))+
            shape(lens,FOAM,'#A9E4DA',blob(33,32,7,4,c=CREAM),hlop=.9,off=(2.5,3))+
            shape(ring,ZIB,ZIBD,blob(24,22,8,4,c='#D7B2DB'),hlop=.9,rule='evenodd'))

def library_book():
    cover='M4,28 L4,84 C22,78 38,80 48,88 C58,80 74,78 92,84 L92,28 C74,24 58,26 48,32 C38,26 22,24 4,28 Z'
    left='M48,30 C38,22 24,19 12,22 L12,72 C24,69 38,71 48,78 Z'
    right='M48,30 C58,22 72,19 84,22 L84,72 C72,69 58,71 48,78 Z'
    lines=''.join(line(d,3,'#C9A4CF') for d in ['M20,34 C28,32 34,33 40,36','M20,46 C28,44 34,45 40,48','M56,36 C62,33 68,32 76,34','M56,48 C62,45 68,44 76,46'])
    rib='M70,20 L70,46 L64,40 L58,46 L58,22 Z'
    return (shape(cover,PIP,PIPD)+shape(left,CREAM,'#F1DEC4',off=(-2,-2))+shape(right,CREAM,'#F1DEC4',off=(-2,-2))
            +lines+shape(rib,BIT,'#D9435C',off=(-1,-1),sw=3.5)+line('M48,30 L48,78',3.5))

def lighthouse_play():
    rock='M12,88 C12,77 26,71 48,71 C70,71 84,77 84,88 Z'
    tower='M35,44 L61,44 L68,82 L28,82 Z'
    tw=('<clipPath id="lhT"><path d="'+tower+'"/></clipPath><g clip-path="url(#lhT)">'
        '<path d="'+tower+'" fill="#EFD9BE"/><path d="'+tower+'" fill="'+CREAM+'" transform="translate(-3,0)"/>'
        '<rect x="20" y="54" width="60" height="11" fill="'+CORAL+'"/><rect x="58" y="54" width="20" height="11" fill="'+CORALD+'"/>'
        '<rect x="20" y="74" width="60" height="10" fill="'+CORAL+'"/><rect x="60" y="74" width="20" height="10" fill="'+CORALD+'"/>'
        + line('M20,54 H80',3)+line('M20,65 H80',3)+line('M20,74 H80',3) + '</g>'
        '<path d="'+tower+'" fill="none" stroke="'+P+'" stroke-width="4" stroke-linejoin="round"/>')
    lamp='M28,20 h40 a3,3 0 0 1 3,3 v18 a3,3 0 0 1 -3,3 h-40 a3,3 0 0 1 -3,-3 v-18 a3,3 0 0 1 3,-3 Z'
    dome='M30,21 C30,6 66,6 66,21 Z'
    play='M41,24.5 L58,32 L41,39.5 Z'
    return (shape(rock,MISTD,'#6F6888',blob(32,78,8,3,c=MIST),hlop=.9)+tw
            +shape(lamp,SUN,SUND,blob(34,26,5,2.5,c=CREAM),hlop=.8,off=(-2,-2))
            +shape(play,P,P,off=(0,0),sw=3)+shape(dome,P2,'#4E1A75',blob(42,12,6,2.5,c='#B07FD0'),hlop=.9)
            +shape(circ(48,5,4),SUN,SUND,off=(0,0),sw=3))

def islets_puzzle():
    d=('M18,30 L36,30 C32,22 36,11 47,11 C58,11 62,22 58,30 L78,30 L78,46 C85,42 93,47 93,57 '
       'C93,67 85,72 78,67 L78,86 L18,86 L18,68 C25,72 34,67 34,58 C34,49 25,44 18,48 Z')
    return shape(d,FUZ,FUZD,blob(32,40,8,4,c=FUZL),hlop=.95)

def shadow_lantern():
    glow=''
    hook=line('M48,6 L48,18',5)+line('M48,6 L48,18',0.01)
    body=ell(48,54,27,27)
    ribs=''.join(line(d,2.6,'#E0A400') for d in ['M48,28 L48,80','M36,30 C28,44 28,64 36,78','M60,30 C68,44 68,64 60,78'])
    capt='M34,18 h28 a4,4 0 0 1 4,4 v4 a4,4 0 0 1 -4,4 h-28 a4,4 0 0 1 -4,-4 v-4 a4,4 0 0 1 4,-4 Z'
    capb='M36,78 h24 a4,4 0 0 1 4,4 v3 a4,4 0 0 1 -4,4 h-24 a4,4 0 0 1 -4,-4 v-3 a4,4 0 0 1 4,-4 Z'
    s=shape(body,SUN,'#F0B800',blob(37,42,8,5,c=CREAM),hlop=.75)
    s=s.replace('</g><path d="'+body+'" fill="none"',ribs+'</g><path d="'+body+'" fill="none"',1)
    return glow+hook+s+shape(capt,P2,'#4E1A75',off=(-1,-1.5),sw=3.5)+shape(capb,P2,'#4E1A75',off=(-1,-1.5),sw=3.5)+line('M48,89 L48,93',5)

def speaker(fill=CREAM,shade=SANDD):
    d='M12,38 h14 L46,20 a3,3 0 0 1 5,2 v52 a3,3 0 0 1 -5,2 L26,58 h-14 a4,4 0 0 1 -4,-4 v-12 a4,4 0 0 1 4,-4 Z'
    return shape(d,fill,shade,blob(20,42,5,2.5,c='#FFFFFF' if fill==CREAM else CREAM),hlop=.5)
def sound_on():
    return speaker()+line('M60,36 C66,42 66,54 60,60',7)+line('M70,26 C82,38 82,58 70,70',7)
def sound_off():
    return speaker(MIST,MISTD)+line('M62,36 L84,60',7)+line('M84,36 L62,60',7)

GATE='#5A536C'; GATE_LINE='#4A4459'   # mauve-grey: 3.2:1 on lagoon, 6.7:1 on cream
def parental_gate():
    """Parent-only gear: flat, monochrome, thin 2-unit outline, no gloss, no relief, no people."""
    import math
    n=8; R=44; r=34; pts=[]
    for i in range(n):
        c=2*math.pi*i/n
        for da,rad in [(-0.36,r),(-0.20,R),(0.20,R),(0.36,r)]:
            pts.append((48+rad*math.cos(c+da), 48+rad*math.sin(c+da)))
    d='M'+' L'.join(f'{x:.2f},{y:.2f}' for x,y in pts)+' Z '+circ(48,48,14)
    return (f'<path d="{d}" fill="{GATE}" fill-rule="evenodd" stroke="{GATE_LINE}" stroke-width="2" stroke-linejoin="round"/>')

def back():
    d='M44,14 a5,5 0 0 1 8,4 v14 h24 a8,8 0 0 1 8,8 v16 a8,8 0 0 1 -8,8 h-24 v14 a5,5 0 0 1 -8,4 L10,52 a5,5 0 0 1 0,-8 Z'
    return shape(d,CREAM,SANDD,blob(40,30,8,3,c='#FFFFFF'),hlop=.5)

def home():
    walls='M22,46 L74,46 L74,82 a4,4 0 0 1 -4,4 L26,86 a4,4 0 0 1 -4,-4 Z'
    roof='M48,12 a5,5 0 0 1 3.5,1.5 L88,46 a5,5 0 0 1 -3,9 L11,55 a5,5 0 0 1 -3,-9 L44.5,13.5 A5,5 0 0 1 48,12 Z'
    door='M40,86 L40,68 a8,8 0 0 1 16,0 L56,86 Z'
    chim='M64,16 h10 v20 h-10 Z'
    return (shape(chim,CORAL,CORALD,off=(-1.5,0))+shape(walls,CREAM,'#EFD9BE',off=(-3,0))+shape(door,P2,'#4E1A75',off=(-1.5,-1.5),sw=3.5)
            +shape(roof,CORAL,CORALD,blob(36,28,8,3,c=CORALL),hlop=.9))

def padlock(fill=P, shade='#26093A', hl='#7A4E9B'):
    shackle=line('M30,46 L30,32 C30,10 66,10 66,32 L66,46',17)+line('M30,46 L30,32 C30,10 66,10 66,32 L66,46',8,MIST)
    body='M22,42 h52 a8,8 0 0 1 8,8 v28 a8,8 0 0 1 -8,8 h-52 a8,8 0 0 1 -8,-8 v-28 a8,8 0 0 1 8,-8 Z'
    key='M48,54 a7,7 0 0 1 4,12.7 l2,8.3 h-12 l2,-8.3 A7,7 0 0 1 48,54 Z'
    return shackle+shape(body,fill,shade,blob(30,50,8,3,c=hl),hlop=.95)+f'<path d="{key}" fill="{CREAM}"/>'

def padlock_badge():
    inner=padlock()
    return (shape(circ(48,48,43),CREAM,'#E9DCC6',off=(-2,-2.5),sw=5)+
            f'<g transform="translate(48 50) scale(0.6) translate(-48 -50)">{inner}</g>')

ICONS={  # name -> (fn, intended dp, use)
 'beach_shell':(beach_shell,'Beach / sound sandbox place badge (replaces music-note glyph)'),
 'cave_palette':(cave_palette,'Cave / colouring place badge (replaces palette glyph)'),
 'forest_magnifier':(forest_magnifier,'Forest / monster hunt place badge (replaces magnifier glyph)'),
 'library_book':(library_book,'Library / audiobooks place badge (replaces book glyph)'),
 'lighthouse_play':(lighthouse_play,'Lighthouse / YouTube place badge (replaces play glyph)'),
 'islets_puzzle':(islets_puzzle,'Islets puzzle place badge (replaces puzzle glyph)'),
 'shadow_lantern':(shadow_lantern,'Shadow game place badge (replaces lantern glyph)'),
 'sound_on':(sound_on,'Map top-right sound toggle, on'),
 'sound_off':(sound_off,'Map top-right sound toggle, off'),
 'parental_gate':(parental_gate,'Parental gate entry, map top-right only, outside the play area: flat mauve-grey gear, no animation, no sound'),
 'back':(back,'Back, top-left (inside a module sub-screen)'),
 'home':(home,'Home / back to map, top-left on every place screen'),
 'padlock':(padlock,'Padlock for locked buttons and cards'),
 'padlock_badge':(padlock_badge,'Round padlock badge overlaid on locked landmarks / tiles'),
}
PAD={'parental_gate':1}
def svg_icon(name, pad=None):
    pad=PAD.get(name,4) if pad is None else pad
    body=ICONS[name][0]()
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-pad} {-pad} {96+2*pad} {96+2*pad}" width="104" height="104">{body}</svg>')
