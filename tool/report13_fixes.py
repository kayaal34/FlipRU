# -*- coding: utf-8 -*-
"""Rapor 13 (rapor_1of4..4of4.md) duzeltmeleri.

Kapsam: butun veritabani icin yanlis karsilik / yanlis cevrilmis ornek
cumle taramasi (tema, tur, okunus bu turda kapsam disi).
"""

# id -> (beklenen ru, yeni tr)
REPORT13_TR = {
    'w06210': ('рожок', 'külah'),
    'w04933': ('кишеть', 'kaynamak'),
    'w05732': ('выручать', 'yardım etmek'),
    'w06757': ('налёт', 'tabaka, cila'),
    'w04871': ('коньяк', 'konyak'),
    'w04595': ('восхищение', 'hayranlık'),
    'w05513': ('наём', 'işe alma'),
    'w02406': ('жизненный', 'hayati'),
    'w02445': ('ствол', 'namlu, gövde (ağaç)'),
    'w06913': ('щипать', 'çimdiklemek, otlamak'),
    'w04532': ('последовательность', 'dizilim'),
}

# id -> (beklenen ru, yeni exTr) -- exRu ayni kaliyor, sadece ceviri duzeliyor
REPORT13_EXAMPLE = {
    'w05098': ('плот', 'Tina kaçırıldı, bir sala bağlandı ve şelaleye atıldı.'),
    'w05008': ('гамма', 'Aynı gamda çalacağız.'),
    'w05444': ('пенсионер', 'Onun bir işi yok. O emeklidir.'),
    'w05926': ('коса', 'Ve orada, ufukta, tırpanlı ölüm duruyor.'),
    'w06021': ('гитарист', 'Tek bir kağıttan gitarist, tek bir kağıttan basist.'),
    'w05286': ('ржавый', 'Bu başvurular, paslı dişlileri yeniden döndürmeye başladı.'),
    'w05331': ('спектр', 'Bunun geniş bir yelpazede sonuçları olduğunu düşünüyorum.'),
    'w05671': ('арка', 'Vitraylı camlarla kaplı kemerler ise çok daha ilgi çekici.'),
    'w05702': ('знамя', "Bu mesela, öğle yemeği yerken 'Yıldızlı Bayrak'ı dinleyip Listerin içmek gibi bir şey."),
    'w06550': ('конфедерация', 'Kayıtlara göre, Afro-Amerikalılardan daha fazla Konfederasyon bayrağı saydım.'),
    'w06388': ('дюна', "Yine de 'Dune'daki en önemli grup Fremenlerdir."),
    'w05002': ('паралич', 'Felç geçirmeden önce bir atletti. Şimdi ise bir para-atlet.'),
    'w05019': ('одеколон', 'Sahte kolonya satın alabilirsiniz.'),
    'w05010': ('чучело', 'Bu onun kuklasıydı: ölü, çıplak, tavandan sarkıyordu.'),
    'w05207': ('староста', 'Bir Rus köyünün muhtarıyla konuştu.'),
    'w05319': ('разрушитель', 'Statükoyu savunanlara ve yıkanlara sesleniyorum.'),
    'w05545': ('космонавт', 'Lenin, üstünü battaniyeyle örterek kozmonotla sohbet ediyor.'),
    'w05571': ('бесчисленный', 'Ve bu değişiklikler sayısız fikirden etkilendi.'),
    'w05606': ('прекращаться', "Bu büyüme 90'larda bile durmadı."),
    'w05638': ('беспечный', 'Oldukça kaygısız bir ortamda büyüdüm.'),
    'w05767': ('тату', 'İnsanlar dövmelerinden pişman oluyor mu?'),
    'w05965': ('ультразвук', 'Ayrıca yarasalar gibi yüksek frekanslı tiz sesler çıkararak uçmayız.'),
    'w06239': ('аппаратура', 'Eskiden böyle bir donanımımız yoktu.'),
    'w06468': ('трубить', 'Ve bunları herkese duyurursak, bizden hoşlanmayabilirler.'),
    'w06542': ('непорочный', 'Onun gebeliğinin lekesiz olduğunu bilmeden.'),
    'w06621': ('приручить', 'Denizin gücünü evcilleştirmeyi sağlayan yelken ve direği icat etti.'),
    'w06624': ('колотить', 'Hepiniz kendi kafanıza vurabilir misiniz?'),
    'w06656': ('настоятель', 'Magd kilisenin başrahibidir.'),
    'w06673': ('футляр', 'Bu, yarı saydam bir kılıf.'),
    'w04558': ('гидра', 'Yenilen yılanın anısına Hidra takımyıldızına bu ad verildi.'),
    'w04573': ('ягода', 'Muhtemelen Frank Gehry ile aynı kumaştan olduğumu söylersiniz.'),
    'w04602': ('вражда', "Al Jazeera'ya karşı kabile düşmanlığını kullandılar."),
    'w04750': ('прочесать', "Otistik çocukları bulmak için Londra'nın Camberwell banliyösünü didik didik araştırdılar."),
    'w04779': ('коттедж', 'Sosyal hizmetleri, sponsorları ve tasarımcıları bir araya getiren geniş bir koalisyon, müstakil evler inşa etti.'),
    'w04856': ('реветь', 'Çocuk gibi ağlama!'),
    'w04911': ('тугой', "ABD'de hükümet kendini sıkı bağlarla bağlamıştır."),
    'w05591': ('скафандр', 'Dalış kıyafetinin kaskından baloncukların yükseldiğini görüyorsunuz.'),
    'w06616': ('кузнечик', 'Bu fotoğraflarda çayır çekirgelerinin çiftleşmesini görüyorsunuz.'),
    'w06625': ('колье', 'Kusursuz aşk hayatı -- kusursuz kolye ve pırlanta yüzükle sembolize edilmiş.'),
    'w06220': ('угонять', 'Hugo bir araba çalar ve polisten kaçmaya çalışır.'),
    'w06774': ('шнур', 'Cihazın kablosu bu yuvaya takılıyordu.'),
    'w06961': ('паштет', 'Sana tavşanı paştetten başka bir şekilde servis ettim mi hiç?'),
    'w07067': ('несерьёзный', 'Güldüler. Bunun ciddi olmadığını düşündüler.'),
    'w07409': ('генезис', 'Hastalığın kökenini daha iyi biliyorum.'),
    'w07456': ('небывалый', 'Sadece erişilebilirlikten değil, görülmemiş bir erişilebilirlikten bahsediyoruz.'),
    'w07745': ('сервиз', 'Kısa süre içinde, aristokratların evlerinde çikolata servisi eksik olmazdı.'),
    'w08723': ('смердеть', 'Pöh, bu kaynattığın şey ne kadar da pis kokuyor. Bu da ne böyle?'),
    'w08728': ('лексика', 'Aslında bazen kelime hazinemizi fakirleştirir.'),
    'w08912': ('малодушный', 'Tüm şüpheyi ortadan kaldırın, geriye kalan şey inanç değil, mutlak, korkak bir kanaat olacaktır.'),
    'w08936': ('беспамятство', 'Ve onları çıldırırcasına sevmek. Tıpkı senin gibi.'),
    'w01764': ('славный', 'Ne şirin bir ufaklık!'),
    'w02120': ('акт', 'Bu opera beş perdeden oluşuyor.'),
    'w01279': ('родной', "Avrupa Birliği'ndeki en yaygın ana dil Almanca'dır."),
    'w01762': ('фонд', "Ulusal Bilim Vakfı'nda bunu seçen insanlar var."),
    'w02293': ('оплата', "Hesabımızın ödemesini Ali'ye yaptık."),
    'w03779': ('чиновник', 'Memurlar nasıl çalıyorlarsa öyle çalmaya devam edecekler.'),
}

# ru/tr birbirini tutuyor ama ornek cumle baska bir kelimeyle karismis /
# eksik / anlamsiz -- guvenli tarafta kalip siliniyor.
REPORT13_CLEAR_EXAMPLE = {
    'w05764', 'w04552', 'w06739', 'w05747', 'w06082', 'w05642',
    'w05064', 'w00723', 'w00859', 'w02167', 'w05946',
}

# gecersiz / kopya baslik kelime
REPORT13_DROP = set()
