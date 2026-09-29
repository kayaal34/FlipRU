# -*- coding: utf-8 -*-
"""Dış inceleme raporu, grup 6."""

FIXES = {
    'w05108': ('şarj (etme), (sabah) jimnastiği', 'şarj / şarj aleti / sabah jimnastiği'),
    'w05110': ('borç', 'kredi / ödünç para'),
    'w05125': ('yaklaşık', 'yaklaşık / örnek (davranış)'),
    'w05145': ('yaymak', 'dağıtmak / yaymak / şişmanlamak'),
    'w05163': ('düzlük', 'ova'),
    'w05207': ('muhtar', 'muhtar / sınıf başkanı'),
    'w05208': ('ben (leke), nişangâh', 'küçük sinek / nişangâh'),
    'w05321': ('coulomb', 'kolye ucu / kulomb (birim)'),
    'w05351': ('makine', 'makine / tezgâh'),
    'w05353': ('hafif', 'düşüncesiz / ciddiyetsiz'),
    'w05354': ('nöbetçi (isim), saatlik', 'saatlik / nöbetçi'),
    'w05383': ('pas vermek', 'pas vermek / geri adım atmak'),
    'w05393': ('gösterişli', 'gür / görkemli'),
    'w05397': ('yük', 'yükleme / doluluk'),
    'w05427': ('soy', 'döl / yavrular'),
    'w05438': ('çörek', 'çörek / ekmek'),
    'w05476': ('kırkmak', 'kesmek / biçmek / kırkmak'),
    'w05496': ('iskandil', 'lot / iskandil'),
    'w05499': ('ritim', 'ölçü (müzik) / nezaket'),
    'w05509': ('içtihat', 'emsal / örnek olay'),
    'w05513': ('işe alma', 'işe alma / kiralama'),
    'w05537': ('ısıtmak', 'yakmak (soba) / batırmak / eritmek'),
    'w05561': ('çağrı', 'çağrı / misyon'),
    'w05591': ('dalgıç elbisesi', 'uzay giysisi / dalgıç elbisesi'),
    'w05594': ('kauçuk', 'kauçuk / lastik'),
    'w05606': ('dinmek', 'sona ermek / durmak'),
    'w05659': ('yetki', 'yetkinlik / yetki alanı'),
    'w05686': ('ocak', 'ocak / odak'),
    'w05687': ('çirkinlik', 'rezalet / çirkinlik'),
    'w05719': ('pazarlık', 'pazarlık / ihale'),
    'w05728': ('temizlik', 'hijyen / temizlik'),
    'w05800': ('rozet', 'priz / (çiçek) rozet'),
    'w05811': ('şaşı', 'eğik / çapraz / şaşı'),
    'w05825': ('battaniye', 'yatak örtüsü / örtü'),
    'w05831': ('kişnemek', 'kişnemek / kahkahayla gülmek'),
    'w05859': ('sahan', 'tava'),
    'w05881': ('sel', 'çamur seli'),
    'w05882': ('söndürmek', 'söndürmek / kısık ateşte pişirmek'),
    'w05896': ('sehpa', 'altlık / stant'),
    'w05899': ('hırsız', 'hırsız / hacker'),
    'w05918': ('suçlamak', 'sitem etmek / suçlamak'),
    'w05926': ('tırpan', 'saç örgüsü / tırpan'),
    'w05936': ('çarpmak', 'el çırpmak / çarpmak'),
    'w05946': ('manivela', 'levye / hurda'),
    'w05949': ('yosun', 'karayosunu'),
    'w05958': ('saygılı', 'saygılı / geçerli (sebep)'),
    'w05963': ('kesir', 'kesir / saçma (av)'),
    'w05971': ('kalkış', 'kalkış / gönderi'),
    'w05981': ('ok / mızrak', 'dart / kısa mızrak'),
    'w05997': ('ayrıcalık', 'ayrıcalık / muafiyet / indirim'),
    'w06046': ('basur', 'basur / (argo) baş belası'),
    'w06065': ('fazla bükmek', 'bükmek / katlamak'),
}

EXTR = {
    'w05106': ('Antikalar satılmıyor ama yine de onlar alıyor.', 'Antika eşya alınmaz, buna rağmen satıldı.'),
    'w05110': ('Benim artık borca ihtiyacım yok.', 'Artık krediye ihtiyacım yok.'),
    'w05125': ('Melbourne Kriket Sahasını doldurmaya yetecek sayıda çocuk.', "Bu, Melbourne Kriket Sahası'ndaki yaklaşık yer sayısıdır."),
    'w05163': ("İsrail Krallığı'nın en büyük düşmanı olan Filistinliler, kıyı düzlüklerinde yaşıyorlar.", "İsrail Krallığı'nın en büyük düşmanı olan Filistinliler, kıyı ovasında yaşıyorlar."),
    'w05373': ('Sertifika Kurumu -- daha doğrusu, öyleydi. geçen sonbahar iflas ediyorlardı', "Hollanda'dan. Yani, temsil ediyordu. Şirket iflas ilan edildi."),
    'w05393': ('Ve bundan sonra, iş daha da vahşileşti.', 'Bundan sonra gür bir şekilde çiçek açmaya başladı.'),
    'w05499': ('Evet, ve şimdi geriye ve öne doğru çalıyoruz. Mike içeride.', 'Şimdi ölçüleri değiş tokuş ederek çalıyoruz. O orada.'),
    'w05509': ("FBI'dan bunu Kongreye sunmasını istediler.", "FBI'dan Kongre'ye emsal göstererek başvurmasını istediler."),
    'w05790': ('Erken bunama için belli bir yaş sınırı var mı?', 'Şizofreni için net bir yaş sınırı var mı?'),
    'w05891': ('Sinek küçüktür, mide bulandırır.', 'Tahtakurusu küçüktür ama kokar.'),
    'w05949': ('Burada, ağaçları saran bir sürü yosun türüne ve her türlü likene de rastlayabilirsiniz.', 'Birçok karayosunu türü ve her türlü liken ağacı sarıp kaplıyor.'),
    'w05983': ('Ağır idrar kokusu nedeniyle et üreticileri androstenon salgısını engellemek için erkek domuzları kısırlaştırır.', 'Bunu, androstenon üretmesinler diye domuz yavrularını kısırlaştıran domuz eti üreticileri dikkate alır.'),
    'w06058': ('Sular yüz elli gün yeryüzünü kapladı.', 'Sular yeryüzünde yüz elli gün boyunca yükseldi.'),
    'w06065': ('İşte bir tane daha -- Bir çöpü alırsınız, içine bir çubuk koyarsınız iki yarım elde edersiniz.', 'İşte bir tane daha: bir pipet alıp içine bir çubuk koyuyor ve ikiye katlıyorsunuz.'),
}

EXDROP = {
    'w06082': 'Что нам нужно решить?',
}

DROP = {
}

FIELDS = {}

POS = {'w05548': ('other', 'noun'), 'w05716': ('other', 'noun')}
