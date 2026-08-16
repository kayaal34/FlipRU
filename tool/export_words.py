"""Kelime listesini denetlenebilir biçimde disa aktarir.

Baska bir modele "bu cevirilerden hangileri yanlis?" diye sormak icin
kullaniliyor. Cikti tek bir CSV; ayrica seviyelere bolunmus parcalar da
yaziliyor cunku 9000 satir tek seferde bir modele sigmiyor.

Kullanim:
    python export_words.py

Cikti:
    export/words_all.csv      butun kelimeler
    export/words_a1.csv ...   seviye seviye
    export/review_b2.txt      "ru = tr" biçiminde, modele yapistirmaya hazir
"""

import csv
import io
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from curated_fixes import FIXES, POST_FIXES  # noqa: E402

try:
    from report_fixes import REPORT_TR
except ImportError:  # ilk tur, rapor henuz yok
    REPORT_TR = {}

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'data', 'words.json')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'export')

# Modele yapistirilacak parca basina kelime sayisi.
CHUNK = 400

HEADER = [
    'id', 'rusca', 'vurgulu', 'okunus', 'turkce', 'tur', 'seviye',
    'tema', 'ornek_ru', 'ornek_tr', 'guven', 'durum',
]


def status(row):
    """Bu kelime daha once elden gecti mi?

    Ikinci tur incelemede en degerli bilgi bu: 615 kayit zaten duzeltildi,
    inceleyen kisi enerjisini dokunulmamis olanlara ayirsin.
    """
    if row[0] in REPORT_TR or row[1] in FIXES or row[1] in POST_FIXES:
        return 'duzeltildi'
    return 'incelenmedi'


def main():
    payload = json.load(io.open(DATA, encoding='utf-8'))
    rows = [list(r) + [status(r)] for r in payload['rows']]
    os.makedirs(OUT, exist_ok=True)

    done = sum(1 for r in rows if r[-1] == 'duzeltildi')
    print(f'  {len(rows)} kelime · {done} duzeltildi · '
          f'{len(rows) - done} incelenmedi\n')

    # 1) Tam CSV
    path = os.path.join(OUT, 'words_all.csv')
    with io.open(path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(rows)
    print(f'  {path}  ({len(rows)} kelime)')

    # 1b) Yalnizca hic incelenmemis olanlar — ikinci turun asil hedefi
    fresh = [r for r in rows if r[-1] == 'incelenmedi']
    path = os.path.join(OUT, 'words_incelenmemis.csv')
    with io.open(path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(fresh)
    print(f'  {path}  ({len(fresh)} kelime)')

    # 2) Seviye seviye CSV
    by_level = {}
    for row in rows:
        by_level.setdefault(row[6], []).append(row)

    for level in ('a1', 'a2', 'b1', 'b2', 'c1'):
        subset = by_level.get(level, [])
        if not subset:
            continue
        path = os.path.join(OUT, f'words_{level}.csv')
        with io.open(path, 'w', encoding='utf-8-sig', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(HEADER)
            writer.writerows(subset)
        print(f'  {path}  ({len(subset)} kelime)')

    # 3) Modele yapistirmaya hazir sade metin parcalari
    prompt = (
        'Asagida bir Rusca-Turkce kelime ogrenme uygulamasinin sozlugu var.\n'
        'Bicim:  id | rusca kelime | mevcut turkce karsilik\n\n'
        'Gorevin: YANLIS, yaniltici, kaba/mustehcen ya da anlami tutmayan '
        'karsiliklari bulmak.\n\n'
        'Kurallar:\n'
        '  1. Yalnizca hatali satirlari yaz, dogru olanlari hic yazma.\n'
        '  2. Onerdigin karsilik EN FAZLA IKI ANLAM icersin '
        '(virgulle ayrilmis).\n'
        '  3. Kelimenin en yaygin/temel anlamini ilk siraya koy.\n'
        '  4. Uzun aciklama yazma; parantez kullanacaksan kisa tut.\n\n'
        'Cikti bicimi (her satir bir hata):\n'
        '  id | rusca kelime | dogru turkce karsilik\n\n'
        'Ornek:\n'
        '  w00401 | провести | geçirmek (vakit), yürütmek\n\n'
        '─────────────────────────────────────────\n\n'
    )
    index = 0
    for level in ('a1', 'a2', 'b1', 'b2', 'c1'):
        subset = by_level.get(level, [])
        for start in range(0, len(subset), CHUNK):
            index += 1
            part = subset[start:start + CHUNK]
            path = os.path.join(OUT, f'review_{index:02d}_{level}.txt')
            with io.open(path, 'w', encoding='utf-8') as f:
                f.write(prompt)
                for row in part:
                    f.write(f'{row[0]} | {row[1]} | {row[4]}\n')
            print(f'  {path}  ({len(part)} satir)')

    print()
    print('Duzeltmeleri geri verirken bicim (Excel ya da duz metin):')
    print('  w00401 | провести | geçirmek (vakit), yürütmek')
    print('Excel gonderirsen ID / Rusça / Önerilen sutunlari yeterli.')


if __name__ == '__main__':
    main()
