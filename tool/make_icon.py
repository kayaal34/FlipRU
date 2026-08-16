"""FlipRU uygulama simgesini ve acilis logosunu uretir.

Tasarim: mor-pembe gecisli yuvarlak kare uzerinde, cevrilmekte olan iki kart.
Arkadaki egik kartta "TR", ondeki kartta "RU" -- uygulamanin yaptigi isi
(iki dil arasinda kart cevirmek) tek bakista anlatiyor.
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Inter-ExtraBold.ttf')

# Android mipmap yogunluklari
ANDROID = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

BG_TOP = (99, 91, 255)      # indigo
BG_MID = (139, 92, 246)     # mor
BG_BOTTOM = (236, 72, 153)  # pembe


def vertical_gradient(size, top, mid, bottom):
    """Ucgen duraklı dikey gecis."""
    image = Image.new('RGB', (1, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(size - 1, 1)
        if t < 0.5:
            k = t / 0.5
            c = tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        else:
            k = (t - 0.5) / 0.5
            c = tuple(int(mid[i] + (bottom[i] - mid[i]) * k) for i in range(3))
        draw.point((0, y), fill=c)
    return image.resize((size, size), Image.BICUBIC)


def rounded_mask(size, radius):
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (size - 1, size - 1)], radius=radius, fill=255
    )
    return mask


def card(size, w, h, radius, fill, letter, font_path, letter_fill, angle):
    """Tek bir kelime karti (dondurulmus, yumusak golgeli)."""
    pad = size // 6
    layer = Image.new('RGBA', (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle(
        [(pad, pad), (pad + w, pad + h)], radius=radius, fill=fill
    )

    if letter:
        # Tek harf yerine iki harf yaziyoruz; punto ona gore.
        size = int(h * (0.62 if len(letter) == 1 else 0.34))
        font = ImageFont.truetype(font_path, size)
        box = draw.textbbox((0, 0), letter, font=font)
        draw.text(
            (
                pad + (w - (box[2] - box[0])) / 2 - box[0],
                pad + (h - (box[3] - box[1])) / 2 - box[1],
            ),
            letter,
            font=font,
            fill=letter_fill,
        )

    return layer.rotate(angle, resample=Image.BICUBIC, expand=True)


def build(size, *, rounded=True):
    """Verilen kenar uzunlugunda simgeyi uretir."""
    scale = 4  # supersampling
    s = size * scale

    base = vertical_gradient(s, BG_TOP, BG_MID, BG_BOTTOM).convert('RGBA')

    # Arka planda hafif isik lekesi -- duz gecisi canlandiriyor.
    glow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        [(-s * 0.25, -s * 0.45), (s * 0.85, s * 0.45)],
        fill=(255, 255, 255, 46),
    )
    base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(s * 0.06)))

    # Kartlar iki dil de okunacak kadar ayrik duruyor.
    card_w, card_h = int(s * 0.35), int(s * 0.48)
    radius = int(s * 0.06)

    back = card(
        s, card_w, card_h, radius,
        (255, 255, 255, 150), 'TR', FONT, (255, 255, 255, 235), 15,
    )
    front = card(
        s, card_w, card_h, radius,
        (255, 255, 255, 255), 'RU', FONT, (91, 60, 220, 255), -7,
    )

    base.alpha_composite(
        back,
        (int(s * 0.50 - back.width / 2 + s * 0.185),
         int(s * 0.5 - back.height / 2) - int(s * 0.02)),
    )
    base.alpha_composite(
        front,
        (int(s * 0.50 - front.width / 2 - s * 0.115),
         int(s * 0.5 - front.height / 2) + int(s * 0.02)),
    )

    if rounded:
        base.putalpha(rounded_mask(s, int(s * 0.22)))

    return base.resize((size, size), Image.LANCZOS)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    if not os.path.exists(FONT):
        raise SystemExit(f'font bulunamadi: {FONT}')

    android_res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    for folder, px in ANDROID.items():
        target = os.path.join(android_res, folder)
        os.makedirs(target, exist_ok=True)
        build(px).save(os.path.join(target, 'ic_launcher.png'))
        print(f'  {folder}/ic_launcher.png ({px}px)')

    # Uygulama ici acilis logosu (seffaf kenarli, koseleri yuvarlatilmis)
    assets = os.path.join(ROOT, 'assets', 'images')
    os.makedirs(assets, exist_ok=True)
    build(512).save(os.path.join(assets, 'logo.png'))
    print(f'  assets/images/logo.png (512px)')

    # Magaza gorseli
    build(1024, rounded=False).save(os.path.join(assets, 'store_icon.png'))
    print(f'  assets/images/store_icon.png (1024px, kosesiz)')


if __name__ == '__main__':
    main()
