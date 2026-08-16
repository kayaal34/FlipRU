"""Wikdict score/is_good/importance filtrelemesinin kaliteyi nasil etkiledigini olcer."""
import io
import random
import re
import sqlite3
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

CYR = re.compile(r'^[а-яё]+(?:[ -][а-яё]+)*$')
con = sqlite3.connect('raw/ru-tr.sqlite3')

rows = con.execute(
    'select written_rep, sense, trans_list, score, is_good, importance '
    'from translation'
).fetchall()
rows = [r for r in rows if r[0] and CYR.match(r[0].strip()) and r[2]]
print('cins-isim satir:', len(rows))

print('is_good dagilimi:', Counter(r[4] for r in rows).most_common())
buckets = Counter()
for r in rows:
    s = r[3] or 0
    if s >= 100:
        buckets['>=100'] += 1
    elif s >= 20:
        buckets['20-99'] += 1
    elif s >= 2:
        buckets['2-19'] += 1
    else:
        buckets['<2'] += 1
print('score dagilimi:', buckets.most_common())

# Frekans siralamasi (basit: kelimenin kendi yuzey formu)
rank = {}
with io.open('raw/ru_freq_full.txt', encoding='utf-8') as f:
    for i, line in enumerate(f):
        p = line.split()
        if len(p) == 2 and p[0] not in rank:
            rank[p[0]] = i

random.seed(11)
for label, pred in [
    ('is_good=1', lambda r: r[4] == 1),
    ('score>=100', lambda r: (r[3] or 0) >= 100),
    ('score>=20', lambda r: (r[3] or 0) >= 20),
    ('score<2', lambda r: (r[3] or 0) < 2),
]:
    sub = [r for r in rows if pred(r) and rank.get(r[0].strip(), 10**9) < 15000]
    print()
    print(f'=== {label} — sik kelimelerden {len(sub)} satir ===')
    for r in random.sample(sub, min(14, len(sub))):
        sense = (r[1] or '')[:26]
        print(f'  {r[0]:<16} -> {r[2][:44]:<44} [{sense}] score={r[3]}')
