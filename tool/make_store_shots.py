# -*- coding: utf-8 -*-
"""Google Play magaza ekran goruntulerini uretir.

Ham ekran goruntusunu marka zeminine yerlestirip ustune tanitim metnini
yaziyor. Ciktilar 1242x2208 (Play'in telefon gorseli icin bekledigi
oranlardan biri) ve assets/store/ altina yaziliyor.

Kullanim:
    python tool/make_store_shots.py <ham_goruntu_klasoru>
"""

import io
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = os.path.join(ROOT, 'assets', 'fonts')
CIKTI = os.path.join(ROOT, 'assets', 'store')

# Simgeyle ayni marka renkleri (bkz. tool/make_icon.py)
BG_TOP = (72, 64, 200)
BG_MID = (110, 74, 196)
BG_BOTTOM = (188, 58, 122)

GENIS, YUKSEK = 1242, 2208

# (ham dosya, baslik, alt baslik)
KARELER = [
    ('04_ana_ekran.png', '8.000’den fazla\nRusça kelime',
     'Örnek cümlesi ve okunuşuyla'),
    ('01_kart_on.png', 'Kartı çevir,\nkaydır, öğren',
     'Bildiğini sağa, tekrar edeceğini sola'),
    ('05_bolumler.png', '20’şer kelimelik\nbölümler',
     'Sırayla ilerle, her bölümü tamamla'),
    ('08_yazma.png', 'Yazarak\npekiştir',
     'Kelimeyi harf harf kur — kalıcı öğrenme'),
    ('07_pratik.png', 'Testlerle\nkendini ölç',
     'Günün testi, seviye testleri, yazma pratiği'),
    ('06_temalar.png', 'Temalara ayrılmış\nkelimeler',
     'Siyaset, ekonomi, sağlık, bilim ve dahası'),
]


def zemin():
    """Dikey marka gecisi + ust kosede yumusak isik."""
    kare = Image.new('RGB', (1, YUKSEK))
    ciz = ImageDraw.Draw(kare)
    for y in range(YUKSEK):
        t = y / (YUKSEK - 1)
        if t < 0.5:
            k = t / 0.5
            c = tuple(int(BG_TOP[i] + (BG_MID[i] - BG_TOP[i]) * k)
                      for i in range(3))
        else:
            k = (t - 0.5) / 0.5
            c = tuple(int(BG_MID[i] + (BG_BOTTOM[i] - BG_MID[i]) * k)
                      for i in range(3))
        ciz.point((0, y), fill=c)
    zem = kare.resize((GENIS, YUKSEK), Image.BICUBIC).convert('RGBA')

    isik = Image.new('RGBA', (GENIS, YUKSEK), (0, 0, 0, 0))
    ImageDraw.Draw(isik).ellipse(
        [(-GENIS * 0.3, -YUKSEK * 0.22), (GENIS * 0.9, YUKSEK * 0.28)],
        fill=(255, 255, 255, 38),
    )
    zem.alpha_composite(isik.filter(ImageFilter.GaussianBlur(GENIS * 0.09)))
    return zem


def yuvarlat(im, yaricap):
    maske = Image.new('L', im.size, 0)
    ImageDraw.Draw(maske).rounded_rectangle(
        [(0, 0), (im.size[0] - 1, im.size[1] - 1)], radius=yaricap, fill=255
    )
    out = im.convert('RGBA')
    out.putalpha(maske)
    return out


def golge(boyut, yaricap, bulanik, alfa):
    g = Image.new('RGBA', (boyut[0] + bulanik * 4, boyut[1] + bulanik * 4),
                  (0, 0, 0, 0))
    ImageDraw.Draw(g).rounded_rectangle(
        [(bulanik * 2, bulanik * 2),
         (bulanik * 2 + boyut[0], bulanik * 2 + boyut[1])],
        radius=yaricap, fill=(0, 0, 0, alfa),
    )
    return g.filter(ImageFilter.GaussianBlur(bulanik))


def sar(ciz, metin, font, en_fazla):
    """Metni verilen genislige gore satirlara boler."""
    satirlar = []
    for parca in metin.split('\n'):
        simdi = ''
        for kelime in parca.split(' '):
            deneme = (simdi + ' ' + kelime).strip()
            if ciz.textlength(deneme, font=font) <= en_fazla or not simdi:
                simdi = deneme
            else:
                satirlar.append(simdi)
                simdi = kelime
        satirlar.append(simdi)
    return satirlar


def uret(ham_yol, baslik, alt, hedef):
    tuval = zemin()
    ciz = ImageDraw.Draw(tuval)

    f_baslik = ImageFont.truetype(
        os.path.join(FONT_DIR, 'Inter-ExtraBold.ttf'), 86)
    f_alt = ImageFont.truetype(
        os.path.join(FONT_DIR, 'Inter-Medium.ttf'), 42)

    kenar = 84
    y = 128
    for satir in sar(ciz, baslik, f_baslik, GENIS - kenar * 2):
        ciz.text((kenar, y), satir, font=f_baslik, fill=(255, 255, 255))
        y += 104
    y += 14
    for satir in sar(ciz, alt, f_alt, GENIS - kenar * 2):
        ciz.text((kenar, y), satir, font=f_alt, fill=(255, 255, 255, 214))
        y += 56

    # Telefon gorseli: kalan alana sigacak kadar
    ham = Image.open(ham_yol).convert('RGB')
    ust = y + 78
    kullanilabilir = YUKSEK - ust + 260   # alt taraf tasabilir, tuval kirpar
    oran = min((GENIS - kenar * 2) / ham.width, kullanilabilir / ham.height)
    yeni = (int(ham.width * oran), int(ham.height * oran))
    telefon = yuvarlat(ham.resize(yeni, Image.LANCZOS), 46)

    x = (GENIS - yeni[0]) // 2
    g = golge(yeni, 46, 34, 130)
    tuval.alpha_composite(g, (x - 68, ust - 54))
    tuval.alpha_composite(telefon, (x, ust))

    tuval.convert('RGB').save(hedef, quality=95)
    return hedef


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    if len(sys.argv) < 2:
        raise SystemExit('kullanim: python tool/make_store_shots.py <klasor>')
    ham_klasor = sys.argv[1]
    os.makedirs(CIKTI, exist_ok=True)

    for i, (dosya, baslik, alt) in enumerate(KARELER, start=1):
        kaynak = os.path.join(ham_klasor, dosya)
        if not os.path.exists(kaynak):
            print('  atlandi (yok):', dosya)
            continue
        hedef = os.path.join(CIKTI, 'play_%d.png' % i)
        uret(kaynak, baslik, alt, hedef)
        print('  %s  <-  %s' % (os.path.basename(hedef), dosya))

    print('\ncikti klasoru:', CIKTI)


if __name__ == '__main__':
    main()
