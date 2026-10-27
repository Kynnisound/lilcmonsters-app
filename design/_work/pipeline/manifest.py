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
m={'project':'Lil C Monsters (SeaMonsters)','version':'assets v1, working draft, 27 Oct 2026','status':'draft for art-director review (Margaux Vérany), not final art',
   'flutter_asset_root':'assets/images/','density_folders':['(1x, no folder)','2.0x/','3.0x/'],
   'map':{'frame_dp':[W,H],'mood':'morning lagoon','opaque':True,
          'variants':[{'name':'map_island_morning.png','dp':[W,H],'intended_screen':'Map hub (home screen), landscape, BoxFit.cover','files':files('map','map_island_morning.png')},
                      {'name':'map_island_morning_safe16x9.png','dp':[667,H],'intended_screen':'Map hub on 16:9 phones: centred 667x375 dp crop of the same frame (every place is inside it)','files':files('map','map_island_morning_safe16x9.png')}],
          'source_svg':'_work/pipeline/map_island.svg (in design/)',
          'ui_reserved_dp':{'top_right_sound_and_parent_gate':[690,0,812,100]},
          'spots':{k:{'center_dp':[x,y],'align':[round(2*x/W-1,4),round(2*y/H-1,4)],'fraction':[round(x/W,4),round(y/H,4)],
                      'landmark_box_dp':[140,140],'hit_area':'circle, 130 dp diameter, centred on center_dp'} for k,(x,y) in L['spots'].items()},
          'guide_spot':{'who':'Fuzzle','foot_center_dp':[L['guide'][0],L['guide'][1]+50],'note':'empty sand pad, no landmark'}},
   'places':[], 'icons':[]}
for k in L['spots']:
    for st in ['unlocked','locked']:
        m['places'].append({'id':k,'state':st,'name':f'place_{k}_{st}.png','dp':[140,140],'hit_area_dp':'120 to 140 (130 used in the layout)',
            'intended_screen':'Map hub: '+SCREEN[k],'notes':'locked = mist ramp + plum padlock badge baked top-right (56 dp at 140 dp)' if st=='locked' else 'full colour; "new" sun ring is drawn by the app, not baked',
            'files':files('places',f'place_{k}_{st}.png')})
for n,dp in IDP.items():
    use=icons.ICONS[n][1]
    m['icons'].append({'id':n,'state':{'sound_on':'on','sound_off':'off'}.get(n,'default'),'name':f'icon_{n}.png','dp':[dp,dp],
        'display_range_dp':'40 to 96' if n in ICON_PLACE else ('44' if n=='parental_gate' else f'{int(dp*0.6)} to {dp}'),
        'intended_screen':use,**({'colour':'#5A536C fill, #4A4459 2-unit outline','contrast':'3.2:1 on lagoon #3FC1B0, 6.7:1 on cream #FFF6E5','touch_target_dp':'>= 44','motion':'none (no wobble, no sound, no tap invitation)'} if n=='parental_gate' else {}),'svg':f'icons/svg/icon_{n}.svg','files':files('icons',f'icon_{n}.png')})
json.dump(m,open(f'{A}/manifest.json','w'),indent=2,ensure_ascii=False)
print(len(m['places']),len(m['icons']))
