# -*- coding: utf-8 -*-
"""Dokuzuncu tur: dosya 7 (w06027-w07028) denetimi (2026-08-29).

Sistematik "yi-" transkripsiyon hatasi bu dosyada da bildirilmisti, ama
tam veri seti taramasi 0 kayit gösterdi: rapor7'de (dosya3-4 turunda)
zaten tum veri setinde duzeltilmisti; kullanicinin dosya7 metni o
duzeltmeden once alinmis bir anlik goruntude hazirlanmis olmali. Bu
yuzden translit icin yeni bir madde yok.
"""

REPORT9_TR = {
    'w06036': ('проводка', 'kablo tesisatı'),
    'w06314': ('проспект', 'cadde, bulvar'),
    'w06998': ('единичный', 'tek, münferit'),
    'w06723': ('безрассудство', 'düşüncesizlik, pervasızlık'),
    'w06325': ('тупость', 'aptallık'),
    'w06144': ('искушать', 'ayartmak, baştan çıkarmak'),
    'w06832': ('гадалка', 'falcı'),
    'w06043': ('вылазка', 'baskın, huruç'),
    'w06037': ('наименьший', 'en küçük'),
    'w06084': ('воскресение', 'diriliş'),
    'w06113': ('тирания', 'tiranlık, zorbalık'),
    'w06101': ('алкаш', 'ayyaş'),
    'w06117': ('скрип', 'gıcırtı'),
    'w06649': ('утёс', 'uçurum, sarp kayalık'),
    'w06808': ('ампула', 'flakon (ilaç)'),
    'w06652': ('сена', 'kuru ot'),
    'w06820': ('кастрировать', 'hadım etmek'),
    'w06218': ('шайба', 'hokey diski'),
    'w06431': ('лайнер', 'yolcu gemisi'),
    'w06322': ('казак', 'Kazak'),
    'w06565': ('аполлон', 'Apollon'),
    'w06782': ('меркурий', 'Merkür'),
    'w06805': ('ливан', 'Lübnan'),
    'w06428': ('слесарь', 'tesisatçı'),
}

# id -> (ru, yeni ru)
REPORT9_RU = {
    'w06652': ('сена', 'сено'),
    'w06805': ('ливан', 'Ливан'),
}

REPORT9_ACCENTED = {
    'w06576': 'морфи́н',
}

# id -> pos
REPORT9_POS = {
    'w06689': 'numeral',   # devyatnadtsat'
    'w06493': 'adjective',  # beremennaya
}

REPORT9_EXAMPLE = {
    'w06649': ('Это не какой-то мелкий утёс. Это высота 32-этажного офиса в деловом центре города.',
               'Bu, ufak bir uçurum değil. Şehir merkezindeki 32 katlı bir ofis binası kadar yüksek.'),
    'w06539': ('В каждом залоговом центре будут работать поручители.',
               '(Alkışlar) Her bölgede kefillerden oluşan bir ekip görev yapacak.'),
    'w06478': ('Я не верю в гороскопы, потому что я скорпион.',
               'Burçlara inanmıyorum çünkü ben bir akrebim.'),
    'w06633': ('Он действительно был графом, сыном шведского эмигранта.',
               'Gerçekten de bir kontmuş, İsveçli bir göçmenin oğluymuş.'),
    'w06131': ('10 апреля Северная Корея заправила свои баллистические ракеты.',
               "10 Nisan'da Kuzey Kore, balistik füzelerini yakıtla doldurdu."),
    'w06765': ('Каждый год в академию поступают более 2,5 тысяч курсантов.',
               'Her yıl akademiye 2.500\'den fazla öğrenci kabul ediliyor.'),
    'w06349': ('Так вот, я не собиралась становиться ярым борцом за многообразие.',
               'Yani, çeşitlilik için ateşli bir savunucu olmaya niyetim yoktu.'),
    'w06930': ('А на что жить чёрному братку в колледже?',
               'Peki siyahi bir gencin üniversitede geçimini nasıl sağlaması bekleniyor?'),
    'w06820': ('А глядя, как ты вытирался, мечтал подпрыгнуть и кастрировать.',
               'Havluyla kurulanışını izlerken üzerine atlayıp seni hadım etmek istedim.'),
    'w06452': ('Вот мой карманный глобус с указанием залежей нефти.',
               'İşte petrol yataklarını gösteren cep küremim.'),
    'w06585': ('Помните, когда я показал вам эти кусочки мозаики?',
               'Size gösterdiğim şu mozaik parçalarını hatırlıyor musunuz?'),
    'w06755': ('Это дало возможность южанам лучше укрепить свои позиции.',
               'Bu, güneylilerin konumlarını daha iyi pekiştirmesine olanak sağladı.'),
    'w06715': ('Ни на одного свидетеля расстрелов Базилевский сослаться не смог.',
               'Bazilevski, kurşuna dizmelere hiçbir tanık gösteremedi.'),
    'w06056': ('Я даже выучила реплики из «Монолога вагины».',
               "Hatta 'Vajina Monologları'ndan replikler bile ezberlemiştim."),
    'w07011': ('Так «Мотылёк» обретает свободу.', 'Böylece "Güve" özgürlüğüne kavuşuyor.'),
    'w06061': ('Из обуви широко использовались кожаные башмаки.',
               'Ayakkabı olarak yaygın şekilde deri çarıklar kullanılıyordu.'),
    'w06094': ('Снова в обойме.', 'Yine şarjörde.'),
    'w06126': ('Не из той, что мы метили!', 'İşaretlediğimiz o değildi!'),
    'w06150': ('Иване, не гаси огонь, он сам должен прогореть.',
               'İvan, ateşi söndürme, kendiliğinden sönsün.'),
    'w06670': ('Этот самец шимпанзе набрёл на кучу опавших переспелых слив.',
               'Bu erkek şempanze, aşırı olgunlaşmış düşmüş eriklerden oluşan bir yığına rastladı.'),
    'w06975': ('Его рог проткнул мне трахею и пищевод, воткнулся в позвоночник и сломал шею.',
               'Boynuzu soluk borumu ve yemek borumu delip omurgama saplandı ve boynumu kırdı.'),
    'w06855': ('Третье: сухожилия крепятся на плечах для максимального натяжения.',
               'Üçüncüsü: kirişler, maksimum gerilim için omuzlara bağlanır.'),
    'w06082': ('Что нам нужно решить?', 'Bizim ne karar vermemiz gerekiyor?'),
    'w06066': ('Три больших растяжки для груди, ребята, вы готовы?',
               '3 büyük göğüs esnetmesi, hazır mıyız?'),
    'w06216': ('Он собирается съесть эту изгородь на обед.',
               'Bu çiti akşam yemeği için yemeyi planlıyor.'),
    'w06470': ('Он вводил шар в артерию, имитируя блокаду, т.е. сердечный приступ.',
               'Arteri tıkamak için yani kalp krizini simüle etmek için, balonu şişirilmiş olarak tuttu.'),
    'w06703': ('Они создают искусственную среду, чтобы мы могли утолить свою жажду цветов.',
               'Yapay bir ortam yaratıp, kendi renk bağımlılığımızı tatmin etmemizi sağlıyorlar.'),
    'w06427': ('Огонь бушует глубоко в океане, извергаясь прямо сейчас.',
               'Ayrıca okyanusun derinlerinde şu sıralar yanan ateş var.'),
    'w06096': ('Мы должны прекратить относиться к болезни как к позору и травмировать больных.',
               'Hastalıkları damgalamayı bırakıp mağdurlara travma yaşatmaya son vermeliyiz.'),
    'w06155': ('Впоследствии я стала представителем Шотландии по вопросам ВИЧ.',
               'Hemen ardından İskoçya ve HIV için bir elçi oldum.'),
    'w06456': ('На пятой неделе, можно видеть ранние предсердия и желудочки.',
               'Beşinci haftada, ilk atriyum ve ventrikülü görebilirsiniz.'),
    'w06465': ('Я слышал, что кто-то прокричал моё имя.', 'Birinin adımı bağırdığını duydum.'),
    'w06529': ('Они даже составили симпатичную рецензию на мою книгу.',
               'Kitabım için yazılan güzel bir eleştiri bile kaleme almışlardı.'),
    'w06533': ('Раз им это нужно, то как насчёт нас, их подзащитных?',
               'Onların buna ihtiyacı varsa, ya bizim gibi müvekkilleri ne olacak?'),
    'w06571': ('"Пума", дым идет прямо на нас, прекрати завесу.',
               "'Puma', duman doğrudan üzerimize geliyor, sis perdesini durdurun."),
    'w06596': ('У этой бандитской зеленой стрелы есть множество устройств.',
               'Şu Yeşil Ok haydudunun bir sürü küçük aleti var.'),
    'w06807': ('Спорт предотвращает болезни.', 'Spor, hastalıkların meydana gelmesini engeller.'),
    'w06971': ('Твоя жизнь не должна быть монотонной, посредственной, бессмысленной.',
               'Monoton, sıradan ve anlamsız bir hayat yaşama.'),
    'w07005': ('Что-то типа пилы, ножей, серпа и топора, которые я заворачивал в тряпку.',
               'Testere, bıçak, orak ve balta gibi bir bez parçasına sakladığım şeyler.'),
    'w07007': ('Многое из того, что попадает в инвентарь абсолютно бесполезно.',
               'Envantere giren şeylerin çoğundan hiç yararlanılmamıştır.'),
    'w06484': ('В моей руке находится фантом, имитирующий клеточную ткань.',
               'Elimde, doku benzeri, silikondan yapılmış bir fantom var.'),
    'w06369': ('Эти гусеницы даже не пытались улучшить свою жизнь.',
               'Bu tırtıllar kendi hayatlarını iyileştirmek için hiçbir şey yapmaya çalışmadı.'),
    'w06341': ('Но есть некоторое беспокойство, что это несколько неестественно.',
               'Ama bunun biraz doğal olmadığına dair bir endişe var.'),
    'w06598': ('А иррациональные числа — это как темнота вокруг них.',
               'İrrasyonel sayılar ise etraflarındaki karanlık gibidir.'),
    'w06364': ('У Али в последнее время частая оральная диарея.',
               'Ali\'nin son zamanlarda sık sık ishali oluyor.'),
}

# Baslikla ilgisi olmayan / kaynagi kirik ornekler: bos birak.
REPORT9_CLEAR_EXAMPLE = {
    'w06055', 'w06154', 'w06299', 'w06300', 'w06304', 'w06318', 'w06383',
    'w06415', 'w06842', 'w07003', 'w06769', 'w06503', 'w06077', 'w06330',
    'w06887',
    # detayi verilmeyen "TR-RU bagi kopmus" listesi
    'w06095', 'w06121', 'w06157', 'w06161', 'w06163', 'w06168', 'w06169',
    'w06170', 'w06178', 'w06204', 'w06223', 'w06231', 'w06245', 'w06252',
    'w06280', 'w06298', 'w06334', 'w06393', 'w06405', 'w06447', 'w06464',
    'w06508', 'w06527', 'w06575', 'w06661', 'w06816', 'w06824', 'w06900',
    'w06935', 'w06938', 'w07014', 'w07023',
}

REPORT9_CLEAR_THEME = {
    'w06047', 'w06135', 'w06167', 'w06300', 'w06374', 'w06375', 'w06543',
    'w06606', 'w06845', 'w06944', 'w07020', 'w06036', 'w06094', 'w06109',
    'w06734', 'w06458', 'w06523', 'w06533', 'w06124', 'w06391', 'w06972',
    'w06069', 'w06331', 'w06644', 'w06396', 'w06422', 'w06806', 'w06935',
    'w06139', 'w06208', 'w06692', 'w06119', 'w06531', 'w06656', 'w06695',
    'w06066', 'w06071', 'w06145', 'w06165', 'w06183', 'w06204', 'w06355',
    'w06390', 'w06444', 'w06485', 'w06483', 'w06554', 'w06577', 'w06584',
    'w06699', 'w06833', 'w06902', 'w06985', 'w07019',
}
