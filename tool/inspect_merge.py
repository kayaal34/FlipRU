"""Badestrand CSV'leri ile Turkce sozluk kaynaklarinin ortusmesini olcer."""
import csv
import io
import json
import re
import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')
csv.field_size_limit(10**7)

CYR = re.compile(r'^[а-яё]+(?:[ -][а-яё]+)*$')

# --- Badestrand: vurgulu formlar + cekimler ---
bd = {}
for name, pos in [('nouns', 'noun'), ('verbs', 'verb'),
                  ('adjectives', 'adj'), ('others', 'other')]:
    with io.open(f'raw/bd_{name}.csv', encoding='utf-8', newline='') as f:
        for i, row in enumerate(csv.DictReader(f, delimiter='\t')):
            bare = (row.get('bare') or '').strip().lower()
            if not bare or not CYR.match(bare) or bare in bd:
                continue
            bd[bare] = {
                'pos': pos,
                'accented': (row.get('accented') or '').strip(),
                'rank': i,
                'forms': [
                    v.strip().lower().replace("'", '')
                    for k, v in row.items()
                    # DictReader fazla sutunlari liste olarak veriyor; atla.
                    if isinstance(v, str) and k not in (
                        'bare', 'accented', 'translations_en',
                        'translations_de', 'gender', 'partner',
                        'aspect') and v and CYR.match(
                        v.strip().lower().replace("'", '').split(',')[0])
                ],
            }
print('Badestrand benzersiz lemma:', len(bd))
by_pos = {}
for v in bd.values():
    by_pos[v['pos']] = by_pos.get(v['pos'], 0) + 1
print('  POS dagilimi:', by_pos)
print('  vurgu isaretli:', sum(1 for v in bd.values() if "'" in v['accented']))

# --- Wikdict (skor filtreli) ---
con = sqlite3.connect('raw/ru-tr.sqlite3')
wd_good, wd_all = {}, {}
for w, sense, trans, score, is_good in con.execute(
    'select written_rep, sense, trans_list, score, is_good from translation'
):
    if not w or not trans:
        continue
    w = w.strip().lower()
    if not CYR.match(w):
        continue
    sc = score or 0
    rec = (trans.strip(), sense or '', sc)
    wd_all.setdefault(w, []).append(rec)
    if is_good == 1 or sc >= 20:
        wd_good.setdefault(w, []).append(rec)
print('Wikdict lemma (tumu):', len(wd_all), '| skor filtreli:', len(wd_good))

# --- Kaikki trwiktionary ---
kk = {}
with io.open('raw/kaikki_ru_tr.jsonl', encoding='utf-8') as f:
    for line in f:
        d = json.loads(line)
        if d.get('pos') == 'name':
            continue
        w = d.get('word', '').strip().lower()
        if not CYR.match(w):
            continue
        gl = [g for s in d.get('senses', []) for g in (s.get('glosses') or [])]
        gl = [g for g in gl if len(g) <= 60]      # tanim degil, karsilik olsun
        if gl:
            kk.setdefault(w, gl)
print('Kaikki (kisa karsilikli):', len(kk))

tr_any = set(wd_all) | set(kk)
tr_good = set(wd_good) | set(kk)
print()
print('Turkce karsiligi olan lemma  (tumu):', len(tr_any))
print('Turkce karsiligi olan lemma (kaliteli):', len(tr_good))
print('Badestrand ∩ kaliteli-Turkce:', len(set(bd) & tr_good))
print('Badestrand ∩ tum-Turkce     :', len(set(bd) & tr_any))
print('Turkce var ama Badestrand yok:', len(tr_good - set(bd)))

# Frekans siralamasina gore kapsam
ranked = sorted(set(bd) & tr_good, key=lambda w: bd[w]['rank'])
print()
print('ilk 20 (frekans sirali) ortak lemma:')
for w in ranked[:20]:
    t = (wd_good.get(w) or [('', '', 0)])[0][0] or (kk.get(w) or [''])[0]
    print(f'  {bd[w]["accented"]:<16} {t[:44]}')
