# -*- coding: utf-8 -*-
"""Dış inceleme raporu, grup 5."""

FIXES = {
    'w04064': ('(kapıyı) çarpmak', 'alkışlamak / (kapıyı) çarpmak'),
    'w04075': ('kıskançlık', 'haset / gıpta'),
    'w04090': ('vahiy', 'kıyamet / vahiy'),
    'w04190': ('dikkat', 'ihtiyat / temkin'),
    'w04220': ('çıkış', 'çıkış / sefer'),
    'w04221': ('pişirmek', 'kaynatmak / haşlamak'),
    'w04237': ('yırtmak', 'yırtmak / (argo) dövmek'),
    'w04243': ('köklü', 'radikal / köklü'),
    'w04259': ('geri çekilme', 'geri çekilme / atık'),
    'w04260': ('anlamak', 'sökmek / anlamak'),
    'w04274': ('firar', 'kaçış'),
    'w04299': ('katlamak', 'katlamak / toplamak / birleştirmek'),
    'w04326': ('adliye', 'adalet'),
    'w04340': ('kabakulak', 'domuzcuk / kabakulak'),
    'w04342': ('ilahi', 'marş / ilahi'),
    'w04379': ('rehber', 'rehber / kondüktör / iletken'),
    'w04387': ('işleme', 'gerçekleştirme / işleme'),
    'w04424': ('ahlaksız', 'ahlaksız / kısır (döngü)'),
    'w04434': ('söndürmek', 'söndürmek / (borç) kapatmak'),
    'w04448': ('doldurmak (kum vb.) / üstünü örtmek / soru yağmuruna tutmak', 'uykuya dalmak / (üstünü) örtmek'),
    'w04498': ('havaya uçurmak / (sağlığı) bozmak', 'havaya uçurmak / baltalamak / (sağlığı) bozmak'),
    'w04556': ('ele geçirmek', 'ele geçirmek / ustalaşmak'),
    'w04573': ('meyve', 'yaban meyvesi / meyve'),
    'w04576': ('anket', 'form / anket formu'),
    'w04591': ('silgi', 'lastik / silgi'),
    'w04595': ('hayranlık', 'hayranlık / kendinden geçme'),
    'w04626': ('sallamak', 'pompalamak / sallamak / (kas) çalıştırmak'),
    'w04638': ('atmaca', 'şahin'),
    'w04695': ('büfe / (mobilya) büfe', 'büfe (yemek yeri / mobilya)'),
    'w04696': ('karalama', 'taslak / çizim'),
    'w04702': ('yol vermek / taviz vermek', 'vazgeçmek / yol vermek'),
    'w04723': ('koyu', 'sık / koyu'),
    'w04742': ('lüks', 'süit / lüks'),
    'w04747': ('plaster', 'yara bandı / flaster'),
    'w04759': ('mekanik', 'mekanik / manuel'),
    'w04774': ('ütülemek', 'ütülemek / okşamak'),
    'w04793': ('aktarma', 'aktarma / nakil'),
    'w04814': ('beceriksiz', 'yeteneksiz / yetersiz'),
    'w04870': ('elle yapılan', 'el ile yapılan / evcil'),
    'w04874': ('miktar', 'büyüklük / nicelik'),
    'w04879': ('dayanak', 'dayanak / vurgu'),
    'w04911': ('katı', 'sıkı / gergin'),
    'w04934': ('şefkat', 'okşama / şefkat / gelincik'),
    'w04939': ('sırt', 'sırt / omurga / sıradağ'),
    'w05008': ('gam', 'gama / gam'),
    'w05029': ('telaşlı', 'huzursuz / telaşlı'),
    'w05050': ('gözetlemek', 'beklemek / kollamak'),
}

EXTR = {
    'w04075': ('Diğer ülkeler topraklarımıza kıskançlıkla bakıyorlar.', 'Diğer ülkeler topraklarımıza haset ile bakıyor.'),
    'w04281': ("CA: Kuzey Oxford'dan gelecek füzeler mesela.", 'KA: Kuzey Oxford. Saldırı füzeleri kalkışa hazır.'),
    'w04323': ('Bileşikleri orta çağlarda biliniyordu.', 'Madalyonlar orta çağlardan beri bilinir.'),
    'w04349': ('Daşa çekmeceyi güçlükle açtı.', 'Daşa mücevher kutusunu güçlükle açtı.'),
    'w04350': ('Buradan takip ediyorum -- (Kahkahalar) ve sadece merdiveni uçurmak zorunda kalacağım.', 'Yani şu an burada sürünüyorum (Kahkahalar) ve şu merdiveni havaya uçurmam gerek.'),
    'w04375': ('Ama orada duramayız. Başlamasıyla birlikte bitemez.', 'Ama hepsi bu değil. Tüzüğü ilan etmekle yetinmek mümkün değil.'),
    'w04387': ('İbadet ederken, dikkatle görevine odaklanıyordu.', 'Bağış yaparken göreve odaklanır.'),
    'w04391': ('Banyo cumartesileri açıktır.', 'Hamam cumartesi günleri açıktır.'),
    'w04398': ('Başlarda, biraz çekinmiştim. Çünkü grup, mahkumlar arasında "Katili Kucakla" olarak biliyordu.', 'Başta "Eşkıyayı Kucakla" denen bir gruba katılmak pek istemiyordum.'),
    'w04420': ('"Sosyal yorum" ve "saygısızlık" 70\'li yıllar boyunca yükseliyor.', "70'lerde toplumsal eleştiri ve saygısızlık yükselişte."),
    'w04454': ('Parayı oyun kullanıcıları, tatlı tohumlar almak için aldıkları Cashlar ile ödemişlerdir.', 'Gelirlerini, yatırımcıların pay alırken ödediği komisyonlardan elde ediyorlardı.'),
    'w04527': ('Var olmama sebepleri, yazılı panelimde bulunuyor.', 'Bazen belgesel bölümde yokluklarının nedeni belirtilir.'),
    'w04540': ('Bu kilisenin orijinal dekorasyonu daha küçük bir dünyayı yansıtıyordu.', 'Şapelin ilk dekorasyonu küçük bir dünyayı yansıtıyordu.'),
    'w04574': ('Bazı toplumlarda bu hayvanlar çeşitli amaçlar için kullanılmaktadırlar.', 'Bu melez artık bazı ülkelerde kullanılıyor.'),
    'w04595': ("Baptistler Büyük Felaket'tan önce İsa'nın dünyaya inip takipçilerini cennete götüreceğine inanırlar.", "Baptistler, Büyük Sıkıntı başlamadan önce Kilise'nin göğe alınacağına inanır."),
    'w04613': ('Seni bir online arkadaşlık sitesinde popüler yapan şey bu dağılım.', 'Değerlendirmelerdeki farklılık, tanışma sitesinde popülerliği artırır.'),
    'w04688': ("Babasının ölümünden sonra 7 Ocak 1989'da imparator oldu.", "İmparatorun 7 Ocak 1989'daki ölümünden sonra imparatoriçenin sağlığı bozuldu."),
    'w04937': ('Babasının intikamını alan asil bir evlat mı?', 'O, babasının intikamını alan asil bir soylu mu?'),
    'w05029': ('Onu korkunç derecede rahatsız edici buluyorum.', 'Onu son derece huzursuz buluyorum.'),
    'w05062': ('Bisiklet kablosu sağ kolunda, hala eski teknolojiyi kullanıyorum.', 'Sağ tarafta hâlâ kablolu eski bir protez duruyor.'),
    'w05067': ('Hanım hanımcık olmak için adeti görmezden gelmeyi öğrendim.', 'Edep gereği adet konusunda cahil kaldım.'),
}

EXDROP = {
}

DROP = {
}

FIELDS = {'w04368': {'ru': ('венера', 'Венера')}, 'w04410': {'ru': ('пакистан', 'Пакистан')}, 'w04694': {'ru': ('будда', 'Будда'), 'accented': ('бу́дда', 'Бу́дда')}}
