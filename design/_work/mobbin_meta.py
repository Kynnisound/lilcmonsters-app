import sys,re,html,json,urllib.request
def get(u):
    r=urllib.request.Request(u,headers={'User-Agent':'Mozilla/5.0'})
    return urllib.request.urlopen(r,timeout=30).read().decode('utf8','ignore')
out=[]
for u in sys.argv[1:]:
    try:
        h=get(u)
    except Exception as e:
        print(json.dumps({'url':u,'err':str(e)}));continue
    t=re.search(r'<meta property="og:title" content="([^"]+)"',h)
    d=re.search(r'<meta name="description" content="([^"]+)"',h)
    og=re.search(r'<meta property="og:image" content="([^"]+)"',h)
    img=None
    if og:
        q=html.unescape(og.group(1))
        m=re.search(r'screenUrl=([^&]+)',q)
        if m:
            img=urllib.parse.unquote(m.group(1))
    h2=re.search(r'<h2[^>]*>([^<]+)</h2>',h)
    print(json.dumps({'url':u,'title':html.unescape(t.group(1)).split(' | ')[0] if t else None,'h2':html.unescape(h2.group(1)) if h2 else None,'img':img}))
