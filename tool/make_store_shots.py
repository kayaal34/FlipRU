# -*- coding: utf-8 -*-
"""Google Play magaza ekran goruntulerini uretir.

Ham ekran goruntusunu telefon cercevesine oturtup marka zeminine
yerlestiriyor ve ustune tanitim metnini yaziyor.

Ekranin tamami gorunur: telefon, metinden arta kalan yukseklige gore
olceklendiriliyor, kirpilmiyor. Ciktilar 1242x2208 (Play'in telefon
gorseli oranlarindan biri) ve assets/store/ altina yaziliyor.

Kullanim:
    python tool/make_store_shots.py <ham_goruntu_klasoru>
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = os.path.join(ROOT, 'assets', 'fonts')
CIKTI = os.path.join(ROOT, 'assets', 'store')

GENIS, YUKSEK = 1242, 2208

# Zemin: koyu lacivertten mora, altta pembe bir sicaklik. Simgenin
# renkleriyle ayni aile ama daha koyu; beyaz metin uzerinde rahat okunsun.
BG_UST = (26, 22, 58)
BG_ORTA = (66, 46, 138)
BG_ALT = (140, 46, 116)

# Telefon cercevesi
CERCEVE = (14, 14, 20)
CERCEVE_ISIK = (108, 104, 140)


def zemin():
    kare = Image.new('RGB', (1, YUKSEK))
    ciz = ImageDraw.Draw(kare)
    for y in range(YUKSEK):
        t = y / (YUKSEK - 1)
        if t < 0.55:
            k = t / 0.55
            c = tuple(int(BG_UST[i] + (BG_ORTA[i] - BG_UST[i]) * k)
                      for i in range(3))
        else:
            k = (t - 0.55) / 0.45
            c = tuple(int(BG_ORTA[i] + (BG_ALT[i] - BG_ORTA[i]) * k)
                      for i in range(3))
        ciz.point((0, y), fill=c)
    zem = kare.resize((GENIS, YUKSEK), Image.BICUBIC).convert('RGBA')

    # Telefonun arkasindan gelen yumusak isik: duz gecisi canlandiriyor.
    isik = Image.new('RGBA', (GENIS, YUKSEK), (0, 0, 0, 0))
    ImageDraw.Draw(isik).ellipse(
        [(GENIS * 0.02, YUKSEK * 0.20), (GENIS * 0.98, YUKSEK * 0.92)],
        fill=(150, 120, 255, 60),
    )
    zem.alpha_composite(isik.filter(ImageFilter.GaussianBlur(GENIS * 0.13)))

    parlak = Image.new('RGBA', (GENIS, YUKSEK), (0, 0, 0, 0))
    ImageDraw.Draw(parlak).ellipse(
        [(-GENIS * 0.35, -YUKSEK * 0.20), (GENIS * 0.75, YUKSEK * 0.14)],
        fill=(255, 255, 255, 30),
    )
    zem.alpha_composite(parlak.filter(ImageFilter.GaussianBlur(GENIS * 0.10)))
    return zem


def yuvarlat(im, yaricap):
    maske = Image.new('L', im.size, 0)
    ImageDraw.Draw(maske).rounded_rectangle(
        [(0, 0), (im.size[0] - 1, im.size[1] - 1)], radius=yaricap, fill=255
    )
    out = im.convert('RGBA')
    out.putalpha(maske)
    return out


def cerceveye_oturt(ekran, kalinlik, yaricap):
    """Ekran goruntusunu koyu bir telefon cercevesine yerlestirir."""
    g, y = ekran.size
    tam = (g + kalinlik * 2, y + kalinlik * 2)

    govde = Image.new('RGBA', tam, (0, 0, 0, 0))
    ciz = ImageDraw.Draw(govde)
    ciz.rounded_rectangle([(0, 0), (tam[0] - 1, tam[1] - 1)],
                          radius=yaricap + kalinlik, fill=CERCEVE)
    # Cercevenin kenarindaki ince isik: metal govde hissi.
    ciz.rounded_rectangle([(0, 0), (tam[0] - 1, tam[1] - 1)],
                          radius=yaricap + kalinlik,
                          outline=CERCEVE_ISIK, width=3)

    govde.alpha_composite(yuvarlat(ekran, yaricap), (kalinlik, kalinlik))
    return govde


def golge(boyut, yaricap, bulanik, alfa):
    pad = bulanik * 3
    g = Image.new('RGBA', (boyut[0] + pad * 2, boyut[1] + pad * 2),
                  (0, 0, 0, 0))
    ImageDraw.Draw(g).rounded_rectangle(
        [(pad, pad), (pad + boyut[0], pad + boyut[1])],
        radius=yaricap, fill=(0, 0, 0, alfa),
    )
    return g.filter(ImageFilter.GaussianBlur(bulanik)), pad


def sar(ciz, metin, font, en_fazla):
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
        os.path.join(FONT_DIR, 'Inter-ExtraBold.ttf'), 78)
    f_alt = ImageFont.truetype(
        os.path.join(FONT_DIR, 'Inter-Medium.ttf'), 38)

    kenar = 92
    en_fazla = GENIS - kenar * 2

    baslik_satir = sar(ciz, baslik, f_baslik, en_fazla)
    alt_satir = sar(ciz, alt, f_alt, en_fazla)

    # Metin blogu ustte, ortalanmis.
    y = 104
    for satir in baslik_satir:
        w = ciz.textlength(satir, font=f_baslik)
        ciz.text(((GENIS - w) / 2, y), satir, font=f_baslik,
                 fill=(255, 255, 255))
        y += 94
    y += 10
    for satir in alt_satir:
        w = ciz.textlength(satir, font=f_alt)
        ciz.text(((GENIS - w) / 2, y), satir, font=f_alt,
                 fill=(226, 220, 255))
        y += 52

    # Kalan alan telefonun: ekranin tamami sigsin, kirpilmasin.
    ust_bosluk = y + 76
    alt_bosluk = 76
    alan_y = YUKSEK - ust_bosluk - alt_bosluk
    alan_x = GENIS - kenar * 2

    kalinlik, yaricap = 13, 40
    ham = Image.open(ham_yol).convert('RGB')
    oran = min((alan_x - kalinlik * 2) / ham.width,
               (alan_y - kalinlik * 2) / ham.height)
    yeni = (int(ham.width * oran), int(ham.height * oran))
    telefon = cerceveye_oturt(ham.resize(yeni, Image.LANCZOS),
                              kalinlik, yaricap)

    tg, ty = telefon.size
    x = (GENIS - tg) // 2
    # Kalan bosluga dikeyde ortala.
    ty0 = ust_bosluk + max(0, (alan_y - ty) // 2)

    g, pad = golge((tg, ty), yaricap + kalinlik, 30, 145)
    tuval.alpha_composite(g, (x - pad, ty0 - pad + 22))
    tuval.alpha_composite(telefon, (x, ty0))

    tuval.convert('RGB').save(hedef, quality=96)
    return hedef


# (ham dosya, baslik, alt baslik)
KARELER = [
    ('04_ana_ekran.png', '8.000’den fazla\nRusça kelime',
     'Okunuşu ve örnek cümlesiyle · tamamen ücretsiz'),
    ('01_kart_on.png', 'Kartı çevir,\nkaydır, öğren',
     'Bildiğin sağa, tekrar edeceğin sola'),
    ('05_bolumler.png', '20’şer kelimelik\nbölümler',
     'Sırayla ilerle, her bölümü tamamlayarak'),
    ('08_yazma.png', 'Yazarak\npekiştir',
     'Kelimeyi harf harf kur — kalıcı öğrenme'),
    ('07_pratik.png', 'Testlerle\nkendini ölç',
     'Günün testi, seviye testleri, yazma pratiği'),
    ('06_temalar.png', 'Temalara ayrılmış\nkelimeler',
     'Siyaset, ekonomi, sağlık, bilim ve dahası'),
]


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
