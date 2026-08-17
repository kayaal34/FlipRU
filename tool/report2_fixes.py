# -*- coding: utf-8 -*-
"""Ikinci tur dis inceleme raporu (2026-08-17, words_guven2.csv uzerine).

Birinci tur `report_fixes.py` icinde. Bu dosya ikinci turun bulgularini ve
o bulgularin yaninda veri setinin tamaminda yapilan taramada cikan ek
hatalari tasiyor. `apply_fixes.py` hepsini `assets/data/words.json` uzerine
idempotent bicimde uyguluyor.

Raporun kategorileri: yanlis ceviri, bozuk kodlama, Turkce sapkali harflerin
dusmesi, ornek cumlenin kelimeyle uyusmamasi, kufur/argo icerik, okunusun
Turkce kufur gibi gorunmesi, eksik ornek cumle.
"""

# ─────────────────────────────────────────────────────────────────────────
# 1) CEVIRI DUZELTMELERI            id -> (rusca kelime, dogru ceviri)
#
# Kimlik dogrulamasi icin Rusca kelime de yaziliyor; apply_fixes.py kelime
# tutmuyorsa satira dokunmuyor.
# ─────────────────────────────────────────────────────────────────────────
REPORT2_TR = {
    # ── Sistematik hata: "business" -> "hacet" ──
    # Ingilizce "do your business" deyimi karistirilmis.
    'w00674': ('бизнес', 'iş, ticaret'),
    'w02254': ('деловой', 'işle ilgili, ticari'),
    'w03373': ('предприятие', 'işletme, girişim'),

    # ── Sistematik hata: zarflar -> "mal" ──
    'w02194': ('хорошенько', 'iyice, güzelce'),
    'w05376': ('прилично', 'düzgünce, yeterince'),
    'w06927': ('благополучно', 'sağ salim'),

    # ── Anlami tamamen yanlis olanlar ──
    'w02882': ('дорожный', 'yol ile ilgili'),
    'w03043': ('магический', 'sihirli, büyülü'),
    'w03849': ('тревожный', 'endişe verici, kaygılı'),
    'w06349': ('ярый', 'ateşli, azılı'),
    'w08188': ('прохвост', 'alçak, hergele'),
    'w04206': ('шланг', 'hortum'),
    'w07805': ('устой', 'temel, dayanak'),

    # ── Yanina alakasiz fiil eklenmis olanlar ──
    'w01777': ('явный', 'aşikâr, apaçık'),
    'w05727': ('преобразование', 'dönüşüm, değiştirilme'),

    # ── Raporun listesinde olmayan, taramada cikan yanlis ceviriler ──
    'w07633': ('рассердить', 'kızdırmak, öfkelendirmek'),  # "cezbetmek" idi
    'w05447': ('дурень', 'ahmak, budala'),          # "inek, kelek" idi
    'w04136': ('соображать', 'kavramak, anlamak'),  # "aksetmek" idi
    'w05902': ('перила', 'korkuluk, tırabzan'),     # "cağ, küpeşte" idi
    'w03379': ('чин', 'rütbe, derece'),             # "aşama" idi
    'w03154': ('разряд', 'deşarj, kategori'),       # "yer, kategori" idi
    'w08093': ('кощунство', 'kutsala saygısızlık'),  # "dine tecavüz" idi
    'w04215': ('сотрясение', 'sarsıntı'),           # "sarsım" diye bir sozcuk yok
    'w03533': ('по-видимому', 'görünüşe göre'),     # "belki" idi — anlam kaymasi
    'w05058': ('по-хорошему', 'iyilikle, dostça'),  # "ala" idi
    'w06678': ('кое-где', 'bazı yerlerde'),         # "ara sıra" zaman zarfiydi
    'w05115': ('кое-куда', 'bir yerlere'),
    'w02140': ('кутить', 'cümbüş yapmak, eğlenmek'),  # 45 karakterlik aciklamaydi
    'w08494': ('лирика', 'şiir, lirik şiir'),       # "şıır" yazim hatasi

    # ── Ayni anlam iki kez yazilmis olanlar (sapkali/sapkasiz cift) ──
    'w01159': ('рыба', 'balık'),                    # "balık, balik"
    'w01950': ('любовник', 'sevgili'),              # "âşık, aşık"
    'w03878': ('штаб-квартира', 'karargâh, merkez'),  # "karargâh, karargah"
    'w03941': ('обычай', 'gelenek, örf'),           # "adet, âdet"
    'w04086': ('кукуруза', 'mısır'),                # "mısır, misir"
    'w04152': ('отвращение', 'tiksinti, bıkkınlık'),  # "bıkkınlık, bikkinlik"
    'w06725': ('плацента', 'plasenta'),             # "plâsenta, plasenta"
    'w07835': ('удовлетворительный', 'tatminkâr, yeterli'),
    'w08213': ('сороковой', 'kırkıncı'),            # "kırkınci, kırkıncı"
}

# ─────────────────────────────────────────────────────────────────────────
# 2) OKUNUS DUZELTMELERI
#
# Hecelere bolunmus okunus, Turkce okuyan biri icin kufur gibi gorunuyordu.
# Sasirtici yan: uc kaliptaki duzeltme ayni zamanda daha DOGRU okunus —
# Rusca "сек-" hecesi "sek", "домкрат"in vurgusu da son hecede.
# ─────────────────────────────────────────────────────────────────────────
REPORT2_TRANSLIT = {
    'w00735': "seks-u-AL'-nıy",        # сексуальный
    'w02001': "sek-ri-TAR'",           # секретарь
    'w03159': 'sek-ri-TAR-şa',         # секретарша
    'w04586': 'ga-ma-seks-u-a-LİST',   # гомосексуалист
    'w07737': "ga-ma-seks-u-AL'-nast'",  # гомосексуальность
    'w08421': 'ga-ma-seks-u-AL',       # гомосексуал
    'w04854': 'VI-peç-ka',             # выпечка
    'w07747': 'dam-KRAT',              # домкрат
}

# ─────────────────────────────────────────────────────────────────────────
# 3) ORNEK CUMLE DEGISIMI          id -> (rusca cumle, turkce cumle)
# ─────────────────────────────────────────────────────────────────────────
REPORT2_EXAMPLE = {
    # ── Bozuk kodlama: CP1251 metni yanlis cozulmus ──
    'w07633': ('Ты рассердил моего сына. Он тебя убьёт.',
               'Oğlumu kızdırdın. Seni öldürecek.'),
    'w05447': ('Да, ты дурень! Ты хочешь делать кресла-качалки.',
               'Evet, sen bir ahmaksın! Sallanan sandalye yapmak istiyorsun.'),
    # Bunlarin cumlesi hem bozuktu hem kelimeyle alakasizdi.
    'w05748': ('Дно реки покрыто мягким илом.',
               'Nehrin dibi yumuşak çamurla kaplı.'),
    'w08402': ('У ребёнка начался отит, и врач выписал капли.',
               'Çocukta orta kulak iltihabı başladı, doktor damla yazdı.'),
    'w08750': ('Из нута готовят хумус.',
               'Nohuttan humus yapılır.'),
    # Arapca alfabeyle yazilmis sozluk artigi kalmis.
    'w06925': ('В его речи не было ни одной непристойности.',
               'Konuşmasında tek bir uygunsuz söz yoktu.'),

    # ── Turkce sapkali harfler dusmus ──
    'w04215': ('Программа «Выше головы» посвящена сотрясению мозга у детей.',
               'Heads Up çocuklarda beyin sarsıntısı ile ilgili.'),
    'w05902': ('Там практически нет перил. Она не соответствует никаким '
               'стандартам.',
               'Görünürde hiç korkuluk yok. Kurallara uygun değil.'),
    'w08009': ('И мне в нём особенно нравится удачно выбранный тон изложения.',
               'Ve bunda özellikle sevdiğim şey, anlatımın iyi seçilmiş tonu.'),
    'w04581': ('Если не ошибаюсь, динамит использовали только для '
               'одиннадцати построек.',
               'Yanılmıyorsam yalnızca on bir yapı için dinamit kullandılar.'),
    'w05693': ('К сожалению, вскоре заказчик обанкротился.',
               'Maalesef müşteri kısa süre sonra iflas etti.'),
    'w06240': ('Это качество присуще всем большим городам.',
               'Bu özellik bütün büyük şehirlere özgüdür.'),
    'w06788': ('В холодильнике нашлось тухлое яйцо.',
               'Buzdolabında çürük bir yumurta bulundu.'),
    'w07822': ('Их движения были синхронными.',
               'Hareketleri senkronikti.'),
    'w08629': ('Кликните по ссылке, чтобы открыть страницу.',
               'Sayfayı açmak için bağlantıya tıklayın.'),
    # Hem sapka eksikti hem cumle kelimeyle alakasizdi.
    'w05171': ('Родители совсем распустили мальчика.',
               'Ailesi çocuğu tamamen şımarttı.'),

    # ── Cumle cifti birbirini karsilamiyordu ──
    'w03379': ('Он получил новый чин.', 'Yeni bir rütbe aldı.'),
    'w08093': ('Для верующих это было настоящее кощунство.',
               'İnananlar için bu gerçek bir kutsala saygısızlıktı.'),
    'w06032': ('Эти три понятия образуют триаду.',
               'Bu üç kavram bir üçleme oluşturuyor.'),
    'w08299': ('Его мать работала прачкой.',
               'Annesi çamaşırcı olarak çalışıyordu.'),
    'w04136': ('Он быстро соображает.', 'Çabuk kavrıyor.'),
    # Wikipedia tarih listelerinden yanlis eslesmis ciftler. "тут" ornegi
    # aslinda Desmond Tutu'nun soyadiyla eslesmisti.
    'w00143': ('Тут очень тихо.', 'Burası çok sessiz.'),
    'w03711': ('Катер быстро подошёл к берегу.',
               'Motorbot hızla kıyıya yaklaştı.'),
    'w06516': ('Команда взяла реванш в следующем матче.',
               'Takım sonraki maçta rövanşı aldı.'),
    'w06831': ('Конклав избрал нового папу.', 'Konklav yeni papayı seçti.'),
    'w07523': ('Платье сшито из тонкого батиста.',
               'Elbise ince keten bezinden dikilmiş.'),
    'w08096': ('Адъютант передал приказ генерала.',
               'Yaver generalin emrini iletti.'),
    'w08494': ('Он любит русскую лирику.', 'Rus lirik şiirini sever.'),
    'w07989': ('Стрихнин — сильный яд.', 'Striknin güçlü bir zehirdir.'),

    'w07977': ('Он написал сонет о любви.', 'Aşk üzerine bir sone yazdı.'),
    'w08933': ('Кража церковного имущества считалась святотатством.',
               'Kilise malı çalmak kutsal şeyleri çalma sayılırdı.'),
    # Cumlenin sonunda basibos bir "^" kalmis.
    'w08368': ('Для очень сухой кожи тальки и пудры не подходят.',
               'Çok kuru ciltler için talk ve toz uygun değildir.'),

    # ── Kufur iceren cumle ──
    # Sarki sozunden alinmis, hem kufurlu hem kelimenin anlamiyla alakasizdi.
    'w02292': ('Он сломал сучок и бросил его в костёр.',
               'Bir dalı kırıp ateşe attı.'),

    # ── Rakam uyusmazligi: Rusca taraf dogru (1894), Turkce taraf yanlisti ──
    'w08591': ('Он был обнаружен в 1894 году офицером французского генштаба.',
               '1894 yılında Fransız Genelkurmay subayı tarafından '
               'keşfedilmişti.'),

    # ── Yazim hatalari ──
    'w03154': ('В наши дни она выдерживает 2000 циклов заряд-разряд.',
               'Günümüz bataryaları 2 bin kere kullanılabiliyor.'),
    'w01965': ('Вот наш вариант объявлений о продаже б/у автомобилей.',
               'Bu, kullanılmış araba bayileri için olan reklamımız.'),

    # ── Ornek cumlesi hic olmayanlar ──
    'w00499': ('Она вернулась домой с радостной новостью.',
               'Sevindirici bir haberle eve döndü.'),
    'w00639': ('Оба брата учатся в университете.',
               'İki kardeş de üniversitede okuyor.'),
    'w01253': ('Меня интересует русская литература.',
               'Rus edebiyatı beni ilgilendiriyor.'),
    'w01874': ('Давай поедем куда-нибудь на выходных.',
               'Hafta sonu bir yere gidelim.'),
    'w01996': ('Давай встретимся где-нибудь в центре.',
               'Merkezde bir yerde buluşalım.'),
    'w02140': ('Они всю ночь кутили в ресторане.',
               'Bütün gece lokantada cümbüş yaptılar.'),
    'w02185': ('Кот вылез из-под стола.', 'Kedi masanın altından çıktı.'),
    'w03422': ('Каждый понимает эти слова по-своему.',
               'Herkes bu sözleri kendince anlıyor.'),
    'w03533': ('По-видимому, он уже ушёл.', 'Görünüşe göre çoktan gitmiş.'),
    'w03878': ('Штаб-квартира компании находится в Москве.',
               'Şirketin karargâhı Moskova\'da.'),
    'w04740': ('Он сделал меткий выстрел.', 'İsabetli bir atış yaptı.'),
    'w05058': ('Давай решим этот вопрос по-хорошему.',
               'Bu meseleyi iyilikle çözelim.'),
    'w05115': ('Мне нужно съездить кое-куда.',
               'Bir yerlere gitmem gerekiyor.'),
    'w06678': ('Кое-где на дороге ещё лежал снег.',
               'Yolun bazı yerlerinde hâlâ kar vardı.'),
    'w06856': ('Это прямо-таки чудо.', 'Bu âdeta bir mucize.'),
    'w07869': ('Ты видел его где-либо ещё?',
               'Onu başka bir yerde gördün mü?'),
    'w08573': ('Молоко киснет на жаре.', 'Süt sıcakta ekşiyor.'),
}

# ─────────────────────────────────────────────────────────────────────────
# 4) SOZLUKTEN CIKARILAN KAYITLAR
# ─────────────────────────────────────────────────────────────────────────
# недоносок: sozlukte notr tibbi terim ("erken doğmuş") diye yaziliyor, ama
# modern Rusca'da neredeyse yalnizca ağır bir hakaret olarak kullaniliyor —
# veri setindeki kendi ornek cumlesi de hakaret anlamindaydi. Dogru cevirisi
# yazilsa uygulamaya kufur girerdi; notr birakilsa ogrenci kelimeyi masum
# sanip kullanirdi. Ikisi de kotu oldugu icin kayit cikariliyor.
# (Ayni gerekce ile 'писька' birinci turda cikarilmisti.)
REPORT2_DROP = {'w07641'}
