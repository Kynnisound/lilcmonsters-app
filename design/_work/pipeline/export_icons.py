import icons, cairosvg, os
OUT='/workspace/seamonsters/design/assets/icons'
DP={'beach_shell':96,'cave_palette':96,'forest_magnifier':96,'library_book':96,'lighthouse_play':96,'islets_puzzle':96,'shadow_lantern':96,
    'sound_on':72,'sound_off':72,'parental_gate':44,'back':72,'home':72,'padlock':48,'padlock_badge':48}
os.makedirs(OUT+'/svg',exist_ok=True)
for n,dp in DP.items():
    svg=icons.svg_icon(n); open(f'{OUT}/svg/icon_{n}.svg','w').write(svg)
    for k,pre in [(1,''),(2,'2.0x/'),(3,'3.0x/')]:
        os.makedirs(f'{OUT}/{pre}',exist_ok=True)
        cairosvg.svg2png(bytestring=svg.encode(),write_to=f'{OUT}/{pre}icon_{n}.png',output_width=dp*k,output_height=dp*k)
print('ok')
