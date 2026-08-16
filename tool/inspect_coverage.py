"""Sozluk kaynaklarinin sik kullanilan Rusca kelimelerdeki kapsamini olcer."""
import io
import json
import random
import re
import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

CYR = re.compile(r'^[а-яё]+(?:[ -][а-яё]+)*$')  # yalnizca kucuk harf: ozel isim degil

# --- Wikdict ---
con = sqlite3.connect('raw/ru-tr.sqlite3')
wikdict = {}
for w, t in con.execute('select written_rep, trans_list from simple_translation'):
    if not w or not t:
        continue
    w = w.strip()
    if CYR.match(w):
        wikdict.setdefault(w, t.strip())
print('Wikdict kucuk-harf (cins isim) girdi:', len(wikdict))

# --- Kaikki trwiktionary ---
kaikki = {}
with io.open('raw/kaikki_ru_tr.jsonl', encoding='utf-8') as f:
    for line in f:
        d = json.loads(line)
        if d.get('pos') == 'name':
            continue
        w = d.get('word', '').strip()
        if not CYR.match(w):
            continue
        glosses = []
        for s in d.get('senses', []):
            glosses += (s.get('glosses') or [])
        if glosses:
            kaikki.setdefault(w, glosses[0])
print('Kaikki cins isim girdi:', len(kaikki))

birlesim = set(wikdict) | set(kaikki)
print('BIRLESIM:', len(birlesim))
print('kesisim :', len(set(wikdict) & set(kaikki)))

# --- Frekans listesi ---
freq = []
with io.open('raw/ru_freq_full.txt', encoding='utf-8') as f:
    for line in f:
        parts = line.split()
        if len(parts) == 2 and CYR.match(parts[0]):
            freq.append(parts[0])
print('frekans listesi:', len(freq))

for n in (1000, 3000, 5000, 10000, 20000):
    top = freq[:n]
    hit = sum(1 for w in top if w in birlesim)
    print(f'  ilk {n:>5} sik kelimenin kapsami: {hit:>5} (%{100*hit/n:.1f})')

print()
print('=== SIK KULLANILAN KELIMELERDEN RASTGELE ORNEKLER ===')
covered = [w for w in freq[:6000] if w in birlesim]
random.seed(7)
for w in random.sample(covered, min(30, len(covered))):
    src = 'W' if w in wikdict else 'K'
    tr = wikdict.get(w) or kaikki.get(w)
    print(f'[{src}] {w:<18} -> {tr[:64]}')
