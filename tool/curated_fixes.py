# -*- coding: utf-8 -*-
"""Telefonda yapilan tam gecisde yakalanan ceviri hatalari.

`curated_overrides.py` ve `curated_b2c1.py` derleme sirasinda okunuyor; bu
dosya ise uretilmis `assets/data/words.json` uzerinde `apply_fixes.py` ile
uygulaniyor. Ham derlem arsivleri (tool/data) artik yerinde olmadigi icin
tam yeniden derleme mumkun degil; boru hatti tekrar calistirilirsa buradaki
kayitlar `curated_overrides.py` icine tasinmali.

Kaynak: 2026-08-16 tarihli cihaz uzerinde ekran ekran gozden gecirme.
"""

# bare -> dogru Turkce karsilik (en fazla iki anlam)
FIXES = {
    # ── Fiiller: sozlugun en cok saptigi grup ──
    'мочь': '-ebilmek, muktedir olmak',
    'сделать': 'yapmak, etmek',
    'вернуться': 'geri dönmek, dönmek',
    'случиться': 'olmak, meydana gelmek',
    'пытаться': 'çalışmak, denemek',
    'остаться': 'kalmak',
    'увидеть': 'görmek',
    'рассказать': 'anlatmak',
    'подумать': 'düşünmek',
    'выйти': 'çıkmak, dışarı çıkmak',
    'начать': 'başlamak',
    'есть': 'yemek',
    'пить': 'içmek',
    'знать': 'bilmek, tanımak',
    'собираться': 'niyet etmek, toplanmak',
    'позволить': 'izin vermek',
    'поехать': 'gitmek, yola çıkmak',
    'пройти': 'geçmek, geçip gitmek',
    'заниматься': 'uğraşmak, meşgul olmak',
    'произойти': 'olmak, meydana gelmek',
    'бросить': 'atmak, bırakmak',
    'закончить': 'bitirmek, tamamlamak',
    'проверить': 'kontrol etmek, denetlemek',
    'принять': 'kabul etmek, almak',
    'принимать': 'kabul etmek, almak',
    'забрать': 'alıp götürmek, almak',
    'волноваться': 'heyecanlanmak, endişelenmek',
    'встретиться': 'buluşmak, karşılaşmak',
    'стать': 'olmak, hâline gelmek',
    'понравиться': 'hoşuna gitmek, beğenilmek',
    'выпить': 'içmek',
    'провести': 'geçirmek, yürütmek',
    'представлять': 'hayal etmek, temsil etmek',
    'представить': 'tanıtmak, hayal etmek',
    'справиться': 'üstesinden gelmek, başa çıkmak',
    'вести': 'götürmek, yönetmek',
    'отпустить': 'bırakmak, serbest bırakmak',
    'беспокоиться': 'endişelenmek, merak etmek',
    'поверить': 'inanmak',
    'ходить': 'yürümek, gitmek',

    # ── Sifat ve zarflar ──
    'должный': 'gerekli, borçlu',
    'нужный': 'gerekli, lazım',
    'конечный': 'nihai, son',
    'отличный': 'mükemmel, harika',
    'узкий': 'dar',
    'малый': 'küçük',
    'звонкий': 'tiz, çınlayan',
    'добрый': 'iyi kalpli, nazik',
    'скорый': 'hızlı, çabuk',
    'ужасный': 'korkunç, berbat',
    'верный': 'doğru, sadık',
    'целый': 'bütün, tam',
    'согласный': 'hemfikir, razı',
    'прямой': 'düz, doğrudan',
    'милый': 'tatlı, sevimli',
    'лучше': 'daha iyi',
    'тут': 'burada',
    'можно': 'olur, mümkün',
    'уж': 'artık, zaten',
    'ни': 'ne (de), hiç',
    'все': 'hepsi, herkes',

    # ── Isimler ──
    'парень': 'delikanlı, erkek arkadaş',
    'час': 'saat',
    'вид': 'görünüm, manzara',
    'номер': 'numara, oda',
    'команда': 'takım, komut',
    'компания': 'şirket, arkadaş grubu',
    'свидание': 'randevu, buluşma',
    'вечеринка': 'parti',
    'тип': 'tip, tür',
    'отношение': 'ilişki, tutum',
    'один': 'bir',
    'бог': 'tanrı',
    'убийство': 'cinayet',
    'история': 'tarih, hikâye',
    'мир': 'dünya, barış',
    'земля': 'yer, toprak',
}

# Raporun kapsamadigi, kaba icerik taramasinda cikan kayitlar.
# Rapordan SONRA uygulanir, yani son sozu bunlar soyler.
POST_FIXES = {
    'заворачивать': 'sarmak, paketlemek',   # "bitirmek, sikmek" idi
    'яичко': 'yumurtacık, testis',          # "taşak" idi
    'скверный': 'kötü, berbat',             # "fena, açık saçık" idi
    'шкура': 'post, deri',                  # "orospu çocuğu, cilt" idi
    'гад': 'sürüngen, alçak',               # "orospu çocuğu" idi
    'сволочь': 'alçak, aşağılık',           # "piç" idi
    'помесь': 'melez, kırma',               # "piç" — tamamen yanlisti
    'ублюдок': 'alçak, aşağılık',           # "piç" idi
    'чайник': 'demlik, acemi',              # "beş kuruşluk adam" idi
    'бездельник': 'tembel, aylak',          # "beş kuruşluk adam" idi
    'таки': 'yine de, nihayet',             # "adam akıllı" idi
    'вдох': 'nefes alma, soluk',            # "ilham" idi
    'заживо': 'diri diri',                  # "yaşam dolu" idi
    'употребление': 'kullanım, tüketim',    # "içilen şey, istihdam" idi
    'вещать': 'yayın yapmak, nutuk çekmek',  # "ahkam kesmek, dağılmış" idi
    'клок': 'tutam, demet',                 # virgul eksikti
    'кромешный': 'zifiri, koyu',            # "tam" idi
    'донос': 'ihbar',                       # "itham" idi
    'наряжать': 'giydirmek, süslemek',      # "aranjman" idi

    # Icerik temizligi: birincil anlami notr olan kelimelerde kelimeyi
    # cikarmak yerine karsiligi sadelestiriliyor.
    'семя': 'tohum',                        # "tohum, meni" idi
    'вожделение': 'arzu, tutku',            # "arzu, şehvet" idi
    'живчик': 'canlı kişi, hareketli',      # "sperm hücresi" idi

    # Raporun oneri sutunu bu ikisinde serbest metin; mevcut ceviri dogru
    # oldugu icin oneriyi degil dogru olani yaziyoruz.
    'мазать': 'sürmek, bulaştırmak',
    'течь': 'akmak, sızmak',

    # ── 2026-08-17 taramasi: raporun disinda kalanlar ──
    # Ornek cumleleri dogru anlami ele veriyordu; her biri cumleyle dogrulandi.
    'царица': 'çariçe, kraliçe',       # "vezir, ibne" idi — satrancdaki vezir
                                        # anlamina takilip hakarete savrulmus
    'бычок': 'dana, izmarit',          # "sokra" — Turkce'de boyle bir karsilik yok
    'влагалище': 'vajina',             # "kapsül" — botanik yan anlami secilmis
    'потомство': 'soy, nesil',         # "döl" tek basina kaba kaciyordu
    'сыночек': 'oğulcuk, canım oğlum',  # "oğlan" — kucultme eki kaybolmus
    'мальчик': 'erkek çocuk, oğlan',   # A1 kelimesi tek basina "oğlan" idi
    'пацан': 'delikanlı, çocuk',       # "oğlan" idi
    'юноша': 'delikanlı, genç erkek',  # "oğlan" ikinci anlam olarak yanlisti
    'вымя': 'hayvan memesi',           # "meme" — hayvan anlami kayboluyordu
}

# Sozluge hic girmemesi gereken kayitlar: ya baska bir kelimenin cekimi
# ya da bu seviyede isi olmayan nadir bir bicim.
DROP = {
    'тута',    # "тут"un lehce bicimi; sozluk "dut" diye cevirmis
    'лета',    # "лето"nun cekimi
    'нашить',  # nadir; A1'de yeri yok
    'писька',  # cocuk agzi mustehcen; ogrenme uygulamasinda yeri yok
}

# Ornek cumlesi yanlis lemmaya baglanmis kayitlar (form tablosu hatasi).
# Yanlis cumle gostermektense cumlesiz birakiyoruz.
DROP_EXAMPLE = {
    'посол',   # "после" formu sanilmis
    'барин',   # "в баре"
    'звонкий',  # "звонок"
    'малый',   # alakasiz cumle
    'мочь',    # "мочи" (idrar) anlamiyla eslesmis

    # ── 2026-08-17: ornek cumle taramasi ──
    # Kelimenin kendisi masum, cumlesi ogrenme uygulamasina uygun degil:
    # tecavuz, kufur ya da cinsel icerik tasiyor.
    'коллега',        # tecavuz haberi
    'отчим',          # tecavuz anlatimi
    'интересовать',   # kufur
    'шлюха',          # kufur
    'юноша',          # cinsel icerik
    'сосок',          # gereksiz cinsel cagrisim
    'влагалище',      # birinci sahis cinsel anlati
    'бычок',          # hakaret iceriyor
    'долбануть',      # kufur
    'идеологический',  # kelimeyle alakasiz mecaz
    'сыночек',        # cocuk olumu iceren cumle
    'оплодотворение',  # cumle ortasindan baslayan bozuk metin
}

# ── Icerik derecelendirmesi icin cikarilan kayitlar ──
#
# Google Play'in IARC derecelendirme anketi cinsel icerik ve uyusturucu
# gondermeleri soruyor. Sozluk maddesi olmalari bunlari mesru kiliyor ama
# kullanici tereddutsuz bir derecelendirme istedi: bu kelimeler cikariliyor.
#
# BILEREK BIRAKILANLAR (cikarmak sozluge zarar verir, dereceye katkisi yok):
#   член   "uye, aza"        — A1 kelimesi (aile uyesi); cevirisi notr
#   голый  "ciplak"          — siradan sifat (ciplak gercek)
#   нагой  "ciplak"          — ayni, edebi kullanim
#   притон "batakhane"       — sucla ilgili, cinsel degil
#   аборт  "kurtaj"          — tibbi terim; Play'in derecelendirme
#                              baslıklarindan biri degil
CONTENT_DROP = {
    # cinsel
    'секс', 'сексуальный', 'гомосексуальность', 'гомосексуалист',
    'гомосексуал', 'проститутка', 'проституция', 'шлюха', 'сутенёр',
    'порнография', 'порнуха', 'насиловать', 'влагалище', 'мастурбация',
    'похоть', 'блуд', 'титька', 'бордель', 'инцест',
    # anatomi (ogrenci icin dusuk deger, derecelendirmede riskli)
    'сосок', 'сперма', 'яичко',
    # uyusturucu
    'наркотик', 'наркоман', 'героин', 'кокаин',
    # tek anlami ureme hucresi olan tibbi terim
    'сперматозоид',
}
