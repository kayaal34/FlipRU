# -*- coding: utf-8 -*-
"""B1 inceleme partilerini words.json'a uygular.

    python tool/b1_uygula.py tool/b1_parti1_fixes.py            # yalnızca kontrol
    python tool/b1_uygula.py tool/b1_parti1_fixes.py --uygula   # yaz

Her düzeltme {id: (beklenen_mevcut_tr, yeni_tr)}. Mevcut Türkçe beklenenle
birebir aynı değilse o satır atlanır ve raporlanır.
"""
import importlib.util
import io
import json
import os
import sys

PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'words.json')

spec = importlib.util.spec_from_file_location('fixes', sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
FIXES = mod.FIXES
UYGULA = '--uygula' in sys.argv

with io.open(PATH, encoding='utf-8') as fh:
    data = json.load(fh)
idx = {ad: i for i, ad in enumerate(data['fields'])}
rows = {r[idx['id']]: r for r in data['rows']}

uygulanan, atlanan = 0, []
for wid, (eski, yeni) in FIXES.items():
    row = rows.get(wid)
    if row is None:
        atlanan.append((wid, 'yok'))
        continue
    if row[idx['tr']] != eski:
        atlanan.append((wid, 'mevcut tr farklı: %r' % row[idx['tr']]))
        continue
    if UYGULA:
        row[idx['tr']] = yeni
    uygulanan += 1

print('düzeltme: %d | uygulanabilir: %d | atlanan: %d' % (len(FIXES), uygulanan, len(atlanan)))
for a in atlanan:
    print('  atlandı:', *a)

if UYGULA:
    with io.open(PATH, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(',', ':'))
    print('assets/data/words.json güncellendi')
