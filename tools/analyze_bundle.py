with open('tools/downloads_bundle.js', 'r', encoding='utf-8') as f:
    js = f.read()

idx = js.find('t.createProductDownloadOrder = function')
if idx != -1:
    print(js[idx-800:idx])
