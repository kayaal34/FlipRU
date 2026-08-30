# -*- coding: utf-8 -*-
"""Altinci tur: kullanicinin 1000'er kelimelik parcalar halinde elle
yaptigi denetim (2026-08-29, dosya 1: w00000-w01004, dosya 2: w01005-w02010).

Rapordaki bazi ID'ler kaymisti (ayni parca icinde elle not alinirken
karismis olmali): rapor "w01899 sluga" diyordu, gercek kayit w01909'da;
"w01904 palata" gercekte w01914'te; "w01924 zabit'" gercekte w01934'te;
"w01909 soyuz" gercekte w01919'da; "w01930 goluboy" gercekte w01940'ta;
"w01179 Meydana gelen supheniz" gercekte w01185'te (somneniye). Her biri
dogru kelimeyi icerdigi dogrulanan gercek ID'ye tasindi; veri setinde o
haliyle bulunmayan/eslesmeyen birkac madde (orn. "w01202" ornek cumlesi
zaten baska bir formdan geliyordu) atlandi ya da yalniz baslik cevirisi
duzeltildi.

Tema etiketleri (theme) icin raporun kendisi "hangi tema dogru" demiyor,
yalnizca "bu etiket yanlis" diyordu -- 150+ kayit icin rastgele atanmis
görünüyor. Doğru temayı tahmin etmek yerine, denetimde yanlis olarak
isaretlenen ve halihazirda bos olmayan etiketler temizlendi (REPORT6_
CLEAR_THEME); zaten bos olanlar (drift/atif hatasi) dokunulmadan
birakildi.
"""

# id -> (ru, yeni tr)
REPORT6_TR = {
    # Dosya 1 - agir ceviri hatalari (baslik kelime cevirisi yanlis)
    'w00405': ('агент', 'ajan'),
    'w00601': ('фотография', 'fotoğraf'),
    'w00900': ('заслуживать', 'hak etmek'),
    'w00727': ('костюм', 'takım elbise'),
    'w00100': ('уж', '(isim) su yılanı, zehirsiz yılan türü'),
    'w00539': ('мужик', 'adam, herif'),
    'w00495': ('образ', 'imge, suret, biçim/tarz'),
    'w00761': ('внутри', 'içeride'),
    'w01136': ('заслужить', 'hak etmek'),

    # Dosya 2 - agir ceviri hatalari
    'w01202': ('жалкий', 'zavallı, acınası'),
    'w01309': ('вход', 'giriş'),
    'w01319': ('лечение', 'tedavi'),
    'w01340': ('итог', 'sonuç, toplam'),
    'w01542': ('торт', 'pasta'),
    'w01294': ('похороны', 'cenaze töreni, defin'),
    'w01428': ('ставка', 'bahis; oran; kadro'),
    'w01723': ('шпион', 'casus'),
    'w01349': ('труд', 'emek, çalışma'),
    'w01345': ('демон', 'iblis, şeytan'),
    'w01640': ('коробок', 'kibrit kutusu'),
    'w01919': ('союз', 'birlik, bağlaç'),  # rapor "w01909" diyordu, gercegi w01919
    'w01988': ('экран', 'ekran'),
    'w01673': ('восхитительный', 'muhteşem, nefis'),
}

# id -> (yeni exRu, yeni exTr)  -- ru dogrulamasi elle yapildi, apply_fixes
# bu ciftleri doğrudan yazar.
REPORT6_EXAMPLE = {
    # --- Dosya 1 ---
    'w00248': ('Это не похоже на убийство на почве ревности.',
               'Bu, kıskançlıktan işlenmiş bir cinayete benzemiyor.'),
    'w00366': ('Я не могу понимать и сопереживать чужих чувств.',
               'Başkalarının duygularını anlayamıyorum ve onlarla empati kuramıyorum.'),
    'w00555': ('Он не настолько глуп, чтобы спорить с ней.',
               'Onunla tartışmayacak kadar aptal değil.'),
    'w01210': ('Он не настолько глуп, чтобы спорить с ней.',
               'Onunla tartışmayacak kadar aptal değil.'),
    'w00092': ('Всё, что я говорю, - ложь. И это - правда.',
               'Söylediğim her şey yalan. İşte gerçek bu.'),
    'w00854': ('Всё, что я говорю, - ложь. И это - правда.',
               'Söylediğim her şey yalan. İşte gerçek bu.'),
    'w00405': ('Ваша команда секретных агентов выследила его подземную лабораторию.',
               'Gizli ajanlardan oluşan takımın onun yer altı laboratuvarını buldu.'),
    'w00924': ('Преступника всегда тянет обратно на место преступления.',
               'Suçlu, her zaman suç mahalline geri dönmek ister.'),
    'w00727': ('Этот костюм тебя красит.', 'Bu takım sana çok yakışıyor.'),
    'w00351': ('Бах был как великий импровизатор с гроссмейстерским умом.',
               'Bach, bir satranç ustasının zekâsıyla doğaçlama yapan büyük bir emprovizatördü.'),
    'w00972': ('Перефразируя Будду: «Ничему нельзя научиться с открытым ртом».',
               "Budha'nın sözünü aktaracak olursam: 'Açık bir ağızla hiçbir şey öğrenilmez.'"),
    'w00877': ('Я помню, как лейтенант, шедший позади меня, разделся до пояса.',
               'Arkamdan gelen teğmenin belden yukarısını çıkardığını hatırlıyorum.'),
    'w00531': ('Заходите к нам. Чем богаты, тем и рады.',
               'Bize gelin. Allah ne verdiyse yeriz.'),
    'w00932': ('Заходите к нам. Чем богаты, тем и рады.',
               'Bize gelin. Allah ne verdiyse yeriz.'),
    'w00484': ('Она сказала ему держаться подальше от дурных приятелей.',
               'Ona, kötü arkadaşlarından uzak durmasını söyledi.'),
    'w00917': ('Да сохранит его Господь.', 'Tanrı onu korusun.'),
    'w00487': ('Откуда ты знаешь, что у Тома есть собака?',
               "Tom'un bir köpeği olduğunu nereden biliyorsun?"),
    'w00892': ('Фома достаточно взрослый, чтобы отделить правильное от неправильного.',
               'Tom doğruyu yanlıştan ayırt edecek kadar olgundur.'),
    'w01045': ('Фома достаточно взрослый, чтобы отделить правильное от неправильного.',
               'Tom doğruyu yanlıştan ayırt edecek kadar olgundur.'),
    'w00594': ('У него длинные волосы, и он носит джинсы.', 'Uzun saçı var ve kot giyer.'),
    'w00600': ('У него длинные волосы, и он носит джинсы.', 'Uzun saçı var ve kot giyer.'),
    'w01087': ('У него длинные волосы, и он носит джинсы.', 'Uzun saçı var ve kot giyer.'),
    'w00684': ('Ты можешь казаться серьёзным, но ты не можешь казаться смешным.',
               'Ciddi görünebilirsin ama komik görünemezsin.'),
    'w00400': ('У Тома есть целая куча неоплаченных штрафов за парковку.',
               "Tom'un bir sürü ödenmemiş park cezası var."),
    'w00804': ('У Тома есть целая куча неоплаченных штрафов за парковку.',
               "Tom'un bir sürü ödenmemiş park cezası var."),
    'w00839': ('Александр находится на пике формы в этом сезоне.',
               'Aleksandr bu sezon formunun zirvesinde.'),
    'w00636': ('Я состою в клубе анонимных картавых алкоголиков.',
               'Kimliğini gizleyen peltek alkoliklerin kulübünün üyesiyim.'),
    'w00447': ('Сегодня я наконец с ними познакомился.', 'Sonunda bugün onlarla tanıştım.'),
    'w00740': ('Я был похищен пришельцами с других планет.',
               'Diğer gezegenlerden gelen uzaylılar tarafından kaçırıldım.'),
    'w00743': ('Шефы берут фуа-гра и готовят его по-своему.',
               'Şefler foie gras alır ve kendi usullerince pişirirler.'),
    'w00437': ('Вы должны пристегнуться ремнями безопасности во время взлёта.',
               'Kalkış sırasında emniyet kemerinizi bağlamış olmalısınız.'),
    'w00433': ('По настоянию врача Том лёг в больницу.', 'Doktorun ısrarı üzerine Tom hastaneye yattı.'),
    'w00122': ('Я просил его зайти, но он не пришёл.', 'Ona uğramasını rica ettim ama gelmedi.'),
    'w00349': ('Не знала, что ты меня так ненавидишь.', 'Beni bu kadar çok nefret ettiğini bilmiyordum.'),

    # Turkce yazim/dilbilgisi (dosya 1, E)
    'w00095': ('После посещения туалета Том обыкновенно руки не моет.',
               "Tom'un tuvalete girdikten sonra ellerini yıkama alışkanlığı yoktur."),
    'w00851': ('После посещения туалета Том обыкновенно руки не моет.',
               "Tom'un tuvalete girdikten sonra ellerini yıkama alışkanlığı yoktur."),
    'w00279': ('Я говорил с ним вчера вечером по телефону.', 'Dün akşam onunla telefonda konuştum.'),
    'w00282': ('Да! Именно так и есть! Вы тоже согласны?', 'Evet! Aynen öyle! Siz de katılıyor musunuz?'),
    'w00324': ('Фома попросил Машу подвезти его до парка развлечений.',
               "Tom, Mary'den onu lunaparka götürmesini rica etti."),
    'w00574': ('Я позвоню им и попрошу прощения.', 'Onları arayacağım ve af dileyeceğim.'),
    'w00610': ('Прости, но я не буду подходить к телефону.', 'Üzgünüm, telefona cevap vermeyeceğim.'),
    'w00265': ('Том был первым, кто исследовал тело Мэри.', "Tom, Mary'nin bedenini ilk inceleyen oldu."),
    'w00549': ('Том взглянул на Мэри и пожал плечами.', "Tom Mary'ye göz attı ve omuz silkti."),
    'w00645': ('Мне интересно, почему Том и Мэри плачут.', "Tom ve Mary'nin neden ağladıklarını merak ediyorum."),
    'w00905': ('(Смех) Умная кофемашина была особенным адом.',
               '(Kahkahalar) Akıllı kahve makinesi bana cehennem azabı çektirdi.'),
    'w00944': ('Людям платили, чтобы они забирали картон из ресторанов.',
               'İnsanlara, restoranlardan karton toplamaları için para ödeniyordu.'),
    'w00309': ('Он поймал мальчика, пытавшегося украсть его часы.', 'Saatini çalan çocuğu yakaladı.'),
    'w00621': ('Шекспир — величайший поэт, которого когда-либо рождала Англия.',
               "Shakespeare, İngiltere'nin şimdiye kadar ürettiği en büyük şairdir."),
    'w00362': ('Моя мечта — стать очень сильным игроком в маджонг.',
               'Hayalim mahjongda güçlü bir oyuncu olmak.'),
    'w00739': ('Моя мечта — стать очень сильным игроком в маджонг.',
               'Hayalim mahjongda güçlü bir oyuncu olmak.'),
    'w00983': ('Госпожа Сато отвечает за мой класс.', 'Bayan Sato sınıfımın sorumlusudur.'),

    # Tekrar eden hatalar (dosya 1, G)
    'w00045': ('У всех форм жизни есть инстинктивное стремление выжить.',
               'Bütün yaşam biçimlerinin hayatta kalmak için içgüdüsel bir dürtüsü vardır.'),
    'w00061': ('У всех форм жизни есть инстинктивное стремление выжить.',
               'Bütün yaşam biçimlerinin hayatta kalmak için içgüdüsel bir dürtüsü vardır.'),
    'w00075': ('У всех форм жизни есть инстинктивное стремление выжить.',
               'Bütün yaşam biçimlerinin hayatta kalmak için içgüdüsel bir dürtüsü vardır.'),
    'w00090': ('У всех форм жизни есть инстинктивное стремление выжить.',
               'Bütün yaşam biçimlerinin hayatta kalmak için içgüdüsel bir dürtüsü vardır.'),
    'w00673': ('У всех форм жизни есть инстинктивное стремление выжить.',
               'Bütün yaşam biçimlerinin hayatta kalmak için içgüdüsel bir dürtüsü vardır.'),
    'w00017': ('Я стал совершенно другим человеком после той ночи.',
               'O geceden sonra tamamen başka bir insana dönüştüm.'),
    'w00031': ('Я стал совершенно другим человеком после той ночи.',
               'O geceden sonra tamamen başka bir insana dönüştüm.'),
    'w00443': ('Я стал совершенно другим человеком после той ночи.',
               'O geceden sonra tamamen başka bir insana dönüştüm.'),
    'w00799': ('Я стал совершенно другим человеком после той ночи.',
               'O geceden sonra tamamen başka bir insana dönüştüm.'),
    'w01137': ('Я стал совершенно другим человеком после той ночи.',
               'O geceden sonra tamamen başka bir insana dönüştüm.'),

    # --- Dosya 2 ---
    'w01519': ('Я собираюсь обратиться с жалобой к менеджеру.',
               'Yöneticiye şikâyette bulunacağım.'),
    'w01298': ('Никто и ничто не может вывести его из себя.',
               'Hiç kimse ve hiçbir şey onu kendinden çıkaramaz.'),
    'w01640': ('У тебя есть коробок спичек?', 'Sende bir kibrit kutusu var mı?'),
    'w01710': ('боевики, террористы, преступники. Оружие может нанести много вреда.',
               'militanlar, teröristler ve suçlular tarafından. Silahlar çok zarar verebilir.'),
    'w01668': ('Кроме того, я поняла, как огромна пропасть между Севером и Югом.',
               'Ayrıca, Kuzey ile Güney arasındaki uçurumun ne kadar büyük olduğunu fark ettim.'),
    'w01877': ('Родители многим пожертвовали, чтобы обеспечить мне высшее образование.',
               'Ailem, bana yüksek öğrenim sağlamak için pek çok fedakarlıkta bulundu.'),
    'w01892': ('К сожалению, малая часть пассажиров пережила катастрофу.',
               'Ne yazık ki, yolcuların yalnızca küçük bir kısmı felaketten sağ kurtuldu.'),
    'w01894': ('Почему Фома хотел физической расправы над Машей?',
               'Tom neden Mary\'ye fiziksel şiddet uygulanmasını istedi?'),
    'w01893': ('Мэри поставила поднос с бокалами на круглый столик.',
               'Mary, kadehlerle dolu tepsiyi yuvarlak masanın üzerine koydu.'),
    'w01914': ('Меня позвали в его палату, чтобы осмотреть его.',
               'Onu muayene etmek için odasına çağrıldım.'),
    'w01909': ('Он соединяет меня напрямую. Это как будто личный слуга.',
               'Beni direkt bağlıyor. Kişisel bir hizmetçi gibi.'),
    'w01851': ('и именно тогда я поняла, что стану пилотом.',
               've işte o zaman pilot olacağımı anladım.'),
    'w01854': ('Служащие магазина даже не догадывались, что мы явимся.',
               'Mağaza çalışanları geleceğimizi tahmin bile etmiyordu.'),
    'w01824': ('Том открыл багажник, чтобы взять запасное колесо.',
               'Tom yedek lastiği almak için bagajı açtı.'),
    'w01867': ('Том обвинил Мэри в краже денег.', "Tom, Mary'yi para çalmakla suçladı."),
    'w01868': ('Никого внутрь не пускают.', 'İçeri kimseyi almıyorlar.'),
    'w01752': ('Я не думал, что мы сможем туда проникнуть.',
               'Oraya girebileceğimizi düşünmedim.'),
    'w01754': ('Мы объявляем церемонию открытой.', 'Töreni açık ilan ediyoruz.'),
    'w01759': ('Автобус приедет на остановку через пятнадцать минут.',
               'Otobüs on beş dakika içinde durağa gelecek.'),
    'w01514': ('Цветочный магазин находится возле кладбища.',
               'Çiçekçi dükkanı mezarlığın yanında.'),
    'w01491': ('Как же я испугался, когда открыл дверь!', 'Kapıyı açtığımda nasıl da korktum!'),
    'w01626': ('Знаменитая русская балерина Анна Павлова была чувашкой.',
               'Ünlü Rus balerini Anna Pavlova bir Çuvaştı.'),
    'w01627': ('Это прямой эфир телепередачи под названием «Мы нормальные».',
               'Bu, "Biz Normaliz" adlı programın canlı yayını.'),
    'w01639': ('Старый турецкий купец попрощался с нами нежным печальным взглядом.',
               'Yaşlı bir Türk tüccar bizimle hüzünlü bir şekilde vedalaştı.'),
    'w01643': ('Вам не нужно искать смысла и ходить по тонкому льду.',
               'Boşuna anlam aramanıza ve ince buzda yürümenize gerek yok.'),
    'w01772': ('Много мифов и легенд существует об этом месте.',
               'Burası hakkında pek çok efsane var.'),
    'w01945': ('Он любит ездить на прогулку верхом на лошади.',
               'At sırtında gezintiye çıkmaktan hoşlanıyor.'),
    'w01965': ('Вот наш вариант объявлений о продаже б/у автомобилей.',
               'Bu, ikinci el araba satış ilanlarımızın bir örneği.'),
    'w01971': ('Эта церковь в одночасье стала местом сбора людей.',
               'Bu kilise, bir anda insanların toplanma yeri haline geldi.'),
    'w01977': ('Не вижу причин для беспокойства.', 'Endişelenecek bir sebep görmüyorum.'),
    'w01998': ('Нетерпимость, дискриминация и месть стали главными последствиями революции.',
               'Hoşgörüsüzlük, ayrımcılık ve intikam, devrimin başlıca sonuçları haline geldi.'),

    # Bozuk Turkce / dilbilgisi (dosya 2, C)
    'w01195': ('Эта теория слишком сложна для моего понимания.',
               'Bu teoriyi kavramak benim için çok zor.'),
    'w01218': ('Я был очень впечатлён его хорошим поведением.',
               'Onun iyi davranışından çok etkilendim.'),
    'w01234': ('Синие штаны стоят дороже зелёных.', 'Mavi pantolon yeşilden daha pahalı.'),
    'w01451': ('Цена синих брюк выше, чем у зелёных.', 'Mavi pantolon yeşilden daha pahalı.'),
    'w01185': ('У вас не возникает сомнений?', 'Hiç şüpheniz yok mu?'),
    'w01327': ('Это уже надо смотреть по обстоятельствам.', 'Artık duruma göre karar vermeli.'),
    'w01318': ('Машины предложения понятны и их легко переводить.',
               "Mary'nin cümleleri anlaşılır ve çevirmesi kolaydır."),
    'w01398': ('Ловить рыбу в озере запрещено.', 'Gölde balık tutmak yasaktır.'),
    'w01537': ('Я не намереваюсь останавливаться здесь в Бостоне.',
               "Boston'da kalmaya niyetim yok."),
    'w01556': ('Хелен упрямо настаивает на том, что это правда.',
               'Helen bunun doğru olduğu konusunda inatla ısrar ediyor.'),
    'w01695': ('С такой температурой тебе нельзя выходить из дома.',
               'Bu kadar ateşin varken evden dışarı çıkamazsın.'),
    'w01788': ('Если прекратить приём лекарства, протеин начинает функционировать нормально.',
               'İlacı almayı bırakırsak, protein normal şekilde işlev görmeye başlar.'),
    'w01217': ('Этот глагол спрягается весьма специфическим образом.',
               'Bu fiil çok özel bir şekilde çekimlenir.'),
    'w01550': ('Это — последние четыре года судебных разбирательств по смартфонам.',
               'Bu, akıllı telefonlar alanındaki davanın son dört yılı.'),

    # Turkce yazim hatalari (dosya 2, D)
    'w01036': ('У тебя есть штопор, чтобы открыть бутылку?', 'Şişeyi açmak için tirbuşonun var mı?'),
    'w01054': ('В Августе я привезу сюда своих сыновей.', 'Ağustosta oğullarımı getireceğim.'),
    'w01419': ('Чудо - это то, что его участие в авантюре успешно.',
               'Mucize, onun maceradaki katılımının başarılı olmasıdır.'),
    'w01790': ('Чудо - это то, что его участие в авантюре успешно.',
               'Mucize, onun maceradaki katılımının başarılı olmasıdır.'),
    'w01432': ('Насилие над женщинами является нарушением прав человека.',
               'Kadına yönelik şiddet insan haklarının ihlalidir.'),
    'w01507': ('Он смог выжить после 150 лет охоты на китов.',
               'Balina avcılarından 150 yıl boyunca canını kurtarmış olabilir.'),
    'w01516': ('Этот признак является общим для птиц и динозавров.',
               'Bu, kuşlarla dinozorları birbirine bağlayan bir özellik.'),
    'w01531': ('Эй, пацан, ты что такой дерзкий?', 'Hey, çocuk, neden bu kadar şımarıksın böyle?'),
    'w01532': ('Судья попросил присяжных вынести приговор.',
               'Hâkim jüriden bir karara varmalarını istedi.'),
    'w01474': ('Ты перевёл пьесу с турецкого языка на арабский.',
               'Sen piyesi Türkçeden Arapçaya tercüme ettin.'),
    'w01563': ('Школа в двух километрах впереди.', 'Okul iki kilometre ileride.'),
    'w01767': ('Том что-то тащил.', 'Tom bir şeyler sürüklüyordu.'),
    'w01773': ('На Татоэбе нельзя создавать предложения про Чарльза.',
               "Tatoeba'da Charles hakkında cümle yazılamaz."),
    'w01830': ('Куда Том хочет, чтобы я положил его чемодан?',
               'Tom, valizini nereye koymamı istiyor?'),
    'w01925': ('Моя бабушка лечит отваром крапивы и головную боль, и боль в суставах.',
               'Babaannem ısırgan otu kaynatarak hazırladığı ilaçla hem baş hem eklem ağrısını tedavi ediyor.'),
    'w01958': ('И особенно важно их построить в судебных исках.',
               'Ve bunu özellikle davalara yönelik olarak yapmalıyız.'),

    # Rusca tarafindaki hatalar (dosya 2, E) - RU ve gerekirse TR
    'w01410': ('Я не намереваюсь причинить тебе вред.', 'Sana zarar vermeye niyetim yok.'),
    'w01475': ('Их основным источником вдохновения был серьёзный пересмотр Лорда Стерна.',
               "Temel esin kaynakları Lord Stern'in ciddi bir değerlendirmesiydi."),
    'w01630': ('Семье требовалась большая помощь на ферме.',
               'Ailenin çiftlikte çok yardıma ihtiyacı vardı.'),
    'w01934': ('Али забил гол «ударом рыбкой» при подаче с фланга.',
               'Ali, kanattan gelen ortayı uçarak kafa vuruşuyla gole çevirdi.'),
    'w01975': ('Шахматная доска состоит из восьми строк и восьми столбцов.',
               'Satranç tahtası sekiz satır ve sekiz sütundan oluşur.'),
    'w00802': ('Убедись, что ты делаешь то, что тебе сказали.',
               'Sana söylenildiği gibi yaptığından emin ol.'),
}

# Garbled / kullanilamaz ornek cumleler: sil (bos birak).
REPORT6_CLEAR_EXAMPLE = {
    'w00994',  # perezvonit' - podcast dokumunden kopmus, kullanilamaz
    'w01202',  # jalkiy - ornek 'jalko' formundan, sifatla ilgisiz
    'w01241',  # meç - transkript etiketi sizmis: "(Смех) ГБ:"
    'w01523',  # prikrytiye - transkript etiketi sizmis: "ААА:"
    'w01984',  # komissar - transkript etiketi sizmis: "БД:"
}

# id -> yeni pos
#
# Not: uygulamanin PartOfSpeech modeli yalnizca 4 deger taniyor: 'noun',
# 'verb', 'adj', ve digeri icin 'other' (bkz. lib/data/models/word.dart,
# PartOfSpeech.byKey). "adjective", "adverb", "preposition", "interjection"
# gibi acik yazilmis degerler sessizce 'other'a duser -- asagidaki degerler
# bu yuzden kisa forma cekildi (ilk yazildiginda hataliydi, sonra duzeltildi).
REPORT6_POS = {
    'w00000': 'other',  # privet (unlem)
    'w00143': 'other',  # tut (zarf)
    'w00217': 'other',  # pered (edat)
    'w00668': 'adj',    # belyy
    'w00849': 'adj',    # krasnyy
    'w00073': 'other',  # kak (zarf)
    'w01940': 'adj',    # goluboy (rapor "w01930" diyordu)
    'w01995': 'adj',    # prostoy
}

# id -> yeni translit. Sistemik hata: kelime basi "и" oncesinde olmayan bir
# "y" kayması eklenmis (rapor kategorisi C). Tum veri setinde tarandi,
# toplam 65 kayit etkilenmis (yalnizca dosya 1'deki 26 degil).
REPORT6_TRANSLIT = {
    'w00018': 'İ-mya', 'w00046': 'i-MET\'', 'w00086': 'İ-li', 'w00266': 'i-DE-ya',
    'w00398': 'İ-min-na', 'w00467': 'i-TAK', 'w00541': 'i-nag-DA', 'w00605': 'i-di-OT',
    'w00665': 'i-NA-çi', 'w01340': 'i-TOK', 'w01461': 'i-zu-ÇAT\'', 'w01600': 'i-NOY',
    'w02197': 'i-zab-ra-JE-ni-ye', 'w02413': 'İ-ba', 'w02615': 'i-zab-ra-JAT\'',
    'w02637': 'i-MU-şçist-va', 'w02747': 'i-nast-RAN-nıy', 'w02755': 'i-MET\'-sya',
    'w02888': 'i-RAK', 'w03128': 'i-RO-ni-ya', 'w03164': 'i-zu-ÇE-ni-ye',
    'w03286': 'i-nap-la-ni-TYA-nin', 'w03361': 'İ-va', 'w03387': 'i-di-AL',
    'w03539': 'i-zab-ri-TE-ni-ye', 'w03685': 'i-ni-tsi-a-Tİ-va', 'w03801': 'i-GOL-ka',
    'w04067': 'i-ZYAŞÇ-nıy', 'w04142': 'İ-midş', 'w04155': 'i-za-LYA-tsi-ya',
    'w04228': 'i-ZIS-kan-nıy', 'w05602': 'i-zab-ri-TA-til\'-nıy', 'w05662': 'i-za-Lİ-ra-van-nıy',
    'w05751': 'i-ZYUM', 'w05929': 'i-ZYAN', 'w05993': 'i-ME-ni-ye', 'w06014': 'i-zab-ri-TA-til\'',
    'w06139': 'i-za-Bİ-li-ye', 'w06151': 'i-ra-NİÇ-nıy', 'w06243': 'i-ta-GO', 'w06266': 'i-ON',
    'w06282': 'i-ye-ROG-lif', 'w06418': 'i-ye-RAR-hi-ya', 'w06423': 'i-RİS-ka',
    'w06540': 'i-zab-ri-TAT\'', 'w06546': 'i-KO-na', 'w06893': 'i-di-a-LO-gi-ya',
    'w07278': 'i-ZYA-ti-ye', 'w07304': 'i-zu-RO-da-vat\'', 'w07329': 'i-zum-RUT',
    'w07366': 'i-di-a-LİST', 'w07436': 'i-za-TOP', 'w07447': 'İ-diş', 'w07575': 'i-MAM',
    'w07620': 'i-ZOG-nu-tıy', 'w07808': 'İ-ga', 'w07817': 'i-KO-ta', 'w07992': 'i-zum-LE-ni-ye',
    'w08322': 'i-zıs-KA-ni-ye', 'w08524': 'i-di-a-la-Gİ-çis-kiy', 'w08586': 'i-din-TİÇ-nast\'',
    'w08602': 'i-NER-tsi-ya', 'w08828': 'i-di-a-LİZM', 'w08836': 'i-zyas-NYAT\'-sya',
    'w08929': 'i-zu-VE-çit\'',
    # Format tamamen eksikti (tek parca, buyuk/kucuk harf/tire yok)
    'w00068': 'V',            # v (tek basina harf, [f] degil [v])
    'w00353': 'za-ÇEM',       # zaçem
    'w00646': 'ra-Dİ-ti-li',  # roditeli (raporun kendi onerisi)
    'w01037': 'u-sta-na-VİT\'',  # ustanovit'
}

# id -> yeni accented (vurgu isareti eksikti)
REPORT6_ACCENTED = {
    'w00353': 'заче́м',
    'w00646': 'роди́тели',
    'w01037': 'установи́ть',
}

# Tema (theme) etiketi yanlis olarak isaretlenen ve halen bos olmayan
# kayitlar: dogru temayi tahmin etmek yerine temizlendi.
REPORT6_CLEAR_THEME = {
    'w00013', 'w00076', 'w00299', 'w00326', 'w00341', 'w00362', 'w00423', 'w00581',
    'w00604', 'w00649', 'w00953', 'w00055', 'w00225', 'w00228', 'w00327', 'w00329',
    'w00330', 'w00567', 'w00765', 'w00916', 'w00951', 'w00108', 'w00111', 'w00271',
    'w00390', 'w00451', 'w00454', 'w00489', 'w00493', 'w00941', 'w00944', 'w00980',
    'w00994', 'w00116', 'w00217', 'w00475', 'w00165', 'w00209', 'w00427', 'w00774',
    'w00155', 'w00161', 'w00198', 'w00301', 'w00754', 'w00793', 'w00798', 'w00926',
    'w00103', 'w00118', 'w00237', 'w00561', 'w00278', 'w00383', 'w00524', 'w00721',
    'w00782', 'w00409', 'w00342', 'w00685', 'w00759', 'w00842', 'w00978', 'w00446',
    'w00728', 'w00973', 'w00501', 'w00513', 'w00586', 'w00577', 'w00636', 'w00963',
    'w00787', 'w00838', 'w00887', 'w00890', 'w00895', 'w00600', 'w00930', 'w00959',
    'w00495',
    'w01286', 'w01354', 'w01430', 'w01496', 'w01527', 'w01650', 'w01937', 'w01222',
    'w01302', 'w01665', 'w01684', 'w01794', 'w01880', 'w01938', 'w01051', 'w01094',
    'w01196', 'w01888', 'w01204', 'w01563', 'w01618', 'w01731', 'w01380', 'w01444',
    'w01551', 'w01953', 'w01299', 'w01366', 'w01456', 'w01571', 'w01635', 'w01301',
    'w01397', 'w01421', 'w01402', 'w01562', 'w01806', 'w01832', 'w01968', 'w01021',
    'w01253', 'w01488', 'w01698', 'w01190', 'w01755', 'w01462', 'w01777', 'w01027',
    'w01161', 'w01803', 'w01884', 'w01994', 'w01075', 'w01119', 'w01629', 'w01044',
    'w01097', 'w01277', 'w01417', 'w01440', 'w01144', 'w01193', 'w01273', 'w01472',
    'w01500', 'w01526', 'w01536', 'w01540', 'w01552', 'w01692', 'w01951',
}
