# -*- coding: utf-8 -*-
"""B1 inceleme partilerini words.json'a uygular.

    python tool/b1_uygula.py tool/b1_parti2_fixes.py            # yalnızca kontrol
    python tool/b1_uygula.py tool/b1_parti2_fixes.py --uygula   # yaz

Parti dosyasında şunlar olabilir:
    FIXES = {id: (beklenen_mevcut_tr, yeni_tr)}
    DROP  = {id: beklenen_ru}          # silinecek kayıtlar
    POS   = {id: (beklenen_pos, yeni_pos)}

Beklenen değer diskteki değerle birebir aynı değilse o satıra dokunulmaz
ve raporlanır: kimlik kayması ya da araya giren bir düzenleme veriyi
bozmasın.
"""
import importlib.util
import io
import json
import os
import sys

PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'words.json')
GECERLI_POS = {'noun', 'verb', 'adj', 'other'}  # PartOfSpeech.byKey

spec = importlib.util.spec_from_file_location('fixes', sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
FIXES = getattr(mod, 'FIXES', {})
DROP = getattr(mod, 'DROP', {})
POS = getattr(mod, 'POS', {})
UYGULA = '--uygula' in sys.argv

with io.open(PATH, encoding='utf-8') as fh:
    data = json.load(fh)
idx = {ad: i for i, ad in enumerate(data['fields'])}
rows = {r[idx['id']]: r for r in data['rows']}
atlanan = []


def bare(s):
    return s.replace('́', '')


tr_ok = 0
for wid, (eski, yeni) in FIXES.items():
    row = rows.get(wid)
    if row is None:
        atlanan.append((wid, 'tr', 'kayıt yok'))
    elif row[idx['tr']] != eski:
        atlanan.append((wid, 'tr', 'mevcut: %r' % row[idx['tr']]))
    else:
        tr_ok += 1
        if UYGULA:
            row[idx['tr']] = yeni

pos_ok = 0
for wid, (eski, yeni) in POS.items():
    row = rows.get(wid)
    if yeni not in GECERLI_POS:
        atlanan.append((wid, 'pos', 'geçersiz tür %r' % yeni))
    elif row is None:
        atlanan.append((wid, 'pos', 'kayıt yok'))
    elif row[idx['pos']] != eski:
        atlanan.append((wid, 'pos', 'mevcut: %r' % row[idx['pos']]))
    else:
        pos_ok += 1
        if UYGULA:
            row[idx['pos']] = yeni

# FIELDS: {id: {alan: (beklenen, yeni)}} — vurgu ve okunuş gibi, tr dışında
# elle düzeltilmesi gereken alanlar. Yalnızca izin verilen alanlar.
IZINLI_ALAN = {'accented', 'translit'}
alan_ok = 0
for wid, degisim in getattr(mod, 'FIELDS', {}).items():
    row = rows.get(wid)
    for alan, (eski, yeni) in degisim.items():
        if alan not in IZINLI_ALAN:
            atlanan.append((wid, alan, 'bu alan değiştirilemez'))
        elif row is None:
            atlanan.append((wid, alan, 'kayıt yok'))
        elif row[idx[alan]] != eski:
            atlanan.append((wid, alan, 'mevcut: %r' % row[idx[alan]]))
        else:
            alan_ok += 1
            if UYGULA:
                row[idx[alan]] = yeni
if alan_ok:
    print('diğer alan düzeltmesi: %d' % alan_ok)

silinecek = set()
for wid, ru in DROP.items():
    row = rows.get(wid)
    if row is None:
        atlanan.append((wid, 'sil', 'kayıt yok (zaten silinmiş olabilir)'))
    elif bare(row[idx['ru']]) != bare(ru):
        atlanan.append((wid, 'sil', 'Rusça tutmuyor: %r' % row[idx['ru']]))
    else:
        silinecek.add(wid)

print('tr: %d/%d | tür: %d/%d | silme: %d/%d | atlanan: %d' % (
    tr_ok, len(FIXES), pos_ok, len(POS), len(silinecek), len(DROP), len(atlanan)))
for a in atlanan:
    print('  atlandı:', *a)

if UYGULA:
    once = len(data['rows'])
    data['rows'] = [r for r in data['rows'] if r[idx['id']] not in silinecek]
    with io.open(PATH, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(',', ':'))
    print('assets/data/words.json güncellendi: %d -> %d kelime' % (once, len(data['rows'])))
