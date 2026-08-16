"""Wikdict ru-tr verisinin kalitesini olcer."""
import re
import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

con = sqlite3.connect('raw/ru-tr.sqlite3')

CYR = re.compile(r'^[а-яёА-ЯЁ]+(?:[ -][а-яёА-ЯЁ]+)*$')
TR = re.compile(r'^[a-zçğıöşüâîûA-ZÇĞİÖŞÜ]+(?:[ ,\-\'][a-zçğıöşüâîûA-ZÇĞİÖŞÜ]+)*$')

rows = con.execute(
    'select written_rep, trans_list, max_score, rel_importance '
    'from simple_translation'
).fetchall()
print('toplam:', len(rows))

clean_ru = 0
clean_both = 0
samples = []
for w, t, score, imp in rows:
    if not w or not t:
        continue
    if CYR.match(w.strip()):
        clean_ru += 1
        first = t.split('|')[0].split(',')[0].strip()
        if TR.match(first):
            clean_both += 1
            if len(samples) < 400:
                samples.append((w.strip(), t.strip(), score, imp))

print('kiril-temiz rusca:', clean_ru)
print('her iki taraf temiz:', clean_both)
print()
print('=== ORNEKLER (her 15. kayit) ===')
for s in samples[::15][:26]:
    print(f'{s[0]:<22} -> {s[1][:60]:<60} score={s[2]} imp={s[3]}')
