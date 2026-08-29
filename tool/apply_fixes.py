# -*- coding: utf-8 -*-
"""`curated_fixes.py` icindeki duzeltmeleri uretilmis veri setine uygular.

Kullanim:  python tool/apply_fixes.py [--dry]

Ham derlem arsivleri olmadan `build_dataset.py` calistirilamadigi icin
duzeltmeler dogrudan `assets/data/words.json` uzerinde yapiliyor. Islem
idempotent: ayni dosyada tekrar calistirmak zarar vermez.
"""
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from curated_fixes import (  # noqa: E402
    CONTENT_DROP,
    DROP,
    DROP_EXAMPLE,
    FIXES,
    POST_FIXES,
)
from report_fixes import (  # noqa: E402
    REPORT_CLEAR_EXAMPLE,
    REPORT_POS,
    REPORT_TR,
)
from report2_fixes import (  # noqa: E402
    REPORT2_DROP,
    REPORT2_EXAMPLE,
    REPORT2_TR,
    REPORT2_TRANSLIT,
)
from report3_fixes import REPORT3_EXTRA, REPORT3_TR  # noqa: E402
from report4_fixes import (  # noqa: E402
    REPORT4_DROP,
    REPORT4_EXTRA,
    REPORT4_TR,
)
from meaning_fixes import MEANING_FIXES, TRANSLIT_FIXES  # noqa: E402
from report5_fixes import (  # noqa: E402
    REPORT5_CLEAR_EXAMPLE,
    REPORT5_EXAMPLE,
    REPORT5_MANUAL,
    REPORT5_POS,
    REPORT5_TR,
)
from report6_fixes import (  # noqa: E402
    REPORT6_ACCENTED,
    REPORT6_CLEAR_EXAMPLE,
    REPORT6_CLEAR_THEME,
    REPORT6_EXAMPLE,
    REPORT6_POS,
    REPORT6_TR,
    REPORT6_TRANSLIT,
)
from report7_fixes import (  # noqa: E402
    REPORT7_ACCENTED,
    REPORT7_CLEAR_EXAMPLE,
    REPORT7_CLEAR_THEME,
    REPORT7_DROP,
    REPORT7_EXAMPLE,
    REPORT7_POS,
    REPORT7_RU,
    REPORT7_TR,
    REPORT7_TRANSLIT,
)
from report8_fixes import (  # noqa: E402
    REPORT8_CLEAR_EXAMPLE,
    REPORT8_CLEAR_THEME,
    REPORT8_DROP,
    REPORT8_EXAMPLE,
    REPORT8_RU,
    REPORT8_TR,
)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, 'assets', 'data', 'words.json')

# Kart yuzunde iki satiri gecmeyen uzunluk. Raporun onerileri yer yer uzun
# aciklama tasiyor ("olmak (fiil) / boy pos, endam (eski isim anlamı)");
# ogrenilecek karsilik kaybolmadan kisaltiyoruz.
MAX_LEN = 34


def _split(text):
    """Parantez icini bozmadan virgul ve egik cizgiden ayirir."""
    parts, depth, buf = [], 0, ''
    for ch in text:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth = max(0, depth - 1)
        if ch in ',/' and depth == 0:
            parts.append(buf.strip())
            buf = ''
        else:
            buf += ch
    if buf.strip():
        parts.append(buf.strip())
    return [p for p in parts if p]


def shorten(text):
    """En fazla iki anlam, gereksiz uzun parantezler atilmis hali."""
    parts = _split(text)[:2]
    if len(', '.join(parts)) <= MAX_LEN:
        return ', '.join(parts)

    # Once uzun parantezleri at.
    stripped = [re.sub(r'\s*\([^)]{12,}\)', '', p).strip() for p in parts]
    stripped = [p for p in stripped if p]
    if stripped and len(', '.join(stripped)) <= MAX_LEN:
        return ', '.join(stripped)

    # Hala uzunsa tek anlama dus.
    return (stripped or parts)[0]


def tek_anlam(text):
    """Ikinci anlami atar.

    Veri setinin %47'sinde iki Turkce karsilik vardi ve bunlarin buyuk
    cogunlugu ayni seyin ikinci bir soylenisiydi: "denklem, muadele",
    "tarla kusu, turgay", "amator, ozenci", "kurt, bori". Ikinci karsilik
    yeni bir sey ogretmiyor, karti kalabaliklastiriyordu.

    Parantezli aciklama tasiyanlar korunuyor: orada ikinci karsilik gercek
    bir anlam ayrimi ("papaz, popo (argo)", "not (okul notu), degerlendirme").

    Ilk karsilik oldugu gibi kaldigi icin hicbir kart yanlis hale gelmiyor;
    yalnizca eksiliyor.
    """
    parts = _split(text)
    if len(parts) < 2:
        return text
    if any('(' in p for p in parts):
        return text
    return parts[0]


def main():
    dry = '--dry' in sys.argv

    with io.open(PATH, encoding='utf-8') as fh:
        data = json.load(fh)
    idx = {name: i for i, name in enumerate(data['fields'])}
    rows = data['rows']

    kept = []
    changed = dropped = cleared = pos_fixed = 0
    translit_fixed = examples_set = tekilendi = anlam_fixed = 0
    accented_fixed = theme_cleared = 0
    seen = set()
    seen_ids = set()
    mismatched = []

    for row in rows:
        bare = row[idx['ru']]
        wid = row[idx['id']]
        if (bare in DROP or bare in CONTENT_DROP
                or wid in REPORT2_DROP or wid in REPORT4_DROP
                or wid in REPORT7_DROP or wid in REPORT8_DROP):
            dropped += 1
            continue

        # Once elle bulunanlar, sonra rapor: rapor daha kapsamli, o kazansin.
        new_tr = FIXES.get(bare)
        for source in (REPORT_TR, REPORT2_TR, REPORT3_TR, REPORT3_EXTRA,
                       REPORT4_TR, REPORT4_EXTRA, REPORT5_TR,
                       REPORT5_MANUAL, REPORT6_TR, REPORT7_TR, REPORT8_TR):
            report = source.get(wid)
            if not report:
                continue
            report_ru, report_tr = report
            # Kimlikler kaymis olabilir; Rusca kelime tutmuyorsa dokunma.
            if report_ru != bare:
                mismatched.append((wid, bare, report_ru))
                continue
            new_tr = report_tr

        # Kaba icerik taramasindan cikanlar en son sozu soyler.
        new_tr = POST_FIXES.get(bare, new_tr)

        # Kisaltma yalnizca gozden gecirilmis satirlarda. Dokunulmamis bir
        # kaydi kisaltmak, hangi anlamin dogru oldugunu bilmeden ilkini
        # secmek demek olurdu — "наряжать: aranjman, ... giydirmek" gibi
        # kayitlarda yanlis olani birakirdi.
        if new_tr:
            new_tr = shorten(new_tr)

        if new_tr and row[idx['tr']] != new_tr:
            print('  %-8s %-16s %-30s -> %s'
                  % (wid, bare, row[idx['tr']][:28], new_tr))
            row[idx['tr']] = new_tr
            changed += 1

        new_pos = (REPORT_POS.get(wid) or REPORT5_POS.get(wid)
                   or REPORT6_POS.get(wid) or REPORT7_POS.get(wid))
        if new_pos and row[idx['pos']] != new_pos:
            row[idx['pos']] = new_pos
            pos_fixed += 1

        elle_okunus = TRANSLIT_FIXES.get(wid)
        if elle_okunus and elle_okunus[0] == bare:
            row[idx['translit']] = elle_okunus[1]

        new_translit = (REPORT2_TRANSLIT.get(wid) or REPORT6_TRANSLIT.get(wid)
                        or REPORT7_TRANSLIT.get(wid))
        if new_translit and row[idx['translit']] != new_translit:
            row[idx['translit']] = new_translit
            translit_fixed += 1

        new_accented = REPORT6_ACCENTED.get(wid) or REPORT7_ACCENTED.get(wid)
        if new_accented and row[idx['accented']] != new_accented:
            row[idx['accented']] = new_accented
            accented_fixed += 1

        # Cumle yazmak silmekten once gelir: ikinci tur, birinci turda
        # silinmis bir cumlenin yerine dogrusunu koyabiliyor.
        new_example = (REPORT2_EXAMPLE.get(wid) or REPORT5_EXAMPLE.get(wid)
                       or REPORT6_EXAMPLE.get(wid) or REPORT7_EXAMPLE.get(wid)
                       or REPORT8_EXAMPLE.get(wid))
        if new_example:
            ex_ru, ex_tr = new_example
            if (row[idx['exRu']], row[idx['exTr']]) != (ex_ru, ex_tr):
                row[idx['exRu']] = ex_ru
                row[idx['exTr']] = ex_tr
                examples_set += 1
        elif (bare in DROP_EXAMPLE or wid in REPORT_CLEAR_EXAMPLE
                or wid in REPORT5_CLEAR_EXAMPLE
                or wid in REPORT6_CLEAR_EXAMPLE
                or wid in REPORT7_CLEAR_EXAMPLE
                or wid in REPORT8_CLEAR_EXAMPLE) and row[idx['exRu']]:
            row[idx['exRu']] = ''
            row[idx['exTr']] = ''
            cleared += 1

        if (wid in REPORT6_CLEAR_THEME or wid in REPORT7_CLEAR_THEME
                or wid in REPORT8_CLEAR_THEME) and row[idx['theme']]:
            row[idx['theme']] = ''
            theme_cleared += 1

        # Baslik kelimenin kendisi hataliydi (gecersiz mastar, kucuk harfli
        # ozel isim). En son uygulanir: yukaridaki eslesmeler eski `bare`
        # degeriyle calisiyor olmali.
        ru_fix = REPORT7_RU.get(wid) or REPORT8_RU.get(wid)
        if ru_fix and ru_fix[0] == bare and row[idx['ru']] != ru_fix[1]:
            row[idx['ru']] = ru_fix[1]
            bare = ru_fix[1]

        sadelesmis = tek_anlam(row[idx['tr']])
        if sadelesmis != row[idx['tr']]:
            row[idx['tr']] = sadelesmis
            tekilendi += 1

        # Ilk karsiligi eskil ya da hantal olanlar en son sozu soyler.
        elle = MEANING_FIXES.get(wid)
        if elle:
            beklenen, yeni = elle
            if beklenen != bare:
                mismatched.append((wid, bare, beklenen))
            elif row[idx['tr']] != yeni:
                row[idx['tr']] = yeni
                anlam_fixed += 1

        seen.add(bare)
        seen_ids.add(wid)
        kept.append(row)

    missing = sorted((set(FIXES) | DROP_EXAMPLE) - seen)
    if missing:
        print('\nveri setinde bulunamadi:', ', '.join(missing))

    known_ids = set(REPORT_TR) | set(REPORT2_TR) | set(REPORT2_EXAMPLE) \
        | set(REPORT2_TRANSLIT) | set(REPORT3_TR) | set(REPORT3_EXTRA) \
        | set(REPORT4_TR) | set(REPORT4_EXTRA) | set(REPORT5_TR) \
        | set(REPORT5_MANUAL) | set(REPORT6_TR) | set(REPORT6_EXAMPLE) \
        | set(REPORT6_POS) | set(REPORT6_TRANSLIT) | set(REPORT6_ACCENTED) \
        | REPORT6_CLEAR_EXAMPLE | REPORT6_CLEAR_THEME \
        | set(REPORT7_TR) | set(REPORT7_EXAMPLE) | set(REPORT7_POS) \
        | set(REPORT7_TRANSLIT) | set(REPORT7_ACCENTED) | set(REPORT7_RU) \
        | REPORT7_CLEAR_EXAMPLE | REPORT7_CLEAR_THEME \
        | set(REPORT8_TR) | set(REPORT8_EXAMPLE) | set(REPORT8_RU) \
        | REPORT8_CLEAR_EXAMPLE | REPORT8_CLEAR_THEME
    lost = sorted(known_ids - seen_ids - REPORT2_DROP - REPORT4_DROP
                  - REPORT7_DROP - REPORT8_DROP)
    if lost:
        print('rapordaki id veri setinde yok (%d): %s'
              % (len(lost), ', '.join(lost[:10])))
    if mismatched:
        print('\nid/kelime uyusmazligi (%d):' % len(mismatched))
        for wid, bare, expected in mismatched[:15]:
            print('   %s veride %r, raporda %r' % (wid, bare, expected))

    print('\nduzeltilen ceviri : %d' % changed)
    print('duzeltilen tur    : %d' % pos_fixed)
    print('duzeltilen okunus : %d' % translit_fixed)
    print('duzeltilen vurgu  : %d' % accented_fixed)
    print('yazilan ornek     : %d' % examples_set)
    print('cikarilan kelime  : %d' % dropped)
    print('silinen ornek     : %d' % cleared)
    print('temizlenen tema   : %d' % theme_cleared)
    print('tek anlama dusen  : %d' % tekilendi)
    print('karsiligi duzelen : %d' % anlam_fixed)
    print('kalan kelime      : %d' % len(kept))

    if dry:
        print('\n(kuru calisma, dosya yazilmadi)')
        return

    data['rows'] = kept
    with io.open(PATH, 'w', encoding='utf-8', newline='\n') as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(',', ':'))
    print('\nassets/data/words.json guncellendi')


if __name__ == '__main__':
    main()
