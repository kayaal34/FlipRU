# -*- coding: utf-8 -*-
"""Dış inceleme raporunun gruplarını words.json'a uygular.

    python tool/rapor_uygula.py tool/rapor_g1_fixes.py            # kontrol
    python tool/rapor_uygula.py tool/rapor_g1_fixes.py --uygula   # yaz

Grup dosyasında olabilecekler:
    FIXES  = {id: (beklenen_tr, yeni_tr)}          # okunuş da yeniden üretilir
    EXTR   = {id: (beklenen_exTr, yeni_exTr)}      # örnek çevirisi
    EXDROP = {id: beklenen_exRu}                   # yanlış örneği kaldır
    DROP   = {id: beklenen_ru}                     # kaydı sil
    POS    = {id: (beklenen_pos, yeni_pos)}
    FIELDS = {id: {alan: (beklenen, yeni)}}        # accented / translit / exRu

Beklenen değer diskteki değerle birebir aynı değilse o satıra dokunulmaz ve
raporlanır: kimlik kayması ya da araya giren bir düzenleme veriyi bozmasın.
"""
import importlib.util
import io
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from tr_translit import translit_phrase as cevir  # noqa: E402

PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'words.json')
GECERLI_POS = {'noun', 'verb', 'adj', 'other'}
IZINLI_ALAN = {'ru', 'accented', 'translit', 'exRu'}

spec = importlib.util.spec_from_file_location('fixes', sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
FIXES = getattr(mod, 'FIXES', {})
EXTR = getattr(mod, 'EXTR', {})
EXDROP = getattr(mod, 'EXDROP', {})
DROP = getattr(mod, 'DROP', {})
POS = getattr(mod, 'POS', {})
FIELDS = getattr(mod, 'FIELDS', {})
UYGULA = '--uygula' in sys.argv

with io.open(PATH, encoding='utf-8-sig') as fh:
    data = json.load(fh)
idx = {ad: i for i, ad in enumerate(data['fields'])}
rows = {r[idx['id']]: r for r in data['rows']}
atlanan = []
sayac = {'tr': 0, 'exTr': 0, 'exSil': 0, 'pos': 0, 'alan': 0}


def bare(s):
    return s.replace('́', '')


def degistir(tur, tablo, alan, ozel=None):
    for wid, (eski, yeni) in tablo.items():
        row = rows.get(wid)
        if row is None:
            atlanan.append((wid, tur, 'kayıt yok'))
        elif row[idx[alan]] != eski:
            atlanan.append((wid, tur, 'mevcut: %r' % row[idx[alan]]))
        else:
            sayac[tur] += 1
            if UYGULA:
                row[idx[alan]] = yeni
                if ozel:
                    ozel(row, yeni)


def tr_yan(row, yeni):
    # Okunuş çevirinin ilk anlamından türetiliyor; eskisi yanlış kalmasın.
    row[idx['trTranslit']] = cevir(yeni)


degistir('tr', FIXES, 'tr', tr_yan)
degistir('exTr', EXTR, 'exTr')

for wid, eski in EXDROP.items():
    row = rows.get(wid)
    if row is None:
        atlanan.append((wid, 'exSil', 'kayıt yok'))
    elif row[idx['exRu']] != eski:
        atlanan.append((wid, 'exSil', 'mevcut: %r' % row[idx['exRu']]))
    else:
        sayac['exSil'] += 1
        if UYGULA:
            row[idx['exRu']] = ''
            row[idx['exTr']] = ''

for wid, (eski, yeni) in POS.items():
    row = rows.get(wid)
    if yeni not in GECERLI_POS:
        atlanan.append((wid, 'pos', 'geçersiz tür %r' % yeni))
    elif row is None:
        atlanan.append((wid, 'pos', 'kayıt yok'))
    elif row[idx['pos']] != eski:
        atlanan.append((wid, 'pos', 'mevcut: %r' % row[idx['pos']]))
    else:
        sayac['pos'] += 1
        if UYGULA:
            row[idx['pos']] = yeni

for wid, degisim in FIELDS.items():
    row = rows.get(wid)
    for alan, (eski, yeni) in degisim.items():
        if alan not in IZINLI_ALAN:
            atlanan.append((wid, alan, 'bu alan değiştirilemez'))
        elif row is None:
            atlanan.append((wid, alan, 'kayıt yok'))
        elif row[idx[alan]] != eski:
            atlanan.append((wid, alan, 'mevcut: %r' % row[idx[alan]]))
        else:
            sayac['alan'] += 1
            if UYGULA:
                row[idx[alan]] = yeni

silinecek = set()
for wid, ru in DROP.items():
    row = rows.get(wid)
    if row is None:
        atlanan.append((wid, 'sil', 'kayıt yok (zaten silinmiş olabilir)'))
    elif bare(row[idx['ru']]).lower() != bare(ru).lower():
        atlanan.append((wid, 'sil', 'Rusça tutmuyor: %r' % row[idx['ru']]))
    else:
        silinecek.add(wid)

print('tr: %d/%d | örnek çevirisi: %d/%d | örnek silme: %d/%d | tür: %d/%d | '
      'alan: %d | silme: %d/%d | atlanan: %d' % (
          sayac['tr'], len(FIXES), sayac['exTr'], len(EXTR), sayac['exSil'],
          len(EXDROP), sayac['pos'], len(POS), sayac['alan'], len(silinecek),
          len(DROP), len(atlanan)))
for a in atlanan:
    print('  atlandı:', *a)

if UYGULA:
    once = len(data['rows'])
    data['rows'] = [r for r in data['rows'] if r[idx['id']] not in silinecek]
    with io.open(PATH, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(',', ':'))
    print('assets/data/words.json güncellendi: %d -> %d kelime' % (once, len(data['rows'])))
