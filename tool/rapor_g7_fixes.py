# -*- coding: utf-8 -*-
"""Dış inceleme raporu, grup 7."""

FIXES = {
    'w06151': ('alaycı', 'ironik / alaycı'),
    'w06194': ('ahlaken', 'manen / duygusal olarak'),
    'w06222': ('tonoz', 'tonoz / kubbe / derleme'),
    'w06232': ('mevcut', 'sayı / nüfus'),
    'w06233': ('bozukluk', 'bozulma / hasar'),
    'w06299': ('ön ek', 'ön ek / (oyun) konsolu'),
    'w06304': ('kilit', 'sürgü / deklanşör'),
    'w06393': ('şarad / kelime oyunu', 'sessiz sinema / mimik oyunu'),
    'w06405': ('gerçeklik', 'özgünlük / hakikilik'),
    'w06409': ('sallamak', 'el sallamak / vazgeçmek'),
    'w06420': ('gizli servis', 'istihbarat servisi / özel servis'),
    'w06427': ('şiddetle esmek', 'kasıp kavurmak / azmak'),
    'w06428': ('tesisatçı', 'tesisatçı / çilingir'),
    'w06437': ('tepsi', 'kum kabı / tepsi'),
    'w06444': ('kapıcı', 'sokak temizlikçisi / kapıcı'),
    'w06458': ('sarnıç', 'tanker / sarnıç'),
    'w06470': ('abluka', 'abluka / tıkanma'),
    'w06545': ('ayırma', 'salgı / akıntı / ayırma'),
    'w06655': ('rutubet', 'nem'),
    'w06658': ('fraksiyon / grup', 'grup / fraksiyon'),
    'w06714': ('ölümlülük', 'ölüm oranı'),
    'w06728': ('anlaşılır', 'görsel / açık'),
    'w06750': ('doldurmak', 'atmak / (üzerine) yağdırmak / ihmal etmek'),
    'w06782': ('Merkür', 'Merkür / cıva'),
    'w06787': ('yaban mersini / böğürtlen türü', 'yaban mersini'),
    'w06823': ('bulunma', 'katılım / hazır bulunma'),
    'w06828': ('bent', 'paragraf'),
    'w06875': ('korumak', 'nöbet tutmak / korumak'),
    'w06885': ('yoğurmak', 'şekillendirmek / yapıştırmak'),
    'w06897': ('sopa', 'çubuk / değnek'),
    'w06913': ('çimdiklemek', 'çimdiklemek / otlamak'),
    'w06915': ('araştırmak', 'el yordamıyla aramak / karıştırmak'),
    'w06937': ('dilim', 'kesim / bölüm'),
    'w06946': ('kanat çırpışı', 'çırpma / sallama'),
    'w06954': ('tuzsuz', 'tatlı (su) / tatsız'),
    'w06957': ('arızi', 'kazara / istemsiz'),
    'w06961': ('ezme', 'ezme / pate'),
    'w06963': ('kütle', 'dizi / veri kümesi / kütle'),
    'w06981': ('tane', 'gren (ağırlık birimi)'),
    'w07011': ('kelebek (küçük) / pervane böceği', 'güve / pervane (kelebek)'),
    'w07044': ('ayrılma', 'yol ayrımı / ayrılma'),
    'w07052': ('dana', 'buzağı'),
    'w07055': ('altlık', 'astar'),
    'w07067': ('hafif', 'ciddiyetsiz / önemsiz'),
    'w07068': ('tencere', 'küçük kazan / bombe şapka'),
    'w07096': ('donuk', 'cansız / donuk'),
}

EXTR = {
    'w06142': ('(Kahkahalar) Şimdi gençlik ve yaşlılıkla ilgili başka bir şiir.', '(Kahkahalar) Şimdi gençlik ve olgunlukla ilgili farklı türden bir şiir daha.'),
    'w06326': ('(Kahkaha) Baskıyı hissediyorum. Altın Oran, çılgınca.', '(Kahkahalar) Tamam, doruğa yaklaşıyorum. Altın Oran.'),
    'w06738': ('Kendimizi ifade etmemize yardım eder ve alkol ve uyuşturucunun yardımı olmadan mutlu olmamızı sağlar.', 'Ruhlarımızı iyileştirir ve hayatımıza mutluluk getirir.'),
    'w06852': ('Hendrik Poinar: Bir sır sakladığımı düşünmüyorum.', 'H.P.: Bunun bir ölçülülük olduğunu sanmıyorum.'),
    'w06875': ('Kollarımı açmıştım.', 'Onu açık kollarla bekledim.'),
    'w06894': ('Bu konuda tek bir doğru yok.', 'Bunun doğru bir ifade olduğunu sanmıyorum.'),
    'w06963': ("Bu aslında Çevre Koruma Departmanı'nın sitesinden. Bu bağlantıların her biri birer Excel sayfası ve her Excel sayfası farklı.", "Tüm veri kümesi Çevre Koruma Departmanı'nın sitesindeydi."),
    'w07052': ('Dana dün gece doğdu.', 'Buzağı dün gece doğdu.'),
    'w07055': ('Altın sırma Moğol hükümdarlarınca giyildi, atlarını süsledi ve çadırlarını kapladı.', 'Altın brokar; Moğol hükümdarlarının ve atlarının giysisi, çadırlarının da astarıydı.'),
}

EXDROP = {
}

DROP = {
}

FIELDS = {'w06782': {'ru': ('меркурий', 'Меркурий'), 'accented': ('мерку́рий', 'Мерку́рий')}}

POS = {'w06380': ('adj', 'noun')}
