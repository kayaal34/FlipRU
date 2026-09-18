# -*- coding: utf-8 -*-
"""B1 inceleme, parti 2 (w02101–w02304) + tüm veritabanında parçacık/saçma
kayıt temizliği.

FIXES: {id: (beklenen_mevcut_tr, yeni_tr)}
DROP:  {id: beklenen_ru}      — silinecek kayıtlar
POS:   {id: (beklenen, yeni)} — sözcük türü düzeltmesi
"""

FIXES = {
    # Yanlış / yanıltıcı
    'w02298': ('rock', 'kader / rock (müzik)'),  # рок önce "kader"
    'w02105': ('(argo) araba', 'el arabası / (argo) araba'),
    'w02302': ('irk', 'ırk'),  # yazım hatası
    'w02134': ('araklamak', 'çalmak'),
    'w02226': ('tekne', 'büyük kazan / fıçı'),  # "tekne" gemi sanılıyor
    'w02123': ('meksika', 'Meksika'),
    # Eski / resmi / az bilinen
    'w02117': ('fecir', 'şafak / gün doğumu'),
    'w02129': ('redaktör', 'editör'),
    'w02272': ('cet', 'ata / cet'),
    'w02284': ('bilhassa', 'özellikle / pek'),
    'w02140': ('cümbüş yapmak', 'âlem yapmak / içip eğlenmek'),
    'w02170': ('mükemmel biçimde', 'harika / muhteşem'),
    'w02147': ('rüyada görünmek', 'rüyasına girmek'),
    'w02169': ('harfi harfine', 'kelimesi kelimesine / gerçek anlamda'),
    'w02172': ('darlık', 'ihtiyaç / yoksulluk'),
    'w02181': ('sersem', 'aptal / salak'),
    'w02212': ('candan', 'samimi / içten'),
    'w02227': ('gözetmek', 'korumak / nöbet tutmak'),
    'w02271': ('betimleme', 'tarif / açıklama / betimleme'),
    'w02180': ('şekerleme', 'şeker / bonbon'),
    # Ana anlamı eksik
    'w02102': ('yanlış', 'yanlış / sadakatsiz'),
    'w02103': ('dayanmak', 'dayanmak (katlanmak) / dışarı taşımak'),
    'w02107': ('oda', 'mekân / oda / yer'),
    'w02110': ('sinirli', 'sinirli / sinir (sinir sistemine ait)'),
    'w02112': ('barınak', 'barınak / yetimhane / sığınak'),
    'w02116': ('düzen', 'rejim / düzen / mod'),
    'w02118': ('tapınak', 'tapınak / kilise / ibadethane'),
    'w02120': ('perde', 'perde (oyun) / tutanak / eylem'),
    'w02121': ('neden olmak', 'neden olmak / (acı, zarar) vermek'),
    'w02130': ('ortadan kalkmak', 'kaybolmak / yok olmak'),
    'w02135': ('resim', 'resim / çizim'),
    'w02141': ('silah', 'alet / silah / top (topçu)'),
    'w02162': ('bilmece', 'bilmece / gizem'),
    'w02165': ('çekicilik', 'güzellik / cazibe / çok tatlı (biri)'),
    'w02171': ('kavga', 'kavga / tartışma / küslük'),
    'w02173': ('izlemek', 'uymak / takip etmek / ardından gelmek'),
    'w02177': ('mezuniyet', 'sayı (dergi) / yayın / mezun dönemi'),
    'w02179': ('tank, depo (genel kap)', 'depo / tank / (çöp) konteyneri'),
    'w02182': ('saygıdeğer', 'sayın / saygıdeğer'),
    'w02188': ('(uzanıp) almak, elde etmek', '(uzanıp) almak / temin etmek / bıktırmak'),
    'w02190': ('gün', 'gün (24 saat)'),
    'w02192': ('istek', 'talep / gereklilik / şart'),
    'w02197': ('görüntü', 'görüntü / resim / tasvir'),
    'w02198': ('saymak', 'saygı duymak / biraz okumak'),
    'w02200': ('acil', 'acilen / hemen'),
    'w02201': ('uygun', 'düzgün / terbiyeli / iyi'),
    'w02203': ('kovalamak', 'kovalamak / (hızlı) sürmek / kovmak'),
    'w02204': ('belirtmek', 'göstermek / belirtmek / işaret etmek'),
    'w02206': ('uydu', 'uydu / yol arkadaşı'),
    'w02209': ('ret', 'ret / vazgeçme / arıza'),
    'w02210': ('ayva tüyü', 'yumuşak tüy / ayva tüyü'),
    'w02219': ('aldatma', 'aldatma / hile / kandırmaca'),
    'w02220': ('(yardım vb.) sağlamak, göstermek', '(yardım) etmek / göstermek / sağlamak'),
    'w02221': ('kırmak', 'kırıp düşürmek / sökmek / (zorla) elde etmek'),
    'w02222': ('ziyaret etmek', 'ziyaret etmek / (okula, derse) gitmek'),
    'w02225': ('katılan', 'katılımcı / üye'),
    'w02233': ('eksiklik', 'eksiklik / kusur / dezavantaj'),
    'w02235': ('merhamet', 'merhamet / lütuf / iyilik'),
    'w02237': ('dağarcık', 'stok / yedek / dağarcık'),
    'w02240': ('keder', 'acı / keder / felaket'),
    'w02242': ('alet', 'cihaz / makine / aygıt'),
    'w02243': ('düzensizlik', 'dağınıklık / düzensizlik / kargaşa'),
    'w02246': ('ofis', 'büro / ofis'),
    'w02252': ('incelemek', 'incelemek / ele almak / değerlendirmek'),
    'w02254': ('iş', 'iş (sıfat) / işle ilgili'),
    'w02259': ('otomat', 'otomat / makineli tüfek'),
    'w02260': ('artış', 'artış / terfi / yükseltme'),
    'w02262': ('yakalamak', 'yetişmek / yakalamak'),
    'w02263': ('aksan', 'aksan / vurgu'),
    'w02264': ('onur', 'onur / meziyet / artı yön'),
    'w02265': ('bir araya getirmek', 'bir araya getirmek / indirmek / tanıştırmak'),
    'w02275': ('komşu', 'komşu (kadın) / oda arkadaşı (kadın)'),
    'w02283': ('açık', 'aydınlık / açık (renk) / parlak'),
    'w02299': ('gebelik', 'hamilelik / gebelik'),
    'w02304': ('kapı (avlu)', '(bahçe, avlu) kapısı / kale (futbol)'),
}

# Tek başına anlamı olmayan parçacıklar, ses taklitleri ve öğrenene bir şey
# katmayan kayıtlar. Kelime kartı olarak "ли = mi" ya da "бах = bam"
# göstermek öğretmiyor, kafa karıştırıyor.
DROP = {
    'w00269': 'ли',     # soru parçacığı
    'w00337': 'ведь',   # vurgu parçacığı
    'w02940': 'таки',   # parçacık (всё-таки ayrıca var)
    'w03704': 'бах',    # ses taklidi
    'w06892': 'ишь',    # ünlem
    'w06291': 'аз',     # Eski Slavca "ben" / harf adı
    'w06313': 'тау',    # Yunan harfi
    'w08822': 'Обь',    # özel isim (nehir)
    'w08993': 'ява',    # özel isim (Cava adası; kayıtta küçük harf)
    'w05860': 'лаж',    # "acyo", finans jargonu
}

POS = {
    # Kullanıcının 17 Eylül'de "artık / gerçekten" yaptığı уж; "su yılanı"
    # anlamı gidince isim değil.
    'w00100': ('noun', 'other'),
}
