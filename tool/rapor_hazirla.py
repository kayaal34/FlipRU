# -*- coding: utf-8 -*-
"""Karar dosyasından (rapor_gN_karar.py) uygulanabilir düzeltme dosyası üretir.

Karar dosyası yalnızca yeni değerleri taşır; "beklenen" değerler raporun
kendi sütunlarından (mevcut çeviri, örnek) doldurulur. Böylece rapor ile
disk arasında bir kayma varsa uygulama satırı atlar.

    python tool/rapor_hazirla.py 1 "C:/Masaüstü/kelime_raporu.xlsx"

Karar dosyasında: TR = {id: yeni_tr}, EXTR = {id: yeni_exTr},
EXDROP = [id, ...], DROP = [id, ...]
"""
import importlib.util
import io
import os
import sys

import openpyxl

grup = int(sys.argv[1])
xlsx = sys.argv[2]
here = os.path.dirname(__file__)

spec = importlib.util.spec_from_file_location(
    'karar', os.path.join(here, 'rapor_g%d_karar.py' % grup))
karar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(karar)
TR = getattr(karar, 'TR', {})
EXTR = getattr(karar, 'EXTR', {})
EXDROP = getattr(karar, 'EXDROP', [])
DROP = getattr(karar, 'DROP', [])
FIELDS = getattr(karar, 'FIELDS', {})
POS = getattr(karar, 'POS', {})

ws = openpyxl.load_workbook(xlsx)['Grup %d' % grup]
rapor = {}
for r in ws.iter_rows(min_row=2, values_only=True):
    _, wid, ru, cur, sev, kod, oneri, note, exru, extr = r
    rapor[wid] = {'ru': ru, 'tr': cur, 'exru': exru, 'extr': extr}

eksik = [w for w in [*TR, *EXTR, *EXDROP, *DROP] if w not in rapor]
if eksik:
    sys.exit('raporda olmayan kimlikler: %s' % eksik)

out = ['# -*- coding: utf-8 -*-', '"""Dış inceleme raporu, grup %d."""' % grup, '']
out.append('FIXES = {')
for w, yeni in TR.items():
    out.append('    %r: (%r, %r),' % (w, rapor[w]['tr'], yeni))
out.append('}\n')
out.append('EXTR = {')
for w, yeni in EXTR.items():
    out.append('    %r: (%r, %r),' % (w, rapor[w]['extr'], yeni))
out.append('}\n')
out.append('EXDROP = {')
for w in EXDROP:
    out.append('    %r: %r,' % (w, rapor[w]['exru']))
out.append('}\n')
out.append('DROP = {')
for w in DROP:
    out.append('    %r: %r,' % (w, rapor[w]['ru']))
out.append('}\n')
out.append('FIELDS = %r\n' % (FIELDS,))
out.append('POS = %r\n' % (POS,))
path = os.path.join(here, 'rapor_g%d_fixes.py' % grup)
io.open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('yazıldı:', path, '| tr %d, exTr %d, örnek silme %d, silme %d' % (
    len(TR), len(EXTR), len(EXDROP), len(DROP)))
