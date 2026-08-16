"""Uretilen veri setinin zayif noktalarini bulur.

Amac: "hangi kayitlar sacma?" sorusuna sayiyla cevap vermek ve build_dataset'e
hangi filtreleri eklemek gerektigini gostermek.
"""

import io
import json
import os
import random
import re
import sys
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'data', 'words.json')

payload = json.load(io.open(DATA, encoding='utf-8'))
F = {name: i for i, name in enumerate(payload['fields'])}
rows = payload['rows']
print(f'toplam kayit: {len(rows)}\n')

WORD_RE = re.compile(r'[а-яё]+')
LATIN = re.compile(r'^[a-z\s\'-]+$')

# Cok yaygin Ingilizce kelimeler: cevrilmeden kalmis olabilir.
EN_STOP = set('''the of and to in a is that it for on with as by at from be this
are was were or an not but have has had they you we he she his her its their
our your can will would could should may might must do does did done make made
get got go went come came take took see saw know knew think thought say said
one two three time year day man woman people thing way life work part place
case week point government company number group problem fact good new first
last long great little own other old right big high different small large next
early young important few public bad same able'''.split())

issues = defaultdict(list)

for r in rows:
    ru = r[F['ru']]
    tr = r[F['tr']]
    ex_ru = r[F['exRu']]
    ex_tr = r[F['exTr']]
    conf = r[F['conf']]
    translit = r[F['translit']]

    first = tr.split(',')[0].strip()

    # 1) Cevrilmemis Ingilizce kalinti
    if LATIN.match(first) and first in EN_STOP:
        issues['ingilizce_kalinti'].append((ru, tr))

    # 2) Turkce karsilik cok kisa / anlamsiz
    if len(first) <= 2:
        issues['cok_kisa_karsilik'].append((ru, tr))

    # 3) Karsilik okunusun kendisi (ceviri degil, translit sizmis)
    if first.replace('-', '').lower() == translit.replace('-', '').lower():
        issues['karsilik_translit'].append((ru, tr))

    # 4) Ornek cumle lemmayi icermiyor olabilir (kok bazli kaba kontrol)
    if ex_ru:
        stem = ru[:max(4, len(ru) - 3)]
        if stem and stem not in ex_ru.lower():
            issues['ornek_kelimeyi_icermiyor'].append((ru, ex_ru[:60]))

    # 5) Ornek cumle cok kisa ya da ceviri oransiz
    if ex_ru and ex_tr:
        if len(ex_tr) < 10:
            issues['ornek_ceviri_cok_kisa'].append((ru, ex_ru[:40], ex_tr))
        ratio = len(ex_tr) / max(len(ex_ru), 1)
        if ratio < 0.35 or ratio > 2.6:
            issues['ornek_oransiz'].append((ru, ex_ru[:40], ex_tr[:40]))

    # 6) Ornek cumlede diyalog/altyazi artigi
    if ex_ru and (ex_ru.startswith('-') or ex_ru.startswith('—')
                  or '..' in ex_ru or ex_tr.startswith('-')):
        issues['altyazi_artigi'].append((ru, ex_ru[:50], ex_tr[:40]))

    # 7) Ayni Turkce karsilik cok fazla kelimede
    # (asagida toplu sayilacak)

print('═══ SORUN SAYILARI ═══')
for key in sorted(issues, key=lambda k: -len(issues[k])):
    print(f'  {key:<26} {len(issues[key]):>6}')

# Ayni karsiligi paylasan kelimeler
by_tr = Counter(r[F['tr']].split(',')[0].strip() for r in rows)
print('\n═══ EN COK TEKRARLANAN KARSILIKLAR ═══')
for term, n in by_tr.most_common(12):
    print(f'  {term:<24} {n} kelimede')

# Guven duzeyine gore dagilim
print('\n═══ GUVEN x ORNEK ═══')
conf_stats = defaultdict(lambda: [0, 0])
for r in rows:
    c = r[F['conf']]
    conf_stats[c][0] += 1
    if r[F['exRu']]:
        conf_stats[c][1] += 1
for c in sorted(conf_stats):
    total, withex = conf_stats[c]
    print(f'  conf={c}: {total:>6} kayit, {withex:>6} ornekli (%{100*withex/total:.0f})')

# Seviye bazli sorun yogunlugu
print('\n═══ SEVIYEYE GORE SORUNLU ORANI ═══')
flagged = set()
for key in ('ingilizce_kalinti', 'cok_kisa_karsilik', 'karsilik_translit'):
    for item in issues[key]:
        flagged.add(item[0])
by_level = Counter(r[F['level']] for r in rows)
lvl_flagged = Counter(r[F['level']] for r in rows if r[F['ru']] in flagged)
for lvl in ('a1', 'a2', 'b1', 'b2', 'c1'):
    tot = by_level[lvl]
    bad = lvl_flagged[lvl]
    print(f'  {lvl.upper()}: {bad:>4} / {tot:>5} (%{100*bad/max(tot,1):.1f})')

print('\n═══ ORNEKLER ═══')
random.seed(3)
for key in sorted(issues, key=lambda k: -len(issues[k])):
    sample = issues[key]
    if not sample:
        continue
    print(f'\n-- {key} ({len(sample)}) --')
    for item in random.sample(sample, min(6, len(sample))):
        print('   ', ' | '.join(str(x) for x in item))
