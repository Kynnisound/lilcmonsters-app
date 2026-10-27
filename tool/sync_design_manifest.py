"""Genere lib/core/content/design_map_layouts.g.dart depuis
design/assets/manifest.json (assets de travail de Margaux), sans modifier
design/. Copie aussi dans assets/images/map/ les images de carte referencees
(1x, 2.0x, 3.0x).

Usage : python3 tool/sync_design_manifest.py

Format v1.3 du manifeste : map.layouts.phone (obligatoire),
map.layouts.tablet43 et map.layouts.phone_compact (facultatives), chacune avec "map" (nom du fichier dans
map/), "frame_dp", "places"{id: {"center_dp"}}, "guide_pad"{"foot_center_dp"}
et "hud_safe_zone_dp"{"rect_ltrb"}. L'ancien format (map.spots) reste lu.
Regle d'echelle (manifeste "scaling_rule") : cover pur,
lieux = clamp(base x s, min, max) lus dans "place_size" de chaque
disposition (140 / 120 / 200 par defaut ; compacte : 120 / 100 / 200, tap
>= 96 dp), HUD en dp fixes. map.layout_selection est recopie en
commentaire et verifie (regle codee dans DesignArt.layoutFor).
"""
import json
import re
import os
import shutil

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
DESIGN = os.path.join(ROOT, 'design', 'assets')
OUT = os.path.join(ROOT, 'lib', 'core', 'content', 'design_map_layouts.g.dart')
PLACES = ('cave', 'forest', 'lighthouse', 'beach', 'library', 'shadow', 'islets')


def image_of(entry):
    if 'map' in entry:
        return 'map/' + entry['map']
    if 'file' in entry:
        return entry['file']
    return entry['variants'][0]['files']['1x']['file']


def normalise(entry):
    """Ramene une disposition (v1.2 ou v1) a : frame_dp, spots, foot, hud."""
    places = entry.get('places') or entry.get('spots')
    guide = entry.get('guide_pad') or entry.get('guide_spot') or {}
    hud = (entry.get('hud_safe_zone_dp') or {}).get('rect_ltrb')
    if hud is None:
        hud = next(iter(entry.get('ui_reserved_dp', {}).values()), None)
    w, h = entry['frame_dp']
    size = entry.get('place_size') or {}
    lo, hi = size.get('clamp_dp', [120, 200])
    tap = re.search(r'max\(\s*(\d+(?:\.\d+)?)', str(size.get('tap_diameter', '')))
    return dict(image=image_of(entry), frame=(w, h),
                base=size.get('base_dp', 140), lo=lo, hi=hi,
                min_tap=float(tap.group(1)) if tap else 0,
                spots={k: v['center_dp'] for k, v in places.items()},
                foot=guide.get('foot_center_dp'), hud=hud or [w, 0, w, 0])


def copy_map(rel):
    """Copie map/<nom> et ses variantes 2.0x/3.0x vers assets/images/map/."""
    head, name = os.path.split(rel)
    for v in ('', '2.0x', '3.0x'):
        src = os.path.join(DESIGN, head, v, name)
        if os.path.exists(src):
            dst = os.path.join(ROOT, 'assets', 'images', 'map', v, name)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(src, dst)
    return f'assets/images/map/{name}'


def num(v):
    return f'{float(v)}'


def dart_layout(entry):
    e = normalise(entry)
    w, h = e['frame']
    missing = [p for p in PLACES if p not in e['spots']]
    assert not missing, f'lieux absents du manifeste : {missing}'
    foot, hud, sp = e['foot'], e['hud'], e['spots']
    lines = [
        'MapLayout(',
        f"  image: '{copy_map(e['image'])}',",
        f'  frame: Size({num(w)}, {num(h)}),',
        '  spots: {',
        *[f"    '{p}': Offset({num(sp[p][0])}, {num(sp[p][1])})," for p in PLACES],
        '  },',
        f'  guideFoot: {f"Offset({num(foot[0])}, {num(foot[1])})" if foot else "null"},',
        f'  hud: Rect.fromLTRB({", ".join(num(v) for v in hud)}),',
        f"  placeBase: {num(e['base'])},",
        f"  placeMin: {num(e['lo'])},",
        f"  placeMax: {num(e['hi'])},",
        f"  minTap: {num(e['min_tap'])},",
        ')',
    ]
    return '\n'.join(lines)


def main():
    m = json.load(open(os.path.join(DESIGN, 'manifest.json'), encoding='utf-8'))
    layouts = m['map'].get('layouts')
    if layouts:
        phone, tablet = layouts['phone'], layouts.get('tablet43')
        compact = layouts.get('phone_compact')
    else:  # format v1 : map.spots, map.guide_spot, map.ui_reserved_dp
        phone = dict(m['map'], map=None)
        phone.pop('map')
        phone['places'] = m['map']['spots']
        phone['variants'] = [v for v in m['map']['variants'] if 'safe16x9' not in v['name']]
        tablet = m.get('tablet43') or m['map'].get('tablet43')
        compact = None
    selection = m['map'].get('layout_selection', '')
    expected = 'height <= 360 dp -> phone_compact; else width/height < 1.7 -> tablet43; else phone'
    if compact or selection:
        assert selection == expected, (
            f'layout_selection a change : {selection!r} ; mettre a jour '
            'DesignArt.layoutFor puis ce script')
    out = [
        '// GENERE par tool/sync_design_manifest.py depuis design/assets/manifest.json.',
        '// Ne pas modifier a la main : relancer le script.',
        '// ignore_for_file: unnecessary_nullable_for_final_variable_declarations',
        "import 'dart:ui';",
        '',
        "import 'design_art.dart';",
        '',
        '/// Carte telephone (manifest.json > map).',
        f'const designPhoneLayout = {dart_layout(phone)};',
        '',
        '/// Carte tablette 4:3 (manifest.json > map.layouts.tablet43). Nulle si',
        '/// absente du manifeste : la carte telephone sert alors partout.',
        'const MapLayout? designTablet43Layout = '
        + (dart_layout(tablet) if tablet else 'null') + ';',
        '',
        '/// Carte compacte des petits telephones (manifest.json >',
        '/// map.layouts.phone_compact). Nulle si absente.',
        f'/// Selection (manifest.json > map.layout_selection) : {selection}',
        'const MapLayout? designPhoneCompactLayout = '
        + (dart_layout(compact) if compact else 'null') + ';',
        '',
    ]
    open(OUT, 'w', encoding='utf-8').write('\n'.join(out))
    print('ecrit', os.path.relpath(OUT, ROOT), '| tablet43 :', 'oui' if tablet else 'absente',
          '| phone_compact :', 'oui' if compact else 'absente')


if __name__ == '__main__':
    main()
