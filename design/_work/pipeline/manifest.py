import json, os
from PIL import Image
A='/workspace/seamonsters/design/assets'
L=json.load(open('map_layout.json')); W,H=L['frame_dp']
from export_icons import DP as IDP
import icons
def files(folder,name):
    out={}
    for k,pre in [('1x',''),('2x','2.0x/'),('3x','3.0x/')]:
        p=f'{folder}/{pre}{name}'; im=Image.open(f'{A}/{p}'); out[k]={'file':p,'px':list(im.size)}
    return out
SCREEN={'beach':'Beach · sound sandbox (guide Pip)','cave':'Cave · colouring (guide Dottie)','forest':'Forest · monster hunt (guide Zib)',
        'library':'Library · animated audiobooks','lighthouse':'Lighthouse · YouTube, behind parental gate','islets':'Islets puzzle (guide Fuzzle)','shadow':'Shadow game (guide Bitsy)'}
ICON_PLACE={'beach_shell':'beach','cave_palette':'cave','forest_magnifier':'forest','library_book':'library','lighthouse_play':'lighthouse','islets_puzzle':'islets','shadow_lantern':'shadow'}
m={'project':'Lil C Monsters (SeaMonsters)','version':'assets v1.2, working draft, 27 Oct 2026','status':'draft for art-director review (Margaux Vérany), not final art',
   'flutter_asset_root':'assets/images/','density_folders':['(1x, no folder)','2.0x/','3.0x/'],
   'map':{'frame_dp':[W,H],'mood':'morning lagoon','opaque':True,
          'variants':[{'name':'map_island_morning.png','dp':[W,H],'intended_screen':'Map hub (home screen), landscape, BoxFit.cover','files':files('map','map_island_morning.png')},
                      {'name':'map_island_morning_tablet43.png','dp':[1024,768],'intended_screen':'Map hub on 4:3 tablets (iPad), BoxFit.cover; layout = layouts.tablet43','files':files('map','map_island_morning_tablet43.png')},
                      {'name':'map_island_morning_safe16x9.png','dp':[667,H],'intended_screen':'Map hub on 16:9 phones: centred 667x375 dp crop of the same frame (every place is inside it)','files':files('map','map_island_morning_safe16x9.png')}],
          'source_svg':['_work/pipeline/map_island.svg','_work/pipeline/map_island_tablet43.svg'],
          'ui_reserved_dp':{'top_right_sound_and_parent_gate':[690,0,812,100]},
          'spots':{k:{'center_dp':[x,y],'align':[round(2*x/W-1,4),round(2*y/H-1,4)],'fraction':[round(x/W,4),round(y/H,4)],
                      'landmark_box_dp':[140,140],'hit_area':'circle, 130 dp diameter, centred on center_dp'} for k,(x,y) in L['spots'].items()},
          'guide_spot':{'who':'Fuzzle','foot_center_dp':[L['guide'][0],L['guide'][1]+50],'note':'empty sand pad, no landmark'}},
   'places':[], 'icons':[]}
import math
def layout(fn, mapfile, note):
    LL=json.load(open(fn)); w,h=LL['frame_dp']; sp=LL['spots']
    ks=list(sp); md=min(math.dist(sp[a],sp[b]) for i,a in enumerate(ks) for b in ks[i+1:])
    hud=LL.get('hud',[690,0,812,100])
    return {'map':mapfile,'frame_dp':[w,h],'note':note,
      'places':{k:{'center_dp':[x,y],'center_fraction':[round(x/w,4),round(y/h,4)],'align':[round(2*x/w-1,4),round(2*y/h-1,4)],
                   'box_dp_at_scale_1':140,'tap_area':{'shape':'circle','diameter_dp_at_scale_1':130,'diameter_fraction_of_frame_width':round(130/w,4),'centre':'center_dp'}} for k,(x,y) in sp.items()},
      'guide_pad':{'who':'Fuzzle','pad_center_dp':[LL['guide'][0],LL['guide'][1]+34],'foot_center_dp':[LL['guide'][0],LL['guide'][1]+50],
                   'pad_center_fraction':[round(LL['guide'][0]/w,4),round((LL['guide'][1]+34)/h,4)]},
      'hud_safe_zone_dp':{'rect_ltrb':hud,'rect_fraction':[round(hud[0]/w,4),round(hud[1]/h,4),round(hud[2]/w,4),round(hud[3]/h,4)],
                          'contents':'sound button 72 dp + parental-gate gear 44 dp, 24 dp margins; fixed dp, never scaled'},
      'min_center_distance_dp':round(md,1)}
m['map']['scaling_rule']={'map_scale':'s = max(screenW / frameW, screenH / frameH)  (BoxFit.cover)',
   'place_size_dp':'clamp(140 * s, 120, 200)','place_position':'frame offset + center_dp * s (equivalently center_fraction of the drawn map rect)',
   'tap_area':'circle of 130/140 of the place size, centred','hud':'fixed dp, does not scale'}
m['map']['layouts']={'phone':layout('map_layout.json','map_island_morning.png','812 x 375 dp frame; 16:9 phones see the centred safe16x9 crop'),
                     'tablet43':layout('map_layout_tablet43.json','map_island_morning_tablet43.png','1024 x 768 dp frame for 4:3 tablets; same island redrawn with places spread vertically')}
m['map'].pop('spots',None); m['map'].pop('guide_spot',None); m['map'].pop('ui_reserved_dp',None)
m['map']['note']='Spot positions moved to map.layouts.<phone|tablet43> (v1.2). Module pictograms are no longer shown on map places.'

for k in L['spots']:
    for st in ['unlocked','locked']:
        m['places'].append({'id':k,'state':st,'name':f'place_{k}_{st}.png','dp':[200,200],'display_size_dp':'140 x map scale, clamped 120 to 200 (nominal 140)','hit_area':'circle, 130/140 of the displayed size',
            'intended_screen':'Map hub: '+SCREEN[k],'notes':'locked = mist ramp + plum padlock badge baked top-right (40 % of the box)' if st=='locked' else 'full colour; "new" sun ring is drawn by the app, not baked',
            'files':files('places',f'place_{k}_{st}.png')})
for n,dp in IDP.items():
    use=icons.ICONS[n][1]
    m['icons'].append({'id':n,'state':{'sound_on':'on','sound_off':'off'}.get(n,'default'),'name':f'icon_{n}.png','dp':[dp,dp],
        'display_range_dp':'40 to 96' if n in ICON_PLACE else ('44' if n=='parental_gate' else f'{int(dp*0.6)} to {dp}'),
        'intended_screen':use if n not in ICON_PLACE else use.replace('place badge','module icon').split(' (replaces')[0]+' : inside the module only (not on the map places, rule v1.2)',**({'colour':'#5A536C fill, #4A4459 2-unit outline','contrast':'3.2:1 on lagoon #3FC1B0, 6.7:1 on cream #FFF6E5','touch_target_dp':'>= 44','motion':'none (no wobble, no sound, no tap invitation)'} if n=='parental_gate' else {}),'svg':f'icons/svg/icon_{n}.svg','files':files('icons',f'icon_{n}.png')})
json.dump(m,open(f'{A}/manifest.json','w'),indent=2,ensure_ascii=False)
print(len(m['places']),len(m['icons']))
