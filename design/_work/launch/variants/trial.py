import sys; sys.path.insert(0,'/workspace/seamonsters/design/_work/pipeline')
from launch_common import *
from PIL import ImageFilter
import launch_motif as M
def deep_bg(size, center=(.5,.475)):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    top=np.array(rgb('#0E7A75'),np.float32); bot=np.array(rgb('#07524F'),np.float32)
    col=top*(1-y[...,None])+bot*y[...,None]
    r=np.hypot(x-center[0], y-center[1])[...,None]
    g=np.clip(1-r/.46,0,1)**1.5*.75
    col=col*(1-g)+np.array(rgb('#054B48'),np.float32)*g
    return Image.fromarray(col.clip(0,255).astype(np.uint8),'RGB')
out=[]
C=(512,486)
for rim in (None,'#3FC1B0','#7FDCCF'):
    bg=deep_bg(1024).convert('RGBA')
    fg=render(M.motif_svg(shadow=False),1024,430,center=C)
    if rim:
        a=fg.getchannel('A').filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.GaussianBlur(6))
        a=a.point(lambda v: min(255,int(v*1.0)))
        L=Image.new('RGBA',(1024,1024),rgb(rim)+(255,)); L.putalpha(a); bg.alpha_composite(L)
    bg.alpha_composite(fg); out.append(bg)
sheet=Image.new('RGB',(1024*3+40,1024+200),(240,236,230))
for i,im in enumerate(out):
    sheet.paste(masked(im,superellipse(1024,5)),(i*1044,0),superellipse(1024,5))
    for j,s in enumerate((60,29)):
        sm=im.resize((s,s),Image.LANCZOS); sheet.paste(sm.convert('RGB'),(i*1044+300+j*100,1060))
sheet.resize((sheet.width//2,sheet.height//2),Image.LANCZOS).save('/workspace/seamonsters/design/_work/launch/variants/trial_rims.png')
