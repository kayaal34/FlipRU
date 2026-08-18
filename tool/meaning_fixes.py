# -*- coding: utf-8 -*-
"""Ilk karsiligi kotu olan kayitlarin duzeltmeleri.

Ikinci anlamlari kaldirdiktan sonra ortaya cikan iki sorun var:

1. **Eskil karsilik.** Ilk sirada gunumuz Turkcesinde kullanilmayan bir
   kelime duruyor: "deveran", "nispet", "hunhar", "musrif", "mutalaa".
   Ogrenci bunlari hicbir yerde gormez.

2. **Sira tersligi.** Iyi karsilik ikinci siradaydi ve silindi:
   "besige ait" kaldi, "ninni" gitti; "kagit" gitti, "burokratik" kaldi.

Bir de bunlardan bagimsiz, literal cevrilmis hantal karsiliklar var:
"su ile ilgili", "goze ait", "yenecek gibi olmayan". Sifat karsiliklarinda
Turkce zaten ismi sifat gibi kullaniyor ("su sporlari", "goz doktoru"),
uzun tamlamaya gerek yok.

Anahtar kelime kimligi; Rusca kelime ayrica dogrulaniyor.
"""

# (id, beklenen Rusca, yeni Turkce karsilik)
MEANING_FIXES = {
    # --- eskil karsiliklar ---
    'w01046': ('прочитать', 'okumak'),                  # "mütalaa etmek" idi
    'w04662': ('неприличный', 'uygunsuz'),              # "münasebetsiz" idi
    'w05408': ('неподходящий', 'uygunsuz'),             # "münasebetsiz" idi
    'w06283': ('неподобающий', 'yakışıksız'),           # "münasebetsiz" idi
    'w06756': ('соотношение', 'oran'),                  # "nispet" idi
    'w06791': ('пропорция', 'orantı'),                  # "nispet" idi
    'w06852': ('сдержанность', 'ölçülülük'),            # "ihtiyat" idi
    'w07296': ('омут', 'girdap'),                       # "anafor" idi
    'w07537': ('водоворот', 'girdap'),                  # "anafor" idi
    'w07847': ('круговорот', 'döngü'),                  # "deveran" idi
    'w07961': ('лютый', 'vahşi'),                       # "hunhar" idi
    'w08557': ('расточительный', 'savurgan'),           # "müsrif" idi
    'w08865': ('мот', 'savurgan'),                      # "müsrif" idi

    # --- iyi karsilik ikinci siradaydi ---
    'w06577': ('бумажный', 'kâğıt'),                    # "bürokratik" kalmisti
    'w07700': ('колыбельный', 'ninni'),                 # "beşiğe ait" kalmisti
    'w08973': ('расчесать', 'taramak'),                 # "kaşıyarak tahriş etmek"
    'w07674': ('силач', 'pehlivan'),                    # "güçlü kuvvetli adam"
    'w08805': ('карабин', 'karabina'),                  # "kısa namlulu tüfek"
    'w08688': ('несъедобный', 'yenmez'),                # "yenecek gibi olmayan"
    'w08061': ('сом', 'yayın balığı'),                  # "bayağı yayın balığı"
    'w04352': ('ужасающий', 'korkunç'),                 # "insanın kanını donduran"
    'w03587': ('задыхаться', 'boğulmak'),               # "nefes darlığı çekmek"
    'w07541': ('меховой', 'kürklü'),                    # "kürk" (sifat olmali)
    'w06701': ('работница', 'kadın işçi'),              # "bayan işçi"
    'w06595': ('загорелый', 'bronzlaşmış'),             # "yanmış"

    # --- literal, hantal tamlamalar ---
    'w01738': ('боевой', 'savaş'),                      # "savaşa ait"
    'w01831': ('космический', 'uzay'),                  # "uzaya ait"
    'w02254': ('деловой', 'iş'),                        # "işle ilgili"
    'w03772': ('энергетический', 'enerji'),             # "enerji ile ilgili"
    'w03823': ('водный', 'su'),                         # "su ile ilgili"
    'w03899': ('весенний', 'ilkbahar'),                 # "ilkbahara ait"
    'w04526': ('птичий', 'kuş'),                        # "bir kuşunkini andıran"
    'w05232': ('глазной', 'göz'),                       # "göze ait"
    'w06140': ('топливный', 'yakıt'),                   # "yakıtla ilgili"
    'w06748': ('конский', 'at'),                        # "ata ait"
    'w06978': ('радиационный', 'radyasyon'),            # "radyasyona ait"
    'w07428': ('световой', 'ışık'),                     # "ışıkla ilgili"
    'w04092': ('избирательный', 'seçici'),              # "seçimle ilgili"
    'w08647': ('выборный', 'seçimle gelen'),            # "seçimle ilgili"
    'w03390': ('всемогущий', 'her şeye gücü yeten'),    # "her şeye kadir"
    'w04822': ('кровный', 'öz'),                        # "kan bağı olan"
    'w06079': ('согласовать', 'uzlaştırmak'),           # "uyumlu hale getirmek"
    'w06135': ('весельчак', 'neşeli kimse'),            # "şen şakrak kişi"
    'w07246': ('простолюдин', 'halktan biri'),          # "sıradan halktan kimse"
    'w08997': ('слепнуть', 'körleşmek'),                # "göz nurunu kaybetmek"
    'w01243': ('когда-либо', 'hiç'),                    # "herhangi bir zaman"
    'w04842': ('грохнуть', 'gümbürdetmek'),             # "güm diye düşürmek"

    # --- yanlis karsiliklar ---
    'w07604': ('тарантул', 'tarantula'),      # "tarantel" idi; o bir dans
    'w08819': ('фарси', 'Farsça'),            # "farisi" idi
    'w06690': ('диагностика', 'tanı'),        # "diagnostik" Turkce degil
}

# Okunusu bicimsiz kalmis kayitlar: hece bolunmemis, vurgu isaretlenmemis.
TRANSLIT_FIXES = {
    'w06045': ('феномен', 'fi-na-MEN'),
    'w06576': ('морфин', 'mar-FİN'),
    'w07878': ('будапешт', 'bu-da-PEŞT'),
    'w07892': ('сингапур', 'sin-ga-PUR'),
    'w08632': ('нептун', 'nip-TUN'),
}
