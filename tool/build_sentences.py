"""Tatoeba ru-tr cumle ciftlerini cikarir -> raw/sentences_ru_tr.json"""
import bz2
import io
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')


def read_sentences(path):
    out = {}
    with bz2.open(path, 'rt', encoding='utf-8') as f:
        for line in f:
            parts = line.rstrip('\n').split('\t')
            if len(parts) >= 3:
                out[parts[0]] = parts[2]
    return out


def read_links(path):
    pairs = []
    with bz2.open(path, 'rt', encoding='utf-8') as f:
        for line in f:
            parts = line.rstrip('\n').split('\t')
            if len(parts) >= 2:
                pairs.append((parts[0], parts[1]))
    return pairs


ru = read_sentences('raw/rus_sentences.tsv.bz2')
tr = read_sentences('raw/tur_sentences.tsv.bz2')
links = read_links('raw/rus_tur_links.tsv.bz2')
print('rusca cumle:', len(ru), '| turkce cumle:', len(tr), '| baglanti:', len(links))

pairs = []
seen = set()
for a, b in links:
    # Baglanti dosyasi hangi yonde olursa olsun calissin.
    if a in ru and b in tr:
        r, t = ru[a], tr[b]
    elif b in ru and a in tr:
        r, t = ru[b], tr[a]
    else:
        continue
    key = (r, t)
    if key in seen:
        continue
    seen.add(key)
    pairs.append({'ru': r, 'tr': t})

print('eslesen ru-tr cift:', len(pairs))
print()
print('=== ORNEKLER ===')
for p in pairs[:8]:
    print(f'  {p["ru"][:60]}')
    print(f'  {p["tr"][:60]}')
    print()

with io.open('raw/sentences_ru_tr.json', 'w', encoding='utf-8') as f:
    json.dump(pairs, f, ensure_ascii=False)
print('yazildi: raw/sentences_ru_tr.json')
