# -*- coding: utf-8 -*-
"""Onuncu tur: dosya 8 (w07029-w08033) denetimi (2026-08-29)."""

REPORT10_TR = {
    'w07339': ('крестоносец', 'Haçlı'),
    'w07363': ('забияка', 'kabadayı'),
    'w07833': ('росомаха', 'vulverin'),
    'w07897': ('такса', 'daksund'),
    'w07347': ('продление', 'yenileme'),
    'w07278': ('изъятие', 'alıkoyma'),
    'w07045': ('депортация', 'sınır dışı etme'),
    'w08002': ('плавно', 'yavaşça'),
    'w07928': ('пенальти', 'penaltı'),
    'w07283': ('болотный', 'bataklık'),
    'w07357': ('укладка', 'dizilim'),
    'w07377': ('сокращаться', 'kasılmak'),
    # ozel isimler
    'w07878': ('будапешт', 'Budapeşte'),
    'w07892': ('сингапур', 'Singapur'),
    'w07950': ('чад', 'Çad'),
    'w07189': ('палестинец', 'Filistinli'),
    'w07457': ('мали', 'Mali'),
    'w07529': ('кувейт', 'Kuveyt'),
    'w07668': ('кипр', 'Kıbrıs'),
    'w07831': ('босния', 'Bosna'),
    'w07910': ('катар', 'Katar'),
    'w07930': ('монголия', 'Moğolistan'),
    'w07940': ('эфиопия', 'Etiyopya'),
    'w07122': ('шестьсот', 'altı yüz'),
    'w07390': ('семьсот', 'yedi yüz'),
}

REPORT10_RU = {
    'w07878': ('будапешт', 'Будапешт'),
    'w07892': ('сингапур', 'Сингапур'),
    'w07950': ('чад', 'Чад'),
    'w07457': ('мали', 'Мали'),
    'w07529': ('кувейт', 'Кувейт'),
    'w07668': ('кипр', 'Кипр'),
    'w07831': ('босния', 'Босния'),
    'w07910': ('катар', 'Катар'),
    'w07930': ('монголия', 'Монголия'),
    'w07940': ('эфиопия', 'Эфиопия'),
}

REPORT10_TRANSLIT = {
    'w07108': 'ska-ta-BOY-nya',
    'w07691': 'BU-di',
    'w07812': 'VI-ka-çat\'',
}
REPORT10_ACCENTED = {
    'w07108': 'скотобо́йня',
    'w07691': 'бу́де',
    'w07812': 'вы́качать',
}

REPORT10_EXAMPLE = {
    'w07382': ('Давайте не будем пугаться нашей безмерной несущественности.',
               'Sınırsız önemsizliğimizden korkmayalım.'),
    'w07368': ('Она реструктурировала 22 млн долларов государственной задолженности.',
               'TNC, hükûmetin 22 milyon dolarlık borcunu yeniden yapılandırdı.'),
    'w07299': ('Ей поставили диагноз фибромы величиной с грейпфрут.',
               'Greyfurt büyüklüğünde bir fibroid teşhisi kondu.'),
    'w07035': ('Именно благодаря тяжкому труду шахтеров пухнет ваш кошелек.',
               'Madencilerin ağır emeği sayesinde cüzdanınız kabarıyor.'),
    'w07984': ('Абсцесс мы вырезали, но кажется забыли внутри скальпель.',
               'Apseyi kestik ama sanırım içeride bir bisturi unuttuk.'),
    'w07550': ('Оператор несколько часов снимал, как мы вращаем ручки.',
               'Kameraman saatlerce düğmeleri çevirişimizi çekti.'),
    'w07324': ('У моржей появилась толстая жировая прослойка, морские львы приобрели гладкую шкуру.',
               'Morslar kalın bir yağ tabakası kazandı, deniz aslanları ise pürüzsüz bir deri kazandı.'),
    'w07176': ('Бифало - это гибрид американского бизона (буффало) и домашней коровы.',
               'Beefalo, Amerikan bizonu (bufalo) ile evcil ineğin bir melezidir.'),
    'w07250': ('Так что, я могу заночевать и в хлеву.', 'Yani gerekirse ahırda bile kalabilirim.'),
    'w07338': ('Он шел через лощину и видел нечто ужасное.',
               'Vadiden geçerken çok kötü bir şey gördü.'),
    'w07621': ('Наложение жгута без крайней необходимости.',
               'Turnikeyi gerekmedikçe uygulamayın.'),
    'w07683': ('Население приветствовало их как освободителей.',
               'Halk onları kurtarıcı olarak karşıladı.'),
    'w07940': ('Как я уже говорил, я был в Эфиопии.', "Daha önce de söylediğim gibi, Etiyopya'daydım."),
    'w07064': ('Какой бюджет предусмотрен для закупки защитного снаряжения?',
               'Koruyucu ekipman için ayrılan bütçe nedir?'),
    'w07173': ('В моём калькуляторе сели батарейки.', 'Hesap makinemin pilleri bitti.'),
    'w07304': ('Только вспомните как один-единственный прыщик изуродовал вас на несколько дней.',
               'Birkaç gün boyunca sizi rahatsız eden o tek sivilceyi hatırlayın sadece.'),
    'w07392': ('И через несколько недель мы сможем вынуть хрящ-основу.',
               'Ve birkaç hafta içinde kıkırdak iskeleti çıkarabiliyoruz.'),
    'w07743': ('Но у таких помп есть подвох: ограниченный срок эксплуатации.',
               'Ama bu pompaların bir sakıncası var: sınırlı bir kullanım ömürleri var.'),
    'w07800': ('Вы можете видеть глазницу и маленький зуб спереди.',
               'Burada bir göz çukuru ve önündeki küçük bir dişi görebilirsiniz.'),
    'w07863': ('Как вообще можно изгнать кого-то из Пакгауза?',
               "Birini Depodan nasıl sürgün edebilirsin ki?"),
    'w07961': ('На улице лютый мороз.', 'Dışarıda çok şiddetli bir soğuk var.'),
    'w08001': ('(Смех) Некоторые ленятся и делают ошибки.',
               '(Gülüşmeler) Bazıları tembellik edip hata yapıyor.'),
    'w08011': ('Чтобы избежать ранений, они использовали толстые рукавицы и мотоциклетные шлемы.',
               'Yaralanmayı önlemek için kalın eldivenler ve motosiklet kaskları kullanıyorlardı.'),
    'w08031': ('Гимн США в исполнении Джими Хендрикса стал культовым.',
               "Jimi Hendrix'in yorumu en ikonik olanıydı."),
    'w07807': ('Мои студенты часто спрашивают меня: "Что такое социология"?',
               'Öğrencilerim bana sık sık "Sosyoloji nedir?" diye sorar.'),
    'w08020': ('Когда красная жидкость попадает в бесцветную, наступает детонация.',
               'Kırmızı sıvı renksiz olanın içine girince patlama gerçekleşir.'),
    'w07032': ('Великий государь, разреши преклонить колени и поцеловать землю.',
               'Yüce Çar, bırak diz çöküp toprağı öpeyim.'),
    'w07761': ('И потом забьём кальян и сыграем Максимальный выброс.',
               'Daha sonra gidip nargile yakarız ve Maximum Overthruster çalarız.'),
}

REPORT10_CLEAR_EXAMPLE = {
    'w07172', 'w07702', 'w07383', 'w07309', 'w07233', 'w07323', 'w07700',
    'w07085', 'w07295', 'w07220',
    'w07054', 'w07094', 'w07123', 'w07157', 'w07212', 'w07268', 'w07277',
    'w07333', 'w07365', 'w07394', 'w07422', 'w07429', 'w07443', 'w07459',
    'w07496', 'w07503', 'w07546', 'w07561', 'w07594', 'w07610', 'w07640',
    'w07671', 'w07695', 'w07717', 'w07723', 'w07725', 'w07775', 'w07841',
    'w07975',
}

REPORT10_DROP = {
    'w07691',  # bude - arkaik baglac, ornek yok
    'w07286',  # bobyor - bobr (w07963) ile ayni kelimenin tekrari
}

REPORT10_CLEAR_THEME = {
    'w07068', 'w07113', 'w07141', 'w07290', 'w07322', 'w07359', 'w07479',
    'w07556', 'w07713', 'w07810', 'w07845', 'w07955', 'w07097', 'w07288',
    'w07508', 'w07745', 'w07898', 'w07951', 'w07254', 'w07291', 'w07308',
    'w07332', 'w07517', 'w07555', 'w07592', 'w07204', 'w07246', 'w07678',
    'w07123', 'w07763', 'w07928', 'w08032', 'w07145', 'w07331', 'w07499',
    'w07743', 'w07983', 'w07135', 'w07211', 'w07295', 'w07649', 'w07724',
    'w07732', 'w07749', 'w07289', 'w07363', 'w07653', 'w07037', 'w07053',
    'w07220', 'w07248', 'w07553', 'w07663', 'w07800', 'w07864', 'w07997',
    'w07324', 'w07897',
}
