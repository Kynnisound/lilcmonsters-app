"""Controle des images embarquees (passe 4 QA, « Could not decompress image »).

Pour chaque PNG, WebP ou JPEG des dossiers d'assets declares dans
pubspec.yaml (variantes 2.0x et 3.0x comprises) :
- signature du fichier conforme a l'extension ;
- dimensions (alerte au-dessus de 4096 px de cote) ;
- PNG : 8 bits par canal, non entrelace, pas d'APNG, pas de profil ICC
  (iCCP) autre que sRGB, mode RGB/RGBA/L/LA/P (jamais CMYK) ;
- WebP : ni anime, ni profil ICC ; sans perte et alpha signales
  (lisibles par Android 4.2.1 et plus, donc Android 7) ;
- decodage complet avec Pillow (et dwebp pour les WebP).

  python3 tool/check_images.py            # rapport, code 1 si probleme
  python3 tool/check_images.py --fix      # reencode les PNG fautifs
  python3 tool/check_images.py --json f   # rapport JSON

--fix ne touche qu'aux copies de assets/ (jamais a design/) : PNG RGBA
8 bits, non entrelace, sans profil ICC (converti en sRGB s'il y en a un).
"""
import io, json, os, re, struct, subprocess, sys, zlib

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
MAX_SIDE = 4096
EXTS = ('.png', '.webp', '.jpg', '.jpeg')


def asset_dirs():
    txt = open(os.path.join(ROOT, 'pubspec.yaml')).read()
    block = txt.split('\n  assets:\n', 1)[1].split('\n  fonts:', 1)[0]
    return [m.group(1) for m in re.finditer(r'^\s+- (assets/\S+/)\s*$', block, re.M)]


def files():
    out = []
    for d in asset_dirs():
        full = os.path.join(ROOT, d)
        if not os.path.isdir(full):
            continue
        cands = [os.path.join(full, f) for f in os.listdir(full)]
        # Variantes de resolution, embarquees d'office par Flutter.
        for sub in os.listdir(full):
            if re.fullmatch(r'\d+(\.\d+)?x', sub):
                s = os.path.join(full, sub)
                cands += [os.path.join(s, f) for f in os.listdir(s)]
        out += [c for c in cands if os.path.isfile(c) and c.lower().endswith(EXTS)]
    return sorted(set(os.path.normpath(f) for f in out))


def png_chunks(data):
    pos, chunks = 8, []
    while pos < len(data):
        n, = struct.unpack('>I', data[pos:pos + 4])
        typ = data[pos + 4:pos + 8].decode('latin1')
        body = data[pos + 8:pos + 8 + n]
        crc, = struct.unpack('>I', data[pos + 8 + n:pos + 12 + n])
        chunks.append((typ, body, zlib.crc32(data[pos + 4:pos + 8 + n]) == crc))
        pos += 12 + n
        if typ == 'IEND':
            break
    return chunks


def check_png(path, data, rep):
    from PIL import Image
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        rep['problems'].append('signature PNG absente')
        return
    chunks = png_chunks(data)
    w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', chunks[0][1])
    rep.update(width=w, height=h, bit_depth=bd, color_type=ct, interlace=il)
    if bd != 8:
        rep['problems'].append(f'{bd} bits par canal')
    if il:
        rep['problems'].append('entrelace (Adam7)')
    names = [c[0] for c in chunks]
    if 'acTL' in names:
        rep['problems'].append('APNG (anime)')
    if not all(c[2] for c in chunks):
        rep['problems'].append('CRC de bloc faux')
    if 'iCCP' in names:
        body = next(c[1] for c in chunks if c[0] == 'iCCP')
        name = body.split(b'\0', 1)[0].decode('latin1')
        rep['icc'] = name
        if 'srgb' not in name.lower():
            rep['problems'].append(f'profil ICC « {name} »')
    im = Image.open(io.BytesIO(data))
    rep['mode'] = im.mode
    if im.mode not in ('RGB', 'RGBA', 'L', 'LA', 'P'):
        rep['problems'].append(f'mode {im.mode}')
    im.load()  # decodage complet


def check_webp(path, data, rep):
    from PIL import Image
    if data[:4] != b'RIFF' or data[8:12] != b'WEBP':
        rep['problems'].append('signature WebP absente')
        return
    info = subprocess.run(['webpinfo', path], capture_output=True, text=True).stdout
    rep['lossless'] = 'Format: Lossless' in info
    rep['alpha'] = bool(re.search(r'Alpha: 1|Chunk ALPH', info))
    if re.search(r'Animation: 1|Chunk ANIM', info):
        rep['problems'].append('WebP anime')
    if re.search(r'ICCP: 1|Chunk ICCP', info):
        rep['problems'].append('profil ICC dans le WebP')
    im = Image.open(io.BytesIO(data))
    rep.update(width=im.width, height=im.height, mode=im.mode)
    if getattr(im, 'n_frames', 1) > 1:
        rep['problems'].append('plusieurs images')
    if 'icc_profile' in im.info:
        rep['problems'].append('profil ICC dans le WebP')
    im.load()
    d = subprocess.run(['dwebp', path, '-o', '/dev/null'], capture_output=True, text=True)
    if d.returncode:
        rep['problems'].append('dwebp : ' + d.stderr.strip()[-120:])


def check(path):
    rel = os.path.relpath(path, ROOT)
    rep = {'file': rel, 'bytes': os.path.getsize(path), 'problems': []}
    data = open(path, 'rb').read()
    try:
        ext = path.lower().rsplit('.', 1)[1]
        if ext == 'png':
            check_png(path, data, rep)
        elif ext == 'webp':
            check_webp(path, data, rep)
        else:
            from PIL import Image
            im = Image.open(io.BytesIO(data))
            rep.update(width=im.width, height=im.height, mode=im.mode)
            if im.mode == 'CMYK':
                rep['problems'].append('JPEG CMYK')
            im.load()
    except Exception as e:  # decodage impossible
        rep['problems'].append(f'decodage : {e}')
    if max(rep.get('width', 0), rep.get('height', 0)) > MAX_SIDE:
        rep['problems'].append(f'plus de {MAX_SIDE} px de cote')
    return rep


def fix_png(path):
    from PIL import Image, ImageCms
    im = Image.open(path)
    icc = im.info.get('icc_profile')
    if icc:
        src = ImageCms.ImageCmsProfile(io.BytesIO(icc))
        im = ImageCms.profileToProfile(im.convert('RGBA'), src,
                                       ImageCms.createProfile('sRGB'), outputMode='RGBA')
    im = im.convert('RGBA')
    if im.getextrema()[3] == (255, 255):
        pass  # opaque : RGBA garde quand meme (format unique demande)
    im.save(path, 'PNG', optimize=True)  # 8 bits, non entrelace, sans iCCP


def main():
    fix = '--fix' in sys.argv
    reps = [check(f) for f in files()]
    if fix:
        for r in reps:
            if r['problems'] and r['file'].endswith('.png'):
                assert not r['file'].startswith('design'), r['file']
                fix_png(os.path.join(ROOT, r['file']))
        reps = [check(f) for f in files()]
    bad = [r for r in reps if r['problems']]
    if '--json' in sys.argv:
        json.dump(reps, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)
    big = max(reps, key=lambda r: max(r.get('width', 0), r.get('height', 0)))
    print(f'{len(reps)} images ; plus grande : {big["file"]} '
          f'{big.get("width")}x{big.get("height")} ; '
          f'{sum(r["file"].endswith(".png") for r in reps)} PNG, '
          f'{sum(r["file"].endswith(".webp") for r in reps)} WebP '
          f'(dont {sum(bool(r.get("lossless")) for r in reps)} sans perte)')
    for r in bad:
        print('PROBLEME', r['file'], '; '.join(r['problems']))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
