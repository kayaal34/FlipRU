"""Kelime listesini denetlenebilir biçimde disa aktarir.

Baska bir modele "bu cevirilerden hangileri yanlis?" diye sormak icin
kullaniliyor. Cikti tek bir CSV; ayrica seviyelere bolunmus parcalar da
yaziliyor cunku 9000 satir tek seferde bir modele sigmiyor.

Kullanim:
    python export_words.py

Cikti:
    export/words_all.csv      butun kelimeler
    export/words_guven2.csv   yalnizca tek kaynakla dogrulanmis katman
    export/words_a1.csv ...   seviye seviye
    export/review_NN_xx.txt   400'erlik parcalar, modele yapistirmaya hazir
"""

import csv
import io
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from curated_fixes import FIXES, POST_FIXES  # noqa: E402
from report_fixes import REPORT_TR  # noqa: E402
from report2_fixes import (  # noqa: E402
    REPORT2_EXAMPLE,
    REPORT2_TR,
    REPORT2_TRANSLIT,
)
from report3_fixes import REPORT3_EXTRA, REPORT3_TR  # noqa: E402
from report4_fixes import REPORT4_EXTRA, REPORT4_TR  # noqa: E402
from report5_fixes import (  # noqa: E402
    REPORT5_CLEAR_EXAMPLE,
    REPORT5_EXAMPLE,
    REPORT5_MANUAL,
    REPORT5_TR,
)

# Bes turda duzeltilmis kayitlarin kimlikleri.
DUZELTILEN = (set(REPORT_TR) | set(REPORT2_TR) | set(REPORT2_EXAMPLE)
              | set(REPORT2_TRANSLIT) | set(REPORT3_TR) | set(REPORT3_EXTRA)
              | set(REPORT4_TR) | set(REPORT4_EXTRA) | set(REPORT5_TR)
              | set(REPORT5_MANUAL) | set(REPORT5_EXAMPLE)
              | set(REPORT5_CLEAR_EXAMPLE))

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
    """Bu kelimeye dis incelemede dokunuldu mu?

    3., 4. ve 5. turlar dosyanin TAMAMINI tarayip yalnizca hatali bulduklarini
    listeledi. Dolayisiyla artik "incelenmedi" diye bir kume yok: bir kayit ya
    duzeltilmis, ya incelenip dogru bulunmustur.
    """
    if row[0] in DUZELTILEN or row[1] in FIXES or row[1] in POST_FIXES:
        return 'duzeltildi'
    return 'incelendi_dogru'


def main():
    payload = json.load(io.open(DATA, encoding='utf-8'))
    rows = [list(r) + [status(r)] for r in payload['rows']]
    os.makedirs(OUT, exist_ok=True)

    done = sum(1 for r in rows if r[-1] == 'duzeltildi')
    print(f'  {len(rows)} kelime · {done} duzeltildi · '
          f'{len(rows) - done} incelenip dogru bulundu\n')

    # 1) Tam CSV
    path = os.path.join(OUT, 'words_all.csv')
    with io.open(path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(rows)
    print(f'  {path}  ({len(rows)} kelime)')

    # 1b) Guven=2 katmani.
    #
    # Guven puani kelimenin kac bagimsiz sozlukte dogrulandigini gosteriyor.
    # Ilk turun raporu bu katmandaki hata oranini %55-70 diye tahmin etmisti;
    # bes tur sonunda gercek oran %55 cikti (2.596 kayittan 1.426'si
    # duzeltildi). Yeni bir inceleme turu yine once buraya bakmali.
    risky = [r for r in rows if r[10] == 2]
    path = os.path.join(OUT, 'words_guven2.csv')
    with io.open(path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(HEADER)
        writer.writerows(risky)
    print(f'  {path}  ({len(risky)} kelime)  <-- guven=2 katmani')

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
