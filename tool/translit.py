"""Rusca -> Turkce okunus uretici.

Uygulanan kurallar:
  * vurgusuz 'о' -> 'a' (akanye)
  * kelime sonunda otumlulesme kaybi: б->p, в->f, г->k, д->t, ж->ş, з->s
  * ь / ъ ardindan gelen sesli iyotlasir: вье -> vye
  * hecelere bolup vurgulu heceyi BUYUK yazar (Turkce buyuk harf kurallariyla)
"""

STRESS = '́'          # birlesik keskin aksan
VOWELS = set('аеёиоуыэюя')
SOFT = set('ьъ')

MAP = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd',
    'е': 'e', 'ё': 'yo', 'ж': 'j', 'з': 'z', 'и': 'i',
    'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n',
    'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
    'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ç',
    'ш': 'ş', 'щ': 'şç', 'ъ': '', 'ы': 'ı', 'ь': "'",
    'э': 'e', 'ю': 'yu', 'я': 'ya',
}

DEVOICE = {'б': 'p', 'в': 'f', 'г': 'k', 'д': 't', 'ж': 'ş', 'з': 's'}

IOTATED = {'е': 'ye', 'ё': 'yo', 'ю': 'yu', 'я': 'ya', 'и': 'yi'}


def tr_upper(text):
    """Turkce buyuk harf: i -> I degil İ, ı -> I."""
    return text.replace('i', 'İ').replace('ı', 'I').upper()


def split_stress(word):
    """(harfler, vurgulu_sesli_index) dondurur. Tek heceli ise otomatik vurgu."""
    letters, stressed = [], -1
    for ch in word.lower():
        if ch == STRESS:
            if letters:
                stressed = len(letters) - 1
            continue
        letters.append(ch)

    if stressed < 0 and 'ё' in letters:
        stressed = letters.index('ё')          # ё her zaman vurgulu

    vowels = [i for i, c in enumerate(letters) if c in VOWELS]
    if stressed < 0 and len(vowels) == 1:
        stressed = vowels[0]                   # tek heceli: tek sesli vurgulu

    return letters, stressed


def _last_consonant_index(letters):
    """Kelime sonundaki (yumusatma isaretleri haric) son unsuzun indeksi."""
    i = len(letters) - 1
    while i >= 0 and letters[i] in SOFT:
        i -= 1
    return i if i >= 0 and letters[i] not in VOWELS else -1


def _letter_to_latin(letters, i, stressed, devoice_at):
    ch = letters[i]
    prev = letters[i - 1] if i > 0 else None

    if i == devoice_at and ch in DEVOICE:
        return DEVOICE[ch]

    if ch == 'о' and stressed >= 0 and i != stressed:
        return 'a'                                     # akanye

    if ch in IOTATED and (prev is None or prev in VOWELS or prev in SOFT):
        return IOTATED[ch]

    # ikanye: unsuzden sonra gelen vurgusuz 'е' [ɪ] okunur (телефон -> ti-li-FON)
    if ch == 'е' and stressed >= 0 and i != stressed:
        return 'i'

    if ch == 'ь':
        nxt = letters[i + 1] if i + 1 < len(letters) else None
        # Sonraki sesli zaten iyotlandi; burada ayrica kesme isareti koyma.
        return '' if nxt in IOTATED else "'"

    return MAP.get(ch, ch)


def syllable_bounds(letters):
    """Hece sinirlari. Sonraki hecenin baslangici: son unsuz (+ varsa ь/ъ)."""
    vowels = [i for i, c in enumerate(letters) if c in VOWELS]
    if not vowels:
        return [(0, len(letters))]

    bounds, start = [], 0
    for k in range(len(vowels) - 1):
        vi, nvi = vowels[k], vowels[k + 1]
        cluster = list(range(vi + 1, nvi))
        if not cluster:
            split = nvi
        else:
            # Yumusatma isaretleri onceki unsuza yapisir: "вь" tek parca.
            j = len(cluster) - 1
            while j > 0 and letters[cluster[j]] in SOFT:
                j -= 1
            split = cluster[j]
        bounds.append((start, split))
        start = split
    bounds.append((start, len(letters)))
    return bounds


def pronounce(word):
    """Vurgulu okunus uretir: 'рабо́тать' -> \"ra-BO-tat'\".

    Cok kelimeli kaliplar ("несмотря́ на") her kelime ayri hecelenip bosluk
    ile birlestirilir; aksi hâlde hece bolucu boslugu unsuz sanip
    "nis-mat-RYA -na" gibi bozuk cikti veriyor.
    """
    if ' ' in word.strip():
        return ' '.join(
            pronounce(part) for part in word.split() if part
        )

    letters, stressed = split_stress(word)
    if not letters:
        return ''

    devoice_at = _last_consonant_index(letters)
    latin = [
        _letter_to_latin(letters, i, stressed, devoice_at)
        for i in range(len(letters))
    ]

    if stressed < 0:
        return ''.join(latin)

    parts = []
    for a, b in syllable_bounds(letters):
        text = ''.join(latin[a:b])
        if not text:
            continue
        parts.append(tr_upper(text) if a <= stressed < b else text)
    return '-'.join(parts)


def transliterate(word):
    """Vurgusuz duz cevrim (arama/eslestirme icin)."""
    letters, _ = split_stress(word)
    return ''.join(
        _letter_to_latin(letters, i, -1, -1) for i in range(len(letters))
    )


if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    tests = [
        ('рабо́тать', "ra-BO-tat'"),
        ('го́род', 'GO-rat'),
        ('возмо́жность', "vaz-MOJ-nast'"),
        ('вода́', 'va-DA'),
        ('кни́га', 'KNİ-ga'),
        ('хлеб', 'HLEP'),
        ('здоро́вье', 'zda-RO-vye'),
        ('эконо́мика', 'e-ka-NO-mi-ka'),
        ('молоко́', 'ma-la-KO'),
        ('учёный', 'u-ÇYO-nıy'),
        ('друг', 'DRUK'),
        ('пого́да', 'pa-GO-da'),
        ('чита́ть', "çi-TAT'"),
        ('семья́', 'si-mYA'),
    ]
    ok = 0
    for src, expected in tests:
        got = pronounce(src)
        good = got.lower() == expected.lower()
        ok += good
        print(f'{"OK " if good else "!! "}{src:<16} -> {got:<18} (beklenen {expected})')
    print(f'\n{ok}/{len(tests)} dogru')
