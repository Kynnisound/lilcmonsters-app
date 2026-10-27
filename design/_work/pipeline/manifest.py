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
m={'project':'Lil C Monsters (SeaMonsters)','version':'assets v1.3, working draft, 27 Oct 2026','status':'draft for art-director review (Margaux Vérany), not final art',
   'flutter_asset_root':'assets/images/','density_folders':['(1x, no folder)','2.0x/','3.0x/'],
   'map':{'frame_dp':[W,H],'mood':'morning lagoon','opaque':True,
          'variants':[{'name':'map_island_morning.png','dp':[W,H],'intended_screen':'Map hub (home screen), landscape, BoxFit.cover','files':files('map','map_island_morning.png')},
                      {'name':'map_island_morning_tablet43.png','dp':[1024,768],'intended_screen':'Map hub on 4:3 tablets (iPad), BoxFit.cover; layout = layouts.tablet43','files':files('map','map_island_morning_tablet43.png')},
                      {'name':'map_island_morning_compact.png','dp':[640,360],'intended_screen':'Map hub on small phones, height <= 360 dp (568x320, 640x360); layout = layouts.phone_compact','files':files('map','map_island_morning_compact.png')},
                      {'name':'map_island_morning_safe16x9.png','dp':[667,H],'intended_screen':'Map hub on 16:9 phones: centred 667x375 dp crop of the same frame (every place is inside it)','files':files('map','map_island_morning_safe16x9.png')}],
          'source_svg':['_work/pipeline/map_island.svg','_work/pipeline/map_island_tablet43.svg'],
          'ui_reserved_dp':{'top_right_sound_and_parent_gate':[690,0,812,100]},
          'spots':{k:{'center_dp':[x,y],'align':[round(2*x/W-1,4),round(2*y/H-1,4)],'fraction':[round(x/W,4),round(y/H,4)],
                      'landmark_box_dp':[140,140],'hit_area':'circle, 130 dp diameter, centred on center_dp'} for k,(x,y) in L['spots'].items()},
          'guide_spot':{'who':'Fuzzle','foot_center_dp':[L['guide'][0],L['guide'][1]+50],'note':'empty sand pad, no landmark'}},
   'places':[], 'icons':[]}
import math
def layout(fn, mapfile, note, base=140, lo=120, hud_default=(632,0,812,112), use_when=None):
    LL=json.load(open(fn)); w,h=LL['frame_dp']; sp=LL['spots']; pdy=LL.get('pad_dy',40); tap=round(base*130/140,1)
    ks=list(sp); md=min(math.dist(sp[a],sp[b]) for i,a in enumerate(ks) for b in ks[i+1:])
    hud=list(LL.get('hud',hud_default))
    return {'map':mapfile,'frame_dp':[w,h],'note':note,
      'places':{k:{'center_dp':[x,y],'center_fraction':[round(x/w,4),round(y/h,4)],'align':[round(2*x/w-1,4),round(2*y/h-1,4)],
                   'box_dp_at_scale_1':base,'tap_area':{'shape':'circle','diameter_dp_at_scale_1':tap,'diameter_fraction_of_frame_width':round(tap/w,4),'centre':'center_dp'}} for k,(x,y) in sp.items()},
      'guide_pad':{'who':'Fuzzle','pad_center_dp':[LL['guide'][0],LL['guide'][1]+pdy-6],'foot_center_dp':[LL['guide'][0],LL['guide'][1]+round(pdy*1.25)],
                   'pad_center_fraction':[round(LL['guide'][0]/w,4),round((LL['guide'][1]+pdy-6)/h,4)]},
      'hud_safe_zone_dp':{'rect_ltrb':hud,'rect_fraction':[round(hud[0]/w,4),round(hud[1]/h,4),round(hud[2]/w,4),round(hud[3]/h,4)],
                          'contents':'sound button 72 dp + parental-gate gear 44 dp, 24 dp margins; fixed dp, never scaled'},
      'min_center_distance_dp':round(md,1),'place_size':{'base_dp':base,'clamp_dp':[lo,200],'tap_diameter':'max(96, place * 130/140)' if lo<120 else 'place * 130/140'},
      **({'use_when':use_when} if use_when else {})}
m['map']['scaling_rule']={'map_scale':'s = max(screenW / frameW, screenH / frameH)  (BoxFit.cover)',
   'place_size_dp':'clamp(base * s, lo, 200): phone/tablet43 base 140, lo 120; phone_compact base 120, lo 100 (tap >= 96 dp, centres >= 104 dp apart, 72 dp minimum touch target holds)','place_position':'frame offset + center_dp * s (equivalently center_fraction of the drawn map rect)',
   'tap_area':'circle of 130/140 of the place size, centred','hud':'fixed dp, does not scale'}
m['map']['layouts']={'phone':layout('map_layout.json','map_island_morning.png','812 x 375 dp frame; 16:9 phones see the centred safe16x9 crop',use_when='screen height > 360 dp and width / height >= 1.7'),
                     'tablet43':layout('map_layout_tablet43.json','map_island_morning_tablet43.png','1024 x 768 dp frame for 4:3 tablets; same island redrawn with places spread vertically',hud_default=(844,0,1024,112),use_when='screen height > 360 dp and width / height < 1.7 (4:3 and 16:10 tablets)'),
                     'phone_compact':layout('map_layout_compact.json','map_island_morning_compact.png','640 x 360 dp frame (16:9) for small phones (568x320, 640x360): places at 120 dp nominal, lighthouse pulled inland, shadow + puzzle islets out at sea; v1.1: puzzle islet pulled in to (550,276) and shadow islet to (466,186) so all puzzle art incl. padlock badge stays >= 24 dp from right/bottom edges (20 dp gesture margin + 4 dp)',base=120,lo=100,use_when='screen height <= 360 dp (any width); checked at 568x320 (s 0.889: place 106.7 dp, tap 99 dp, min centre distance 109.4 dp; puzzle art margins right 29.1 / bottom 25.8 dp) and 640x360 (s 1: place 120, tap 111.4, distance 123.1; margins right 33.2 / bottom 29.0)')}
m['map']['layout_selection']='height <= 360 dp -> phone_compact; else width/height < 1.7 -> tablet43; else phone'
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
SI=json.load(open('shadow_iou_v2.json'))
NM=['fuzzle','pip','dottie','zib','bitsy']
POSE={'fuzzle':'giant hug: both arms stretched straight out (T shape), teal striped horns','pip':'waving: one arm straight up, one foot kicked out; single eye (cut out in the shadow)',
      'dottie':'giant pink-tipped paintbrush held up diagonally, other arm raised, one foot kicked; polka dots + single eye (cut out in the shadow)',
      'zib':'big golden magnifier held out to the side (clear glass, 40 % alpha: the shadow shows the ring), two curly antennae','bitsy':'tiny, hanging under one huge leaf parachute by its stem'}
m['shadows']={'version':'v2 (27/10, BUG-005 retest): colour pose illustrations + silhouettes built from their alpha',
  'intended_screen':'Shadow game slots (lib/features/shadows, _ShadowSlot): hidden state = shadow_<id>.png, revealed state = color/<id>.png (same frame, so the reveal lands exactly on the shadow)',
  'colour':'plum #3A1752, alpha 85 % (spec §7), transparent background, square, BoxFit.contain framing (same as the slot and tool/shadow_similarity.py)',
  'construction':'shadow alpha = colour illustration alpha (same crop, same 4 % padding, same resampling) minus holes: Pip eye, Dottie eye + polka dots, Zib lens glass. IoU(shadow, own colour alpha) = '+', '.join(f"{n} {SI['shadow_vs_own_colour'][n]}" for n in NM),
  'items':[{'id':n,'pose':POSE[n],
            'shadow':{'name':f'shadow_{n}.png','dp':[170,170],'master_512':f'shadows/512/shadow_{n}_512.png','files':files('shadows',f'shadow_{n}.png')},
            'color':{'name':f'{n}.png','dp':[170,170],'master_512':f'shadows/color/512/{n}_512.png','files':files('shadows/color',f'{n}.png'),
                     'note':'shadow-game pose of the brand character (same fur colour, face, horns); use in the shadow game instead of monsters/<id>.webp'},
            'display':'slot image area (slot side up to 170 dp)'} for n in NM],
  'iou':SI['pairs'],'iou_method':'own script _work/pipeline/pose_shadows.py: alpha > 50 %, same square framing; 512 px masters and 200 px contain (same method as tool/shadow_similarity.py)',
  'shadow_vs_colour_iou_512':SI['shadow_vs_colour']}
json.dump(m,open(f'{A}/manifest.json','w'),indent=2,ensure_ascii=False)
print(len(m['places']),len(m['icons']))
