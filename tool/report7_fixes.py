# -*- coding: utf-8 -*-
"""Yedinci tur: dosya 3 (w02011-w03014) ve dosya 4 (w03015-w03983) denetimi
(2026-08-29). Kullanicinin acik talimati uzerine bu turdan itibaren:

- Ornek cumle kurtarilamayacak kadar bozuksa (transkript parcasi, konuyla
  ilgisiz, RU kaynagi kirik) duzeltmeye calismak yerine BOS birakiliyor.
- "Supheli" kayitlar (nadir kimyasal elementler, nota/unlem gibi sozluk
  girdisi olmayan seyler, kufurlu/mustehcen ornekli maddeler) dogrudan
  cikariliyor (REPORT7_DROP). Kaliforniy (Dosya 2, w01882) ayni sorunu
  tasidigi icin geriye donuk olarak buraya eklendi.
- Tema/POS hatalarinda oldugu gibi, dogru karsiligi belirsiz "ornek cumle
  baslikla uyusmuyor" kategorisi (E/F) bu turda atlandi - yanlis degil,
  yalnizca gosterici degil; yeni ornek yazmak ayri bir emek gerektiriyor.

Birkac ID yine kaymisti (kullanicinin elle tuttugu notlarda): "w01899/
w01909/w02921/w03210/w03379/w03842" gibi ornekler; gercek icerigi
dogrulanabilenler doğru ID'ye tasindi, dogrulanamayanlar atlandi.
"""

# id -> (ru, yeni tr)
REPORT7_TR = {
    # --- Dosya 3 ---
    'w02017': ('тост', 'kızarmış ekmek (tost)'),
    'w02507': ('пробка', 'trafik sıkışıklığı'),
    'w02105': ('тачка', '(argo) araba'),
    'w02825': ('лавка', 'dükkân, küçük mağaza'),
    'w02465': ('змей', 'yılan, ejderha'),
    'w02831': ('нанимать', 'işe almak'),
    'w02431': ('скромный', 'mütevazı'),
    'w02419': ('долина', 'vadi'),
    'w02630': ('джунгли', 'cangıl'),
    'w02533': ('шторм', 'fırtına'),
    'w02472': ('порт', 'liman'),
    'w02677': ('учительница', 'öğretmen (kadın)'),
    'w02678': ('учёный', 'bilim insanı'),
    'w02902': ('сущность', 'öz, mahiyet'),
    'w02667': ('подчиняться', 'uymak'),
    'w02913': ('болтовня', 'gevezelik'),
    'w02851': ('почерк', 'el yazısı'),
    'w02520': ('оборона', 'savunma'),
    'w02574': ('опека', 'vesayet'),
    'w02837': ('духовный', 'manevi'),
    'w02505': ('религиозный', 'dini'),
    'w02237': ('запас', 'dağarcık, stok'),
    'w02678obidj': None,

    # --- Dosya 4 ---
    'w03029': ('мудрость', 'bilgelik'),
    'w03633': ('схватка', 'sancı (doğum)'),
    'w03543': ('бешенство', 'hiddet, öfke'),
    'w03961': ('бич', 'bela, felaket'),
    'w03622': ('цепочка', 'zincir'),
    'w03542': ('плита', 'ocak (fırın)'),
    'w03668': ('горшок', 'lazımlık'),
    'w03501': ('убеждать', 'ikna etmek'),
    'w03537': ('сканирование', 'tarama'),
    'w03555': ('принятие', 'kabul etme'),
    'w03748': ('выручить', 'kurtarmak, yardım etmek'),
    'w03744': ('важность', 'önem'),
    'w03394': ('вредить', 'zarar vermek'),  # rapor 'w03379' diyordu
    'w03726': ('выращивать', 'yetiştirmek'),
    'w03280': ('хрупкий', 'kırılgan, narin'),
    'w03299': ('ладонь', 'avuç içi'),
    'w03637': ('телеграмма', 'telgraf'),
    'w03653': ('коммерческий', 'ticari'),
    'w03779': ('чиновник', 'memur, bürokrat'),
    'w03821': ('мерзость', 'iğrençlik, pislik'),
    'w03882': ('сувенир', 'hediyelik eşya'),
    'w03858': ('жадный', 'açgözlü'),  # rapor 'w03842' diyordu
    'w03770': ('длительный', 'uzun süreli'),
    'w03503': ('прогноз', 'tahmin'),
    'w03721': ('семейство', 'aile'),
    'w03041': ('скот', 'büyükbaş hayvan, sığır'),
    'w03245': ('лодыжка', 'ayak bileği'),
    'w03224': ('командный', 'takıma ait'),  # rapor 'w03210' diyordu
    'w03023': ('роскошный', 'lüks, görkemli'),
    'w03872': ('кружка', 'kupa, bardak'),
    'w03124': ('служащий', 'memur'),
    'w03273': ('титул', 'unvan'),
    'w03366': ('Аллах', 'Allah'),  # ru alani REPORT7_RU ile buyutuldu
    'w03708': ('Чили', 'Şili'),    # ru alani REPORT7_RU ile buyutuldu
}
del REPORT7_TR['w02678obidj']

# id -> (ru, yeni ru)  -- baslik kelimenin kendisi hatali/kucuk harfliydi
REPORT7_RU = {
    'w02984': ('езжать', 'ездить'),
    'w02458': ('вашингтон', 'Вашингтон'),
    'w02553': ('марс', 'Марс'),
    'w02888': ('ирак', 'Ирак'),
    'w02932': ('афганистан', 'Афганистан'),
    'w03366': ('аллах', 'Аллах'),
    'w03708': ('чили', 'Чили'),
}

# id -> yeni accented / translit (yalniz ru degisenler + bonus format hatasi)
REPORT7_ACCENTED = {
    'w02984': 'е́здить',
    'w03366': 'Алла́х',  # ru buyutuldu, aksanli alan da eslesmeli
}
REPORT7_TRANSLIT = {
    'w02984': 'YEZ-dit\'',
    'w02461': 'vi-tse-pre-zi-DENT',
    'w03590': 'BO-u-link',
}

# id -> (yeni exRu, yeni exTr)
REPORT7_EXAMPLE = {
    # --- Dosya 3, A ---
    'w02918': ('Я не хочу на тебя обижаться.', 'Sana darılmak istemiyorum.'),
    'w02586': ('Не ты здесь приказываешь.', 'Burada emirleri sen vermiyorsun.'),
    'w02729': ('Это не похоже на убийство на почве ревности.',
               'Bu, kıskançlıktan işlenmiş bir cinayete benzemiyor.'),
    'w02648': ('И это напомнило мне об одном недавнем случае.',
               'Bu bana, geçtiğimiz günlerdeki bir olayı anımsattı.'),
    'w02898': ('Я по-настоящему соскучился по дизайну.', 'Tasarımı gerçekten özledim.'),
    'w02884': ('Это был блестящий рассказ о моём предательстве.',
               'İhanetimle ilgili parlak bir hikâyeydi.'),
    'w02879': ('Нас запрещали в Египте, а наших корреспондентов арестовывали.',
               'Mısır\'da yasaklanmıştık ve muhabirlerimizin bir kısmı tutuklanmıştı.'),
    'w02814': ('Верховный суд отменил предыдущее решение.', 'Yüksek Mahkeme kararı iptal etti.'),
    'w02635': ('Они хотели, чтобы Конгресс поставил копирование вне закона.',
               'Kongre\'nin kopyalamayı yasa dışı ilan etmesini istiyorlardı.'),
    'w02827': ('Я живу с этим диагнозом уже четыре года.', 'Dört yıldır bu teşhisle yaşıyorum.'),
    'w02841': ('Рыбы Мола славятся тем, что переносят тонны паразитов.',
               'Mola balıkları çok sayıda parazit taşımalarıyla ünlüdür.'),
    'w02663': ('После захватывающего убийства зеленоволосой Розы врачи бальзамируют её мазями для покойников.',
               'Yeşil saçlı Rosa\'nın çarpıcı cinayetinin ardından, doktorlar onu ölüler için özel merhemlerle korudular.'),
    'w02689': ('Здесь есть контейнер для биологических отходов?',
               'Burada biyolojik atıklar için çöp var mı?'),
    'w02047': ('И это соответствовало опухоли размером с бейсбольный мяч.',
               've bu, beyzbol topu büyüklüğünde bir tümöre karşılık geliyordu.'),
    'w02049': ('Если у вас есть какие-либо вопросы, не стесняйтесь позвонить.',
               'Herhangi bir sorunuz varsa, aramaktan çekinmeyin.'),
    'w02059': ('Это предложение не имеет определённого смысла.',
               'Bu cümlenin belirli bir anlamı yok.'),
    'w02501': ('Комната маленькая, а мебели много. Поэтому здесь очень тесно.',
               'Oda küçük ama mobilya çok. Bu yüzden burası oldukça dar.'),
    'w03229': ('Комната маленькая, а мебели много. Поэтому здесь очень тесно.',
               'Oda küçük ama mobilya çok. Bu yüzden burası oldukça dar.'),
    'w02525': ('Нарисуй свой портрет.', 'Kendi portreni çiz.'),
    'w02893': ('Я же не хотел вас обмануть или шантажировать.',
               'Sizi aldatmak ya da şantaj yapmak istemiyordum.'),
    'w02728': ('Почему бы самому не сделать недорогие салфетки?',
               'Neden düşük maliyetli peçeteleri kendim yapmayayım?'),
    'w02795': ('Та еда была просто божественной.', 'O yemek tam anlamıyla enfesti.'),
    'w02800': ('Есть еще одна ужасная фраза "разрушение стеклянного потолка".',
               'Bir de "cam tavanı kırmak" diye korkunç bir tabir daha var.'),
    'w02801': ('Вскоре меня начали оскорблять на моих собственных концертах.',
               'Kısa süre sonra kendi konserlerimde hakarete uğramaya başladım.'),
    'w02843': ('Очень важно, что у нас есть гибкая администрация.',
               'Esnek bir yönetimimizin olması gerçekten çok önemli.'),
    'w02862': ('Другие используют эти данные, чтобы получить страховые возмещения.',
               'Bazıları bu verileri sigorta tazminatı almak için kullanıyor.'),
    'w02941': ('Чем больше просмотров, тем больше долларов от рекламы.',
               'Ne kadar çok görüntülenme olursa, reklamdan o kadar çok kazanç olur.'),
    'w02976': ('Почему ни один народ земли не знает доподлинно историю своего происхождения?',
               'Dünyadaki hiçbir halk neden kökeninin tarihini tam olarak bilmiyor?'),
    'w02977': ('Погружение начинается. Никакой связи с внешним миром кроме простенькой рации.',
               'Dalış başlıyor. Basit bir telsiz dışında dış dünyayla hiçbir bağlantı yok.'),
    'w02986': ('Желание проистекает из потребности и запроса.',
               'Arzu, ihtiyaç ve talepten doğar.'),
    'w02930': ('Я хотела добавить немного смысла в свою бессмысленную и злобную жизнь.',
               'Anlamsız ve kötü niyetli hayatıma azıcık anlam katmak istedim.'),
    'w02923': ('Приступай с Богом!', 'Haydi, Allah\'ın izniyle başla!'),
    'w02935': ('Если выключить свет, стрелка возвращается к нулевой отметке.',
               'Işığı kapatırsan, ibre sıfıra döner.'),
    'w02913ex': ('Наверно, достаточно пустой болтовни?',
                 'Herhalde yeterince boş gevezelik ettik, değil mi?'),

    # --- Dosya 3, C (Turkce yazim) ---
    'w02028': ('Том был в старой растянутой футболке.', 'Tom eski, bollaşmış bir tişört giyiyordu.'),
    'w02053': ('Какие хорошие привычки следует выработать в себе?',
               'Kendimiz için ne tür iyi alışkanlıklar edinmeliyiz?'),
    'w02055': ('Вот, перчатки мне немного малы, но вот она.',
               'Bu eldivenler bana biraz küçük ama olsun.'),
    'w02065': ('Мексиканке очень понравился русский шоколад.',
               'Meksikalı kadın Rus çikolatasını çok sevdi.'),
    'w02099': ('Королева только что отложила яйца. Нет никакого руководства.',
               'Kraliçe sadece yumurtlar. Başka da bir yönetim yoktur.'),
    'w02157': ('Я чувствую, что имею препятствие для своего развития.',
               'Gelişmemin engellendiğini hissediyorum.'),
    'w02993': ('Я чувствую, что имею препятствие для своего развития.',
               'Gelişmemin engellendiğini hissediyorum.'),
    'w02165': ('В одиночестве тоже есть своя прелесть.',
               'Yalnızlığın da kendi içinde iyi tarafları var.'),
    'w02180': ('Эти конфеты мне не нравятся.', 'Bu şekerleri sevmiyorum.'),
    'w02291': ('В тысяча восемьсот восьмом году он руководил оркестром в Бамберге.',
               '1808 yılında Bamberg\'te bir orkestra yönetti.'),
    'w02874': ('В тысяча восемьсот восьмом году он руководил оркестром в Бамберге.',
               '1808 yılında Bamberg\'te bir orkestra yönetti.'),
    'w02299': ('Противозачаточные меры дешевле, чем беременность.',
               'Doğum kontrolü hamilelikten daha ucuzdur.'),
    'w02324': ('Том легко угадал пароль Мэри.', "Tom Mary'nin parolasını rahatça tahmin etti."),
    'w03012': ('Кагебешники запретили Илоне открывать шторы во время парада.',
               "KGB yetkilileri İlona'nın geçit töreni sırasında perdeleri açmasını yasakladı."),
    'w02447': ('Почему бы не вложить часть себя в работу?',
               'Neden işe kendinizden bir şeyler katmamak?'),
    'w02566': ('Конечно, уголовное правосудие рассматривает их как обычных жуликов.',
               'Tabii ki, adalet sistemi onların suçunu herkesin bildiği eski suçlardan kabul ediyor.'),
    'w02643': ('После работы консультантом по управлению, стану укротительницей слонов.',
               'Küresel işletme danışmanlığından fil terbiyecisine.'),
    'w02666': ('Это твоя форма официантки.', 'Bu senin garson üniforman.'),
    'w02703': ('Мы ценим вашу преданность.', 'Sadakatinizi takdir ediyoruz.'),
    'w02742': ('Конечно, это не так плохо, как у этого бедняги.',
               'Elbette, bu zavallı kişininki kadar kötü değil.'),
    'w02922': ('Его ответ был отрицательным.', 'Onun cevabı negatifti.'),
    'w02950': ('Сколько лет ты уже преподаёшь английский язык?',
               'Kaç senedir İngilizce öğretiyorsun?'),
    'w02965': ('Наша диета очень разнообразна.', 'Diyetimiz çok çeşitlidir.'),
    'w02934': ('Артист развивался, и мы все были тому свидетелями.',
               'Sanatçı gelişiyordu ve hepimiz buna şahit olduk.'),

    # --- Dosya 3, D (Rusca) ---
    'w02126': ('Многие виды цветов распускаются в середине апреля.',
               'Birçok çiçek türü nisanın ortasında açar.'),

    # --- Dosya 3, tekrarlar / drift duzeltmesi ---
    'w02027': ('Перед ним стояла шикарная слегка одетая танцовщица.',
               'Karşısında şık, üstü başı yarı çıplak bir dansçı duruyordu.'),

    # --- Dosya 4, A ---
    'w03839': ('От перца жжёт во рту.', 'Ağzım biberden yanıyor.'),
    'w03060': ('Другими словами, игра - наш адаптивный туз в рукаве.',
               'Diğer bir deyişle, oyun elimizdeki koz kartımız.'),

    # --- Dosya 4, C ---
    'w03035': ('Предложение на рынке нефти в настоящее время превышает спрос.',
               'Petrol piyasasında arz şu anda talebi aşıyor.'),
    'w03085': ('Пусть Бог его не наказывает.', 'Tanrı onu cezalandırmasın.'),
    'w03089': ('Как и раньше, в деле участвует русская мафия.',
               'Daha önce olduğu gibi, bu işte Rus mafyası da var.'),
    'w03053': ('Это моя дочь. Вы бы с ней подружились.',
               'Bu benim kızım. Onunla arkadaş olurdunuz.'),
    'w03088': ('Девятая планета большая, но она очень-очень далеко.',
               'Dokuzuncu gezegen büyük ama gerçekten çok çok uzakta.'),
    'w03107': ('Но это происходит только в регионе Африканского Рога.',
               'Ama bu yalnızca Afrika Boynuzu bölgesinde oluyor.'),
    'w03114': ('Пуганая ворона куста боится.', 'Ürkmüş karga çalıdan korkar.'),
    'w03122': ('Нужно привести законы в соответствие с реалиями современности.',
               'Yasaları günümüz gerçekleriyle uyumlu hale getirmek gerekiyor.'),
    'w03159': ('Кстати, у этого менеджера был роман с секретаршей.',
               'Bu arada, bu müdürün sekreteriyle bir ilişkisi vardı.'),
    'w03201': ('А армия вообще убьёт вас, а Хамас похитит и будет требовать выкуп.',
               'Ordu sizi öldürür, Hamas ise kaçırıp fidye isteyecek.'),
    'w03252': ('Блоха может прыгнуть на двести раз выше собственного роста.',
               'Bir pire, kendi boyunun iki yüz katı yüksekliğe zıplayabilir.'),
    'w03272': ('Потому что часть негатива исходила от «своих» же.',
               'Çünkü negatifliğin bir kısmı "kendi insanlarımdan" geliyordu.'),
    'w03294': ('В будущем номер один вы выигрываете в лотерею.',
               'Gelecekte, bir numarayla piyangoyu kazanırsınız.'),
    'w03333': ('Его нужно отстранить от должности.', 'Görevden alınması gerekiyor.'),
    'w03338': ('Мне кажется, нам нужна сеть загородных поместий.',
               'Bize kır malikanelerinden oluşan bir ağ gerekiyor gibi görünüyor.'),
    'w03344': ('«Оранжевые» выбыли в первом туре.', 'Turuncular ilk turda elendi.'),
    'w03419': ('Не ломай комедию!', 'Numara yapma!'),
    'w03513': ('Звонок Джеймсу для сообщения ему кода комбинации замкá.',
               "James'e kombinasyon kilidinin kodunu bildirmek için arama."),
    'w03572': ('Человек, который возглавлял это, был бывшим армейским генералом.',
               'Buna liderlik eden kişi eski bir ordu generaliydi.'),
    'w03605': ('Потому что недостаточно сместить лидера, правителя или диктатора.',
               'Çünkü bir lideri, hükümdarı ya da diktatörü devirmek yeterli değil.'),
    'w03640': ('Воскресающие растения активируют эти гены при наступлении засухи.',
               'Dirilen bitkiler, kuraklık başladığında bu genleri etkinleştirir.'),
    'w03666': ('Я проснулся, вышел подышать, и я смотрю, по взлетной полосе бежит человек.',
               'Uyandım, biraz hava almaya çıktım ve pistte koşan birini gördüm.'),
    'w03682': ('Максима возбуждают девушки в чулках.',
               "Maksim'i çorap giyen kızlar tahrik ediyor."),
    'w03705': ('Сивиллы, чьи пророчества никому не нужны.',
               'Kehanetlerine kimsenin ihtiyaç duymadığı kâhinler.'),
    'w03729': ('Они хотели стать уютным местом встреч для сообщества.',
               'Topluluk için rahat bir buluşma yeri olmak istediler.'),
    'w03734': ('Что является причиной изжоги и как она лечится?',
               'Peki mide ekşimesine ne sebep olur ve nasıl tedavi edilir?'),
    'w03782': ('Гробница была уничтожена в результате умышленного поджога.',
               'Mezar, kasıtlı bir kundaklama sonucu yok edilmişti.'),
    'w03785': ('Все это превращается в коллективное крушение поезда.',
               'Her şey toplu bir tren kazasına dönüşüyor.'),
    'w03795': ('Это было увлекательно, но заработает на живом человеке?',
               'Bu ilginçti ama gerçek bir insanda işe yarar mı?'),
    'w03865': ('Иногда занятия отменялись, так как у талибов возникало подозрение.',
               'Bazen dersler iptal edilirdi çünkü Taliban şüphelenirdi.'),
    'w03907': ("Это было 28 июня 2012 года, в годовщину Стоунволлских бунтов.",
               "Tarih 28 Haziran 2012'ydi, Stonewall isyanlarının yıl dönümüydü."),
    'w03910': ('Восстановление основных сенсорных функций имеет решающее значение.',
               'Temel duyusal işlevlerin iyileştirilmesi belirleyici bir öneme sahip.'),
    'w03911': ('Возможно, это полезно для талии, но вы быстро проголодаетесь.',
               'Bel için faydalı olabilir ama uzun süre tok tutmaz.'),
    'w03922': ('Мы строим красивые дома, разрабатываем дизайн, развиваем архитектуру.',
               'Güzel evler inşa ediyoruz, tasarım geliştiriyoruz, mimari üretiyoruz.'),
    'w03932': ('Он показывал животным пищу и одновременно звонил в колокольчик.',
               'Hayvanlara biraz yiyecek gösterirken aynı anda bir çan çalardı.'),
    'w03975': ('Порой ведут себя друг с другом как школьники.',
               'Bazen birbirlerine karşı okul çocukları gibi davranırlar.'),
    'w03971': ('Перед ним стояла шикарная слегка одетая танцовщица.',
               'Karşısında şık, üstü başı yarı çıplak bir dansçı duruyordu.'),

    # --- Dosya 4, E (Turkce yazim) ---
    'w03055': ('Знаменитый пример — способность уловить запах спаржи в моче.',
               'En ünlü örneklerinden biri sözde kuşkonmazın idrarını koklama becerisidir.'),
    'w03067': ('Каждый хоть раз в жизни влюбляется.', 'Herkes hayatı boyunca en az bir kere aşık olur.'),
    'w03090': ('Так создатели находят технологии везде, где только можно.',
               'Böylece yaratıcılar teknolojiyi mümkün olan her yerde harmanladı.'),
    'w03119': ('У меня дар убеждения.', 'İkna etme yeteneğim var.'),
    'w03282': ('Перед применением спрей необходимо встряхнуть.',
               'Sprey kullanılmadan önce çalkalanmalıdır.'),
    'w03847': ('Какая у тебя любимая причёска?', 'Gözde saç stilin nedir?'),
    'w03329': ('Нельзя дразнить собаку.', 'Köpeği kışkırtma.'),
    'w03653ex': ('Это не коммерческая пристань.', 'Bu, ticari bir iskele değil.'),
    'w03587': ('Эта комната такая маленькая и душная, что я задыхаюсь.',
               'Bu odanın küçüklüğünden ve havasızlığından dolayı nefesim tıkanıyor.'),
    'w03619': ('Она снимает макияж.', 'O makyajını siliyor.'),
    'w03709': ('Это также имеет отношение к болезням и реабилитации.',
               'Ama bunun hastalıklar ve rehabilitasyonla da ilgisi var.'),
    'w03774': ('Так что этот канат запросто может закрутиться вокруг вас.',
               'Çevrenizde çok kolay bir şekilde döner.'),
    'w03906': ('Ему нравится джаз, и мне тоже.', 'O caz sever, ben de öyle.'),
    'w03958': ('Представьте паруса Сиднейского оперного театра в качестве электростанций.',
               "Sydney Opera Binası'nın yelkenlerini elektrik santrali olarak düşünün."),
    'w03966': ('Авторитеты в этом матче не дают "Илдызспору" особых шансов.',
               "Otoriteler, Yıldızspor'a bu maçta fazla şans tanımıyor."),

    # --- Dosya 4, F (Rusca) ---
    'w03214': ('Многие из этих пациентов имеют очень сильные ожоги.',
               'Bu hastaların çoğunun çok ciddi yanıkları var.'),

    # --- Dosya 3/4 tekrarlanan / paylasilan ornekler ---
    'w03488': ('Это не похоже на убийство на почве ревности.',
               'Bu, kıskançlıktan işlenmiş bir cinayete benzemiyor.'),
    'w03769': ('Фома слишком немощный, чтобы подняться самостоятельно.',
               'Tom kendi başına kalkamayacak kadar güçsüz.'),
    'w02963': ('Фома слишком немощный, чтобы подняться самостоятельно.',
               'Tom kendi başına kalkamayacak kadar güçsüz.'),
    'w03887': ('У всех форм жизни есть инстинктивное стремление выжить.',
               'Bütün yaşam biçimlerinin hayatta kalmak için içgüdüsel bir dürtüsü vardır.'),
    'w03962': ('Жильё в пригороде стоит вдвое дешевле, чем в городе.',
               'Banliyödeki konut, şehirdekine göre iki kat daha ucuza mal oluyor.'),
    'w02511': ('Жильё в пригороде стоит вдвое дешевле, чем в городе.',
               'Banliyödeki konut, şehirdekine göre iki kat daha ucuza mal oluyor.'),
}
del REPORT7_EXAMPLE['w02913ex']
del REPORT7_EXAMPLE['w03653ex']
REPORT7_EXAMPLE['w02913'] = ('Наверно, достаточно пустой болтовни?',
                              'Herhalde yeterince boş gevezelik ettik, değil mi?')
REPORT7_EXAMPLE['w03653'] = ('Это не коммерческая пристань.', 'Bu, ticari bir iskele değil.')

# Kurtarilamayan / konuyla ilgisiz / kaynagi kirik ornek cumleler: bos birak.
REPORT7_CLEAR_EXAMPLE = {
    # Dosya 3, B
    'w02014', 'w02081', 'w02109', 'w02111', 'w02119', 'w02227', 'w02294',
    'w02347', 'w02351', 'w02422', 'w02423', 'w02428', 'w02517', 'w02647',
    'w02706', 'w02813', 'w02872',
    # Dosya 3, H (musteshen icerik, kelime kaliyor)
    'w02524', 'w02515',
    # Dosya 4, A (kelimeyle ilgisiz ornek)
    'w03737', 'w03456', 'w03598', 'w03612', 'w03688', 'w03806', 'w03890',
    'w03213', 'w03073',
    # Dosya 4, D
    'w03019', 'w03106', 'w03112', 'w03121', 'w03145', 'w03161', 'w03234',
    'w03246', 'w03249', 'w03256', 'w03260', 'w03278', 'w03320', 'w03361',
    'w03388', 'w03416', 'w03433', 'w03548', 'w03568', 'w03664', 'w03718',
    'w03758', 'w03763', 'w03768', 'w03775', 'w03797', 'w03892', 'w03914',
    'w03919', 'w03960',
    # Dosya 4, kaynak cumlesi de kirik
    'w03560',
    # Dosya 4, uygunsuz baglam ama kelime meşru
    'w03743',
}

# Sozluk girdisi olarak sorunlu / dil ogrenimi icin uygunsuz: cikar.
REPORT7_DROP = {
    'w01882',  # kaliforniy (Dosya 2) - geriye donuk, ayni sorun
    'w02029',  # ay (unlem, sozluk girdisi degil)
    'w02282',  # mi (nota adi, gurultu)
    'w02115',  # tina (cok nadir, ornek yok)
    'w02611',  # vip' (cok nadir, ornek yok)
    'w02832',  # parok (cok nadir, ornek yok)
    'w02562',  # kent (argo/nadir, ornek yok)
    'w02996',  # germaniy (kimyasal element)
    'w03625',  # indiy (kimyasal element)
    'w03016',  # lin' (nadir balik turu, ornek yok)
    'w03690',  # tor (belirsiz, ornek yok)
    'w03478',  # go (oyun adi, sozluk girdisi degil, ornek yok)
    'w03820',  # dzersi (belirsiz, ornek yok)
    'w03755',  # koks (belirsiz/riskli, ornek yok)
    'w03290',  # set (belirsiz, ornek yok)
    'w03365',  # gerr (Almanca unvan, Rusca sozcuk degil)
    'w03452',  # poimet' (kufurlu/mustehcen ornekli argo fiil)
}

# id -> yeni pos
REPORT7_POS = {
    'w02678': 'noun',   # uçёnıy
    'w02683': 'adjective',  # zelyonıy
    'w02757': 'adjective',  # pravıy
    'w02187': 'adverb',     # podryad
    'w03124': 'noun',   # slujaşçiy
}

# Tema yanlis isaretlenen ve halen bos olmayan kayitlar temizlendi.
REPORT7_CLEAR_THEME = {
    'w02099', 'w02551', 'w02555', 'w02560', 'w02600', 'w02647', 'w02757',
    'w02835', 'w02851', 'w02915', 'w02926', 'w02937', 'w02171', 'w02288',
    'w02576', 'w02843', 'w02179', 'w02216', 'w02445', 'w02873', 'w02887',
    'w02452', 'w02493', 'w02079', 'w02437', 'w02470', 'w02742', 'w02983',
    'w02687', 'w02717', 'w02719', 'w02819', 'w02943', 'w02959', 'w02144',
    'w02323', 'w02643', 'w02869', 'w02704', 'w02159', 'w02166', 'w02345',
    'w02481', 'w02589', 'w02900', 'w02436', 'w02840', 'w02950', 'w02957',
    'w02120', 'w02422', 'w02791', 'w02122', 'w02177', 'w02466', 'w02552',
    'w02739', 'w02016', 'w02030', 'w02031', 'w02098', 'w02129', 'w02132',
    'w02156', 'w02204', 'w02205', 'w02206', 'w02213', 'w02225', 'w02380',
    'w02485', 'w02497', 'w02516', 'w02532', 'w02547', 'w02597', 'w02628',
    'w02694', 'w02721', 'w02726', 'w02738', 'w02812', 'w02892', 'w02907',
    'w02902',
    'w03073', 'w03215', 'w03364', 'w03404', 'w03445', 'w03564', 'w03600',
    'w03791', 'w03807', 'w03843', 'w03852', 'w03942', 'w03952', 'w03981',
    'w03049', 'w03065', 'w03376', 'w03726', 'w03808', 'w03944', 'w03140',
    'w03204', 'w03220', 'w03288', 'w03119', 'w03150', 'w03272', 'w03756',
    'w03898', 'w03368', 'w03665', 'w03719', 'w03743', 'w03753', 'w03954',
    'w03021', 'w03154', 'w03256', 'w03379', 'w03481', 'w03659', 'w03681',
    'w03967', 'w03039', 'w03195', 'w03196', 'w03224', 'w03319', 'w03534',
    'w03633', 'w03027', 'w03030', 'w03315', 'w03579', 'w03683', 'w03750',
    'w03902', 'w03052', 'w03066', 'w03096', 'w03099', 'w03135', 'w03189',
    'w03203', 'w03219', 'w03221', 'w03241', 'w03244', 'w03263', 'w03267',
    'w03269', 'w03310', 'w03318', 'w03347', 'w03362', 'w03432', 'w03454',
    'w03475', 'w03477', 'w03558', 'w03613', 'w03620', 'w03649', 'w03661',
    'w03684', 'w03694', 'w03708', 'w03830', 'w03875', 'w03889', 'w03951',
    'w03957', 'w03961',
}
