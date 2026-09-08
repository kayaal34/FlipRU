# -*- coding: utf-8 -*-
"""Turkce kelimelerin Kiril harfleriyle okunusunu uretir.

Rusca arayuzlu kullanici Turkce kelimeyi gorunce nasil okunacagini
bilmiyor; Rusca kelimelerdeki `translit` alaninin aynasi bu.

Turkce fonetik oldugu icin donusum neredeyse birebir harf esleme:
her harf tek bir sesi karsiliyor, Rusca'daki gibi vurguya bagli
sesli indirgemesi yok. Elle yazmak yerine burada uretiliyor.

Kullanim:  python tool/tr_translit.py [--dry]
"""
import io
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, 'assets', 'data', 'words.json')

VOWELS = set('aeıioöuü')

# Tek harfin karsiligi. y ve yumusak sesliler ayrica ele aliniyor.
SIMPLE = {
    'a': 'а', 'b': 'б', 'c': 'дж', 'ç': 'ч', 'd': 'д',
    'f': 'ф', 'g': 'г', 'h': 'х', 'ı': 'ы', 'i': 'и',
    'j': 'ж', 'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н',
    'o': 'о', 'p': 'п', 'r': 'р', 's': 'с', 'ş': 'ш',
    't': 'т', 'u': 'у', 'v': 'в', 'z': 'з',
    # Turkce'de olmayan ama alintilarda gecen harfler
    'q': 'к', 'w': 'в', 'x': 'кс',
}

# y + sesli: Rusca'nin kendi yumusak seslileriyle yaziliyor ki
# okuyan doğal olarak "йа" degil "я" desin. я/е/ё/ю zaten y sesini
# tasidigi icin ayrica "й" eklenmiyor.
Y_PAIRS = {
    'a': 'я', 'e': 'е', 'o': 'ё', 'u': 'ю',
    'ö': 'ё', 'ü': 'ю',
    # Rusca'da "yı" ve "yi" icin tek harf yok.
    'ı': 'йы', 'i': 'йи',
}

# Turkce'nin kendi buyuk/kucuk esleri: 'İ'.lower() Python'da iki
# karakterlik bir dizi uretiyor, once burada duzeltiliyor.
TR_LOWER = {'İ': 'i', 'I': 'ı'}


def _low(ch):
    return TR_LOWER.get(ch) or ch.lower()


# Uzatmada yalniz sesli tekrarlanir: "yağmur"da onceki harf "я" olsa da
# uzayan ses "а"dir, "яя" degil "яа" yazilmali.
PLAIN_VOWEL = {
    'a': 'а', 'e': 'е', 'ı': 'ы', 'i': 'и',
    'o': 'о', 'ö': 'ё', 'u': 'у', 'ü': 'ю',
}


def translit_word(word):
    out = []
    last_vowel = ''
    i = 0
    n = len(word)
    while i < n:
        ch = word[i]
        low = _low(ch)
        prev = _low(word[i - 1]) if i > 0 else ''
        at_start = i == 0 or not prev.isalpha()

        if low == 'y':
            nxt = _low(word[i + 1]) if i + 1 < n else ''
            if nxt in Y_PAIRS:
                out.append(Y_PAIRS[nxt])
                last_vowel = PLAIN_VOWEL[nxt]
                i += 2
                continue
            out.append('й')
        elif low == 'e':
            # Kelime basinda "э" (sertlestirmez), sonrasinda "е".
            last_vowel = 'э' if at_start else 'е'
            out.append(last_vowel)
        elif low == 'ö':
            # Rusca'da bagimsiz "ö" yok: unsuzden sonra "ё" dogru sesi
            # veriyor, kelime basinda "о" daha yakin duruyor.
            last_vowel = 'о' if at_start else 'ё'
            out.append(last_vowel)
        elif low == 'ü':
            last_vowel = 'у' if at_start else 'ю'
            out.append(last_vowel)
        elif low == 'ğ':
            # Kendi sesi yok. Iki sesli arasindaysa sadece dusuyor
            # (ağaç -> аач, soğuk -> соук); sonu ya da unsuz oncesiyse
            # onundeki sesliyi uzatiyor (dağ -> даа, sağlık -> саалык).
            nxt = _low(word[i + 1]) if i + 1 < n else ''
            if last_vowel and prev in VOWELS and nxt not in VOWELS:
                out.append(last_vowel)
        elif low in SIMPLE:
            if low in PLAIN_VOWEL:
                last_vowel = SIMPLE[low]
            out.append(SIMPLE[low])
        else:
            # Bosluk, tire, kesme isareti vb. oldugu gibi kalir.
            out.append(ch)
        i += 1
    return ''.join(out)


def translit_phrase(text):
    """Parantezli aciklamalari disarida birakip yalniz kelimeyi cevirir."""
    # "cilt (kitap)" gibi kayitlarda yalniz bas kismi okunur.
    head = text.split('(')[0].strip()
    head = head.split(',')[0].strip()
    if not head:
        return ''
    return translit_word(head)


def main():
    dry = '--dry' in sys.argv

    with io.open(PATH, encoding='utf-8') as fh:
        data = json.load(fh)

    fields = data['fields']
    rows = data['rows']

    if 'trTranslit' in fields:
        idx = fields.index('trTranslit')
        added = False
    else:
        fields.append('trTranslit')
        idx = len(fields) - 1
        added = True

    tr_idx = fields.index('tr')
    changed = 0
    samples = []

    for row in rows:
        if added:
            row.append('')
        value = translit_phrase(row[tr_idx])
        if row[idx] != value:
            row[idx] = value
            changed += 1
        if len(samples) < 25 and value:
            samples.append((row[tr_idx], value))

    print('alan eklendi     :', added)
    print('yazilan okunus   :', changed)
    print('toplam kelime    :', len(rows))
    print('\nornekler:')
    for tr, cyr in samples:
        print('  %-28s %s' % (tr, cyr))

    if dry:
        print('\n(kuru calisma, dosya yazilmadi)')
        return

    with io.open(PATH, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(',', ':'))
    print('\nassets/data/words.json guncellendi')


if __name__ == '__main__':
    main()
