"""Ham sozluk kaynaklarindan uygulama veri setini uretir.

Cikti: ../assets/data/words.json

Kaynaklar
---------
  bd_*.csv            Badestrand: lemma + vurgulu form + cekimler + EN karsilik
  ru-tr.sqlite3       Wikdict dogrudan Rusca->Turkce (skorlu)
  ru-en / en-tr       Ingilizce uzerinden kopru (fikir birligi kontrolu icin)
  kaikki_ru_tr.jsonl  Turkce Vikisozluk maddeleri
  ru_freq_full.txt    Yuzey formu frekanslari -> lemma sirasi -> CEFR seviyesi
  sentences_ru_tr.json Tatoeba ru-tr cumle ciftleri

Ceviri secimi
-------------
Tek bir sozluge guvenmiyoruz: ayni Turkce karsilik birden fazla kaynaktan
geliyorsa guven puani yukseliyor. `conf` alani 3 = birden cok kaynak dogruladi,
2 = tek kaynak ama yuksek skorlu, 1 = zayif.
"""

import csv
import gzip
import io
import json
import os
import re
import sqlite3
import sys
import unicodedata
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding='utf-8')
csv.field_size_limit(10**7)

import translit  # noqa: E402

RAW = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'raw')
OUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'assets', 'data', 'words.json',
)

CYR_LEMMA = re.compile(r'^[а-яё]+(?:[ -][а-яё]+)*$')
TR_TERM = re.compile(r"^[a-zçğıöşüâîû]+(?:[ '\-][a-zçğıöşüâîû]+)*$")
WORD_RE = re.compile(r'[а-яёА-ЯЁ]+')

STRESS = '́'

# Uygulamaya girecek azami kelime sayisi.
MAX_WORDS = 9000


def log(*a):
    print(*a, flush=True)


# ─────────────────────────────── Badestrand ───────────────────────────────

BD_META = {
    'bare', 'accented', 'translations_en', 'translations_de', 'gender',
    'partner', 'aspect', 'animate', 'indeclinable', 'sg_only', 'pl_only',
    'type', 'level', 'rank', 'id', 'position', 'derived_from_word_id',
}


def load_badestrand():
    """bare -> {accented, pos, forms, en} ve form -> {bare} haritasi."""
    lemmas = {}
    form_index = defaultdict(set)

    for name, pos in [('nouns', 'noun'), ('verbs', 'verb'),
                      ('adjectives', 'adj'), ('others', 'other')]:
        path = os.path.join(RAW, f'bd_{name}.csv')
        with io.open(path, encoding='utf-8', newline='') as f:
            for row in csv.DictReader(f, delimiter='\t'):
                bare = (row.get('bare') or '').strip().lower()
                if not bare or not CYR_LEMMA.match(bare):
                    continue
                if bare in lemmas:
                    continue

                accented = (row.get('accented') or '').strip()
                forms = set()
                for key, val in row.items():
                    if key in BD_META or not isinstance(val, str):
                        continue
                    for piece in val.split(','):
                        surface = piece.strip().lower().replace("'", '')
                        if surface and CYR_LEMMA.match(surface):
                            forms.add(surface)
                forms.add(bare)

                lemmas[bare] = {
                    'accented': accented or bare,
                    'pos': pos,
                    'forms': forms,
                    'en': [
                        t.strip().lower()
                        for t in re.split(r'[;,]', row.get('translations_en') or '')
                        if t.strip()
                    ],
                    'en_cased': [
                        t.strip()
                        for t in re.split(r'[;,]', row.get('translations_en') or '')
                        if t.strip()
                    ],
                }
                for surface in forms:
                    form_index[surface].add(bare)

    log(f'Badestrand lemma: {len(lemmas)} | benzersiz yuzey formu: {len(form_index)}')
    return lemmas, form_index


# ──────────────────────────────── Frekans ────────────────────────────────

def load_frequency(form_index):
    """Yuzey formu frekanslarini lemmalara dagitip siralama uretir."""
    lemma_freq = Counter()
    path = os.path.join(RAW, 'ru_freq_full.txt')
    with io.open(path, encoding='utf-8', errors='ignore') as f:
        for line in f:
            parts = line.split()
            if len(parts) != 2:
                continue
            surface, count = parts[0].strip().lower(), parts[1]
            if not count.isdigit():
                continue
            owners = form_index.get(surface)
            if not owners:
                continue
            # Belirsiz form birden cok lemmaya ait olabilir; payi bolusturuyoruz.
            share = int(count) / len(owners)
            for bare in owners:
                lemma_freq[bare] += share

    ranked = [w for w, _ in lemma_freq.most_common()]
    rank = {w: i for i, w in enumerate(ranked)}
    log(f'frekans eslesen lemma: {len(rank)}')
    return rank


# ──────────────────────────────── Wikdict ────────────────────────────────

def load_wikdict(filename, term_filter=None, cased_sink=None):
    """written_rep -> [(karsilik, skor, is_good)] listesi.

    [cased_sink] verilirse karsiliklarin ozgun buyuk/kucuk hali de oraya
    yazilir; ozel isim tespiti buna dayaniyor.
    """
    con = sqlite3.connect(os.path.join(RAW, filename))
    out = defaultdict(list)
    query = (
        'select written_rep, trans_list, score, is_good from translation'
    )
    for written, trans, score, is_good in con.execute(query):
        if not written or not trans:
            continue
        key = written.strip().lower()
        for term in trans.split('|'):
            term = term.strip()
            if not term:
                continue
            if cased_sink is not None:
                cased_sink[key].append(term)
            term = term.lower()
            if term_filter and not term_filter.match(term):
                continue
            out[key].append((term, score or 0, is_good or 0))
    con.close()
    log(f'{filename}: {len(out)} anahtar')
    return out


def is_proper_noun(bare, record, english_cased):
    """Ozel isim mi?

    Kelime dagarcigi uygulamasinda "Kanada", "Hayfa", "Amur" gibi maddelerin
    isi yok. En guvenilir isaret, Ingilizce karsiliklarin buyuk harfle
    baslamasi -- Rusca tarafta lemma zaten hep kucuk harfle tutuluyor.
    """
    candidates = [
        t for t in english_cased.get(bare, []) + record['en_cased']
        if t and t[0].isalpha()
    ]
    if not candidates:
        return False
    capitalised = sum(1 for t in candidates if t[0].isupper())
    return capitalised >= max(2, len(candidates) * 0.6)


def load_kaikki_tr():
    """Turkce Vikisozluk: lemma -> [kisa karsilik]."""
    out = defaultdict(list)
    path = os.path.join(RAW, 'kaikki_ru_tr.jsonl')
    with io.open(path, encoding='utf-8') as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get('pos') == 'name':
                continue
            word = (d.get('word') or '').strip().lower()
            if not CYR_LEMMA.match(word):
                continue
            for sense in d.get('senses', []):
                for gloss in (sense.get('glosses') or []):
                    gloss = gloss.strip().lower()
                    # Cekim aciklamalarini ("... sozcugunun cekimi") ele
                    if 'çekimi' in gloss or 'çoğulu' in gloss:
                        continue
                    if TR_TERM.match(gloss) and len(gloss) <= 34:
                        out[word].append(gloss)
    log(f'kaikki tr: {len(out)} anahtar')
    return out


# ──────────────────────────────── Cumleler ────────────────────────────────

NOISE_RE = re.compile(r'[<>{}\[\]|_*#@~]|\.\.|♪|♫')
LATIN_IN_RU = re.compile(r'[a-zA-Z]{3,}')
# Altyazi diyalog isaretleri: bu satirlar cogu zaman yanlis hizalanmis oluyor.
DIALOGUE_RE = re.compile(r'^\s*[-—–]')


def _acceptable(ru, tr):
    """Ders materyali olarak kullanilabilir mi?"""
    if not ru or not tr:
        return False
    if len(ru) > 110 or len(tr) > 130 or len(tr) < 10:
        return False
    if NOISE_RE.search(ru) or NOISE_RE.search(tr):
        return False
    if DIALOGUE_RE.match(ru) or DIALOGUE_RE.match(tr):
        return False
    if LATIN_IN_RU.search(ru):
        return False
    if ru.isupper() or tr.isupper():
        return False
    # Soru/duz cumle uyusmazligi hizalama hatasinin guclu isareti.
    if ('?' in ru) != ('?' in tr):
        return False
    # Cok dengesiz ciftler genelde hizalama hatasidir.
    ratio = len(tr) / max(len(ru), 1)
    return 0.45 <= ratio <= 2.0


def _iter_tatoeba():
    path = os.path.join(RAW, 'sentences_ru_tr.json')
    if not os.path.exists(path):
        return
    for pair in json.load(io.open(path, encoding='utf-8')):
        yield pair['ru'], pair['tr']


def _iter_moses_zip(filename):
    """OPUS moses zip'inden ru/tr satirlarini akis halinde okur."""
    import zipfile

    path = os.path.join(RAW, filename)
    if not os.path.exists(path):
        return
    with zipfile.ZipFile(path) as zf:
        names = zf.namelist()
        ru_name = next((n for n in names if n.endswith('.ru')), None)
        tr_name = next((n for n in names if n.endswith('.tr')), None)
        if not ru_name or not tr_name:
            return
        with zf.open(ru_name) as rf, zf.open(tr_name) as tf:
            ru_stream = io.TextIOWrapper(rf, encoding='utf-8', errors='ignore')
            tr_stream = io.TextIOWrapper(tf, encoding='utf-8', errors='ignore')
            for ru, tr in zip(ru_stream, tr_stream):
                yield ru.strip(), tr.strip()


# Kalite sirasi: temiz ve ogretici kaynaklar once, gurultulu olan en sonda
# yalnizca bosluk doldurur.
CORPORA = [
    ('tatoeba', _iter_tatoeba, None),
    ('ted2020', _iter_moses_zip, 'ted2020_ru-tr.zip'),
    ('wikimatrix', _iter_moses_zip, 'wikimatrix_ru-tr.zip'),
    ('opensubs', _iter_moses_zip, 'opensubs_ru-tr.zip'),
]


def build_sentence_index(form_index, needed):
    """lemma -> en uygun (ru, tr) ornek cumle.

    Kaynaklar kalite sirasiyla taranir; bir lemma daha kaliteli bir kaynaktan
    cumle aldiysa sonraki kaynaklar onu ezmez.
    """
    best = {}

    for label, reader, arg in CORPORA:
        source = reader(arg) if arg else reader()
        if source is None:
            continue

        round_best = {}
        scanned = 0
        try:
            for ru, tr in source:
                scanned += 1
                if not _acceptable(ru, tr):
                    continue
                tokens = WORD_RE.findall(ru.lower())
                if not (3 <= len(tokens) <= 14):
                    continue
                # Ogrenme icin orta uzunluktaki cumleler ideal.
                score = -abs(len(tokens) - 8)
                for token in set(tokens):
                    # Kisa ve cok sahipli formlar yanlis lemmaya baglaniyor
                    # ("гну" hem гнуть hem гну = antilop).
                    if len(token) < 4:
                        continue
                    owners = form_index.get(token, ())
                    if len(owners) > 3:
                        continue
                    for bare in owners:
                        if bare in best or bare not in needed:
                            continue
                        current = round_best.get(bare)
                        if current is None or score > current[0]:
                            round_best[bare] = (score, ru, tr)
        except Exception as exc:  # bozuk/eksik arsiv yapiyi durdurmasin
            log(f'   {label} okunamadi: {exc}')

        best.update(round_best)
        log(f'  {label:<11} +{len(round_best):>5} lemma '
            f'(tarandi {scanned}, toplam {len(best)})')

    log(f'ornek cumlesi olan lemma: {len(best)} / {len(needed)}')
    return {k: (v[1], v[2]) for k, v in best.items()}


# ───────────────────────────────── Temalar ────────────────────────────────

THEME_KEYWORDS = {
    'politics': 'devlet hükümet siyaset seçim oy parti başkan bakan meclis '
                'yasa kanun anayasa vatandaş millet ülke diplomat elçi '
                'müzakere anlaşma barış savaş ordu asker cephe zafer yenilgi '
                'iktidar muhalefet yönetim',
    'economy': 'para ekonomi banka vergi kâr kar zarar piyasa pazar ticaret '
               'satış alım maliyet fiyat ücret maaş bütçe borç kredi yatırım '
               'şirket firma üretim tüketim gelir gider enflasyon kriz '
               'işsizlik hisse faiz sermaye ihracat ithalat',
    'health': 'sağlık hasta hastalık doktor hekim tedavi ilaç hastane ameliyat '
              'yara ağrı kan kalp beyin akciğer mide organ virüs mikrop aşı '
              'bağışıklık beslenme diyet vitamin sağlıklı iyileşmek muayene '
              'teşhis ateş grip kanser',
    'science': 'bilim araştırma deney bilgin fizik kimya biyoloji matematik '
               'atom molekül hücre gen enerji madde kuvvet hız kütle uzay '
               'gezegen yıldız evren teori hipotez kanıt gözlem ölçüm veri '
               'analiz keşif buluş',
    'environment': 'çevre doğa iklim hava su toprak orman ağaç bitki çiçek '
                   'hayvan kuş balık deniz göl nehir dağ ova kirlilik atık '
                   'geri dönüşüm ısınma yağmur kar rüzgar fırtına deprem '
                   'sel kuraklık tür nesil',
    'education': 'okul öğrenci öğretmen ders sınıf sınav not eğitim öğrenim '
                 'üniversite fakülte bölüm diploma kitap defter kalem ödev '
                 'araştırma bilgi öğrenmek öğretmek okumak yazmak dil '
                 'gramer kelime cümle alfabe',
    'technology': 'bilgisayar telefon internet yazılım donanım program '
                  'uygulama site ağ veri dosya ekran klavye robot makine '
                  'motor elektrik cihaz teknoloji dijital sistem kod',
    'work': 'iş çalışan işçi memur müdür patron ofis şirket meslek kariyer '
            'görev sorumluluk toplantı proje sözleşme işe işten emekli '
            'mesai izin terfi başvuru mülakat',
    'law': 'hukuk mahkeme hâkim hakim avukat savcı dava suç ceza hapis '
           'tutuklu polis jandarma delil tanık karar hüküm adalet hak '
           'sözleşme miras',
    'transport': 'araba otomobil otobüs tren uçak gemi bisiklet motosiklet '
                 'yol sokak cadde köprü tünel istasyon durak liman '
                 'havaalanı bilet yolcu sürücü şoför trafik seyahat yolculuk',
    'food': 'yemek yiyecek içecek ekmek et balık tavuk sebze meyve elma '
            'patates domates soğan pirinç makarna çorba tatlı şeker tuz '
            'yağ süt peynir yumurta kahve çay su şarap bira lokanta '
            'restoran mutfak pişirmek',
    'family': 'aile anne baba oğul kız kardeş abla ağabey dede nine torun '
              'amca dayı hala teyze kuzen eş koca karı çocuk bebek evlilik '
              'düğün nişan akraba',
    'emotion': 'sevgi aşk nefret korku kaygı endişe üzüntü keder sevinç '
               'mutluluk neşe öfke kızgınlık utanç gurur umut hayal özlem '
               'acı pişmanlık heyecan şaşkınlık duygu his',
    'body': 'vücut baş kafa saç göz kulak burun ağız diş dil boyun omuz '
            'kol el parmak göğüs karın sırt bacak diz ayak deri kemik kas '
            'sinir damar',
    'home': 'ev daire oda salon mutfak banyo yatak masa sandalye dolap '
            'kapı pencere duvar tavan zemin çatı bahçe balkon anahtar '
            'perde halı lamba eşya mobilya kira komşu',
    'time': 'zaman saat dakika saniye gün hafta ay yıl asır dün bugün yarın '
            'sabah öğle akşam gece mevsim ilkbahar yaz sonbahar kış tarih '
            'takvim geçmiş gelecek şimdi erken geç',
    'culture': 'sanat müzik resim heykel tiyatro sinema film oyun şarkı '
               'dans şiir roman hikâye yazar şair ressam müzisyen sanatçı '
               'müze sergi kültür gelenek örf âdet bayram festival',
    'sport': 'spor futbol basketbol voleybol tenis yüzme koşu maç takım '
             'oyuncu antrenör hakem gol puan şampiyon turnuva olimpiyat '
             'stadyum salon egzersiz idman',
    'military': 'ordu asker savaş silah tüfek top tank uçak gemi general '
                'komutan er subay cephe saldırı savunma zafer yenilgi barış '
                'ateşkes rütbe birlik tabur bomba mermi kalkan zırh',
    'religion': 'din tanrı allah peygamber kilise cami tapınak dua ibadet '
                'namaz oruç günah sevap melek şeytan cennet cehennet ruh '
                'kutsal iman inanç rahip imam ayin haç',
    'geography': 'coğrafya kıta ülke bölge şehir köy ada yarımada körfez '
                 'boğaz okyanus deniz göl nehir dağ tepe ova vadi çöl '
                 'kutup ekvator harita sınır başkent nüfus',
    'agriculture': 'tarım çiftçi tarla ekin buğday arpa mısır pamuk hasat '
                   'ekmek dikmek sulama gübre traktör hayvancılık sürü '
                   'çoban ahır sera bahçıvan tohum kök filiz',
    'construction': 'inşaat yapı bina temel duvar tuğla beton çimento '
                    'demir çelik ahşap tahta çivi çekiç testere vinç '
                    'mimar mühendis usta işçi iskele çatı kiriş',
    'clothing': 'giysi elbise gömlek pantolon etek ceket palto mont kazak '
                'tişört çorap ayakkabı bot terlik şapka eldiven atkı kemer '
                'düğme fermuar kumaş yün pamuk ipek deri moda',
    'shopping': 'alışveriş mağaza market dükkân kasa fiş fatura indirim '
                'kampanya fiyat ucuz pahalı ödeme nakit kart taksit '
                'müşteri satıcı reyon vitrin sepet iade garanti',
    'media': 'medya haber gazete dergi televizyon radyo kanal yayın program '
             'muhabir gazeteci sunucu röportaj ilan reklam basın yayın '
             'sansür kamuoyu bülten manşet',
    'animals': 'hayvan köpek kedi at inek koyun keçi tavuk horoz kuş ördek '
               'kartal aslan kaplan ayı kurt tilki tavşan fare fil zürafa '
               'maymun yılan kurbağa balık köpekbalığı böcek arı karınca',
    'travel': 'seyahat gezi tatil turist tur rehber otel pansiyon rezervasyon '
              'bavul valiz pasaport vize gümrük konaklama kamp çadır plaj '
              'manzara gezmek ziyaret hatıra',
    'personality': 'kişilik karakter huy davranış dürüst yalancı cesur korkak '
                   'cömert cimri nazik kaba sabırlı aceleci çalışkan tembel '
                   'akıllı aptal komik ciddi utangaç kibirli alçakgönüllü',
    'quantity': 'sayı miktar ölçü tane çift düzine yüz bin milyon yarım '
                'çeyrek toplam ortalama fazla eksik az çok bütün parça '
                'kilo gram litre metre santim kilometre derece yüzde',
}

THEME_SETS = {
    key: set(words.split()) for key, words in THEME_KEYWORDS.items()
}


THEME_KEYWORDS_EN = {
    'politics': 'state government politics political election vote party '
                'president minister parliament law constitution citizen nation '
                'country diplomat ambassador negotiation treaty peace war army '
                'soldier military victory defeat power opposition authority',
    'economy': 'money economy economic bank tax profit loss market trade '
               'commerce sale purchase cost price wage salary budget debt '
               'credit investment company firm production consumption income '
               'expense inflation crisis unemployment share interest capital '
               'export import financial',
    'health': 'health healthy patient disease illness doctor physician '
              'treatment medicine drug hospital surgery wound pain blood '
              'heart brain lung stomach organ virus germ vaccine immunity '
              'nutrition diet vitamin heal cure diagnosis fever flu cancer '
              'medical',
    'science': 'science scientific research experiment scientist physics '
               'chemistry biology mathematics atom molecule cell gene energy '
               'matter force speed mass space planet star universe theory '
               'hypothesis evidence observation measurement data analysis '
               'discovery invention',
    'environment': 'environment nature climate weather water soil forest tree '
                   'plant flower animal bird fish sea lake river mountain '
                   'pollution waste recycling warming rain snow wind storm '
                   'earthquake flood drought species ecology',
    'education': 'school student teacher lesson class exam grade education '
                 'university faculty department diploma book notebook pen '
                 'homework knowledge learn teach read write language grammar '
                 'word sentence alphabet study',
    'technology': 'computer phone internet software hardware program '
                  'application website network data file screen keyboard '
                  'robot machine engine electricity device technology '
                  'digital system code',
    'work': 'work job worker employee official manager boss office company '
            'profession career task responsibility meeting project contract '
            'retire shift leave promotion application interview',
    'law': 'law legal court judge lawyer prosecutor case crime punishment '
           'prison prisoner police evidence witness verdict justice right '
           'contract inheritance',
    'transport': 'car automobile bus train plane ship bicycle motorcycle road '
                 'street bridge tunnel station stop port airport ticket '
                 'passenger driver traffic travel journey',
    'food': 'food eat drink bread meat fish chicken vegetable fruit apple '
            'potato tomato onion rice pasta soup dessert sugar salt oil milk '
            'cheese egg coffee tea wine beer restaurant kitchen cook',
    'family': 'family mother father son daughter brother sister grandfather '
              'grandmother grandchild uncle aunt cousin wife husband child '
              'baby marriage wedding engagement relative parent',
    'emotion': 'love hate fear anxiety worry sadness sorrow joy happiness '
               'anger rage shame pride hope dream longing pain regret '
               'excitement surprise feeling emotion',
    'body': 'body head hair eye ear nose mouth tooth tongue neck shoulder arm '
            'hand finger chest belly back leg knee foot skin bone muscle '
            'nerve vein',
    'home': 'house home apartment room hall kitchen bathroom bed table chair '
            'cupboard door window wall ceiling floor roof garden balcony key '
            'curtain carpet lamp furniture rent neighbour neighbor',
    'time': 'time hour minute second day week month year century yesterday '
            'today tomorrow morning noon evening night season spring summer '
            'autumn winter date calendar past future early late',
    'culture': 'art music painting sculpture theatre theater cinema film play '
               'song dance poetry novel story writer poet painter musician '
               'artist museum exhibition culture tradition custom holiday '
               'festival',
    'sport': 'sport football basketball volleyball tennis swimming running '
             'match team player coach referee goal point champion tournament '
             'olympic stadium gym exercise training',
    'military': 'army soldier war weapon gun rifle cannon tank warship '
                'general commander officer front attack defence defense '
                'victory defeat truce regiment battalion bomb bullet armour '
                'armor military troops',
    'religion': 'religion god prophet church mosque temple prayer worship '
                'fasting sin angel devil heaven hell soul holy faith belief '
                'priest ritual cross sacred divine',
    'geography': 'geography continent country region city village island '
                 'peninsula gulf strait ocean sea lake river mountain hill '
                 'plain valley desert pole equator map border capital '
                 'population terrain',
    'agriculture': 'agriculture farmer field crop wheat barley corn cotton '
                   'harvest sow plant irrigation fertiliser fertilizer '
                   'tractor livestock herd shepherd barn greenhouse seed '
                   'root sprout',
    'construction': 'construction building structure foundation wall brick '
                    'concrete cement iron steel timber wood nail hammer saw '
                    'crane architect engineer builder scaffold roof beam',
    'clothing': 'clothes dress shirt trousers pants skirt jacket coat sweater '
                'shirt sock shoe boot slipper hat glove scarf belt button '
                'zipper fabric wool cotton silk leather fashion',
    'shopping': 'shopping shop store market cashier receipt invoice discount '
                'campaign price cheap expensive payment cash card instalment '
                'customer seller aisle window basket refund warranty',
    'media': 'media news newspaper magazine television radio channel '
             'broadcast programme program reporter journalist anchor '
             'interview advertisement press censorship headline bulletin '
             'public opinion',
    'animals': 'animal dog cat horse cow sheep goat chicken rooster bird '
               'duck eagle lion tiger bear wolf fox rabbit mouse elephant '
               'giraffe monkey snake frog fish shark insect bee ant',
    'travel': 'travel trip holiday vacation tourist tour guide hotel hostel '
              'reservation suitcase luggage passport visa customs '
              'accommodation camp tent beach scenery visit souvenir',
    'personality': 'personality character temper behaviour behavior honest '
                   'liar brave coward generous stingy polite rude patient '
                   'hasty diligent lazy clever stupid funny serious shy '
                   'arrogant humble',
    'quantity': 'number quantity measure piece pair dozen hundred thousand '
                'million half quarter total average excess lack few many '
                'whole part kilo gram litre liter metre meter centimetre '
                'kilometre degree percent',
}

THEME_SETS_EN = {
    key: set(words.split()) for key, words in THEME_KEYWORDS_EN.items()
}


def pick_theme(turkish, english):
    """Turkce ve Ingilizce karsiliklardan tema tahmin eder.

    Turkce karsilik cogu zaman 1-3 kelime; Ingilizce taraf cok daha zengin
    oldugu icin ikisini birlikte puanliyoruz.
    """
    tr_tokens = set(re.findall(r'[a-zçğıöşüâîû]+', turkish.lower()))
    en_tokens = set()
    for gloss in english:
        en_tokens |= set(re.findall(r'[a-z]+', gloss.lower()))

    scores = Counter()
    for theme, keywords in THEME_SETS.items():
        hit = len(tr_tokens & keywords)
        if hit:
            scores[theme] += hit * 3
    for theme, keywords in THEME_SETS_EN.items():
        hit = len(en_tokens & keywords)
        if hit:
            scores[theme] += hit * 2

    if not scores:
        return None
    theme, score = scores.most_common(1)[0]
    return theme if score >= 2 else None


# ─────────────────────────── Ceviri secimi ────────────────────────────────

# Kopruden sizan kurum kisaltmalari ve cevrilmemis Ingilizce artiklar.
JUNK_TERMS = {
    'dsö', 'abd', 'bm', 'ab', 'nato', 'tbmm', 'kdv', 'pdf',
    'do', 'be', 'get', 'set', 'put', 'let', 'may', 'can', 'will',
    'bt', 'ebe', 'vs', 'vb',
}


def normalize(term):
    """Karsiligi karsilastirmaya hazir hale getirir.

    Sozlukte "merhaba! selâm!" gibi noktalamali girdiler var; bunlari
    ayiklamak yerine temizliyoruz, yoksa butun selamlasma kelimeleri
    (привет, здравствуйте) veri setinden dusuyor.
    """
    term = term.strip().lower()
    term = re.sub(r'[!?.,;:]+', ' ', term)
    term = re.sub(r'\s+', ' ', term).strip()
    return unicodedata.normalize('NFC', term)


def english_glosses(bare, record, ru_en):
    """Tema tahmini icin lemmaya ait tum Ingilizce karsiliklar."""
    glosses = {normalize(t) for t, _, _ in ru_en.get(bare, ())}
    if record:
        glosses |= {normalize(t) for t in record['en']}
    return glosses


def choose_turkish(bare, record, direct, ru_en, en_tr, kaikki):
    """Kaynaklari birlestirip (karsilik_metni, guven) dondurur."""
    candidates = Counter()
    sources = defaultdict(set)

    # 1) Dogrudan ru->tr
    direct_quality = {}
    direct_score = {}
    direct_order = {}
    for position, (term, score, is_good) in enumerate(direct.get(bare, ())):
        term = normalize(term)
        if not TR_TERM.match(term) or len(term) > 34:
            continue
        weight = 4 if (is_good == 1 or score >= 100) else (3 if score >= 20 else 1)
        candidates[term] += weight
        sources[term].add('direct')
        direct_quality[term] = max(direct_quality.get(term, 0), weight)
        direct_score[term] = max(direct_score.get(term, -1), score)
        direct_order.setdefault(term, position)

    # 2) Ingilizce koprusu: ru->en (Wikdict + Badestrand) -> en->tr
    english = {normalize(t) for t, _, _ in ru_en.get(bare, ())}
    english |= {normalize(t) for t in record['en']}
    for eng in list(english)[:8]:
        for term, score, is_good in en_tr.get(eng, ())[:6]:
            term = normalize(term)
            if not TR_TERM.match(term) or len(term) > 34:
                continue
            candidates[term] += 2 if (is_good == 1 or score >= 20) else 1
            sources[term].add('bridge')

    # 3) Turkce Vikisozluk
    for term in kaikki.get(bare, ()):
        term = normalize(term)
        if not TR_TERM.match(term):
            continue
        candidates[term] += 3
        sources[term].add('kaikki')

    if not candidates:
        return None, 0

    # Siralama once dogrudan Rusca->Turkce sozlugun kendi skoruna bakar.
    # Onceden koprü teyidine +3 bonus veriliyordu ve bu, sozlugun kendi
    # sıralamasini eziyordu: "хромой" icin skoru 2 olan "aksak" varken
    # skoru 0 olan "geyik" one geciyordu.
    def sort_key(term):
        # Wikdict trans_list'i en yaygin karsilik basta olacak sekilde
        # siralanmis; ayni skorda onun sirasina uyuyoruz (yoksa "спасибо"
        # icin "teşekkür ederim" yerine kisa olan "sağ ol" secilyordu).
        return (
            -direct_score.get(term, -1),
            direct_order.get(term, 99),
            -(1 if len(sources[term]) >= 2 else 0),
            -candidates[term],
            len(term),
        )

    ordered = sorted(candidates.items(), key=lambda kv: sort_key(kv[0]))

    # Birincil karsilik en yuksek puanli olan. Ikincil karsiliklarda ise
    # teyit sart: yalnizca Ingilizce koprusunden gelenler es adlilik yuzunden
    # sacmaliyor (who -> "dsö", mine -> "maden", see -> "bak").
    # Birincil karsilik en yuksek puanli olan. Ikincil karsiliklarda dogrudan
    # ru->tr sozlugune guveniyoruz (gercek anlam ayrimlarini o tasiyor:
    # "исключительно" -> ancak / sirf / istisnai). Yalnizca Ingilizce
    # koprusunden gelenler es adlilik yuzunden sacmaliyor, onlar teyit istiyor.
    # En fazla iki anlam: uc ve fazlasi kafa karistiriyor ("да" icin "evet"
    # yeter). En yuksek puanli, yani en bilinen karsilik basta.
    top = [ordered[0][0]]
    for term, _ in ordered[1:]:
        if len(top) >= 2:
            break
        if len(term) <= 2 or term in JUNK_TERMS:
            continue
        if term in top:
            continue
        corroborated = len(sources[term]) >= 2
        from_direct = 'direct' in sources[term]
        if corroborated or from_direct:
            top.append(term)

    best_sources = sources[ordered[0][0]]

    # Dogrudan Rusca->Turkce sozlugun bu karsiligi icermesi sart. Yalnizca
    # Ingilizce koprusu + Vikisozluk anlasmasi yeterli degil: ikisi de ayni
    # es adli Ingilizce kelimeden besleniyor olabiliyor, yani "iki kaynak"
    # aslinda tek bir hatayi iki kez tekrar ediyor.
    primary = ordered[0][0]
    if 'direct' not in best_sources:
        return None, 0

    # Sozlugun skor vermedigi (0) girdiler cogunlukla baglamdan kopmus tek
    # cevirilerdir; en az bir puan almis olmasini sart kosuyoruz.
    if direct_score.get(primary, 0) < 1:
        return None, 0

    corroborated = len(best_sources) >= 2
    confidence = 3 if corroborated else 2
    return ', '.join(top), confidence


# ──────────────────────────────── Seviye ─────────────────────────────────

# Seviye, *elemeden gecen* kelimeler frekansa gore siralandiktan sonraki
# konuma gore veriliyor. Ham frekans sirasi kullanilsaydi, karsiligi bulunamayan
# binlerce sik kelime yuzunden desteler C1'e yigiliyordu.
LEVEL_BOUNDS = [
    ('a1', 700),
    ('a2', 1900),
    ('b1', 3900),
    ('b2', 6400),
]


def pick_level(position):
    for level, bound in LEVEL_BOUNDS:
        if position < bound:
            return level
    return 'c1'


# ────────────────────────────────── Ana ──────────────────────────────────

def main():
    lemmas, form_index = load_badestrand()
    rank = load_frequency(form_index)
    direct = load_wikdict('ru-tr.sqlite3', TR_TERM)
    english_cased = defaultdict(list)
    ru_en = load_wikdict('ru-en.sqlite3', cased_sink=english_cased)
    en_tr = load_wikdict('en-tr.sqlite3', TR_TERM)
    kaikki = load_kaikki_tr()

    try:
        from curated_overrides import OVERRIDES
    except ImportError:
        OVERRIDES = {}
    try:
        from curated_b2c1 import B2_C1, DROP
        OVERRIDES = {**OVERRIDES, **B2_C1}
    except ImportError:
        DROP = set()
    log(f'elle duzeltilmis kayit: {len(OVERRIDES)}')

    # 1. gecis: ceviriler. Hangi kelimelerin hayatta kaldigini bilmeden
    # cumle aramak, 650 MB'lik arsivi bosuna taramak demek.
    stats = Counter()
    accepted = {}
    for bare, record in lemmas.items():
        if bare in DROP:
            stats['elle_cikarildi'] += 1
            continue
        if is_proper_noun(bare, record, english_cased):
            stats['ozel_isim_atlandi'] += 1
            continue

        turkish, confidence = choose_turkish(
            bare, record, direct, ru_en, en_tr, kaikki
        )
        if bare in OVERRIDES:
            turkish = OVERRIDES[bare][0]
            confidence = 4
        if not turkish:
            stats['karsiliksiz'] += 1
            continue
        # Derlemde hic gecmeyen lemma, ogrenmeye deger bir kelime degil.
        if confidence < 4 and bare not in rank:
            stats['frekanssiz_atlandi'] += 1
            continue
        # Eleme artik choose_turkish icinde yapiliyor: dogrudan sozlukte
        # bulunmayan ya da hem zayif hem teyitsiz karsiliklar oraya hic
        # gelmiyor. Burada yalnizca guven duzeyini kaydediyoruz.
        if confidence < 2:
            stats['zayif_atlandi'] += 1
            continue
        accepted[bare] = (turkish, confidence)

    # Sozlukte lemma olarak bulunmayan kaliplar ("несмотря на", "то есть")
    # yalnizca elle listeden gelebiliyor.
    for bare, (turkish, _) in OVERRIDES.items():
        if bare not in accepted:
            accepted[bare] = (turkish, 4)
            stats['elle_eklendi'] += 1

    log(f'ceviriye sahip lemma: {len(accepted)}')

    # 2. gecis: yalnizca bu lemmalar icin ornek cumle.
    sentences = build_sentence_index(form_index, set(accepted))

    rows = []
    for bare, (turkish, confidence) in accepted.items():
        record = lemmas.get(bare)
        override_accent = OVERRIDES.get(bare, (None, None))[1]

        if override_accent:
            accented = override_accent
        elif record:
            accented = record['accented'].replace("'", STRESS)
        else:
            accented = bare

        pronunciation = translit.pronounce(accented) or translit.transliterate(bare)
        example = sentences.get(bare)

        rows.append([
            bare,                                   # 0 ru
            accented,                               # 1 vurgulu
            pronunciation,                          # 2 okunus
            turkish,                                # 3 turkce
            record['pos'] if record else 'other',   # 4 tur
            '',                                     # 5 seviye (asagida)
            pick_theme(turkish, english_glosses(bare, record, ru_en)) or '',
            example[0] if example else '',          # 7 ornek ru
            example[1] if example else '',          # 8 ornek tr
            confidence,                             # 9 guven
        ])
        stats['yazildi'] += 1
        stats[f'guven_{confidence}'] += 1
        if example:
            stats['ornekli'] += 1
        if rows[-1][6]:
            stats['temali'] += 1

    # Siralama: once elle secilmis baslangic kelimeleri (selamlasma ve gunluk
    # kaliplar), sonra sikliga gore. Zamir ve edatlar geriye itiliyor -- ham
    # frekans siralamasinda ilk bolum bastan asagi "я, не, что, в, и" cikiyor
    # ve yeni baslayan icin ogretici degil.
    try:
        from curated_overrides import STARTER, FUNCTION_KEEP
    except ImportError:
        STARTER, FUNCTION_KEEP = [], set()

    starter_rank = {w: i for i, w in enumerate(STARTER)}
    FUNCTION_PENALTY = 260

    def order_key(row):
        bare = row[0]
        if bare in starter_rank:
            return starter_rank[bare] - len(STARTER)
        base = rank.get(bare, 10**9)
        if row[4] == 'other' and bare not in FUNCTION_KEEP:
            base += FUNCTION_PENALTY
        return base

    rows.sort(key=order_key)

    # En sik MAX_WORDS kelimeyle sinirla. Kuyruktaki nadir kelimeler hem
    # ogrenme degeri dusuk hem de otomatik cevirinin en cok hata yaptigi yer.
    if len(rows) > MAX_WORDS:
        stats['kuyruk_kirpildi'] = len(rows) - MAX_WORDS
        rows = rows[:MAX_WORDS]
    for i, row in enumerate(rows):
        row[5] = pick_level(i)
        stats[f'seviye_{row[5]}'] += 1
        row.insert(0, f'w{i:05d}')

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    payload = {
        'fields': ['id', 'ru', 'accented', 'translit', 'tr', 'pos',
                   'level', 'theme', 'exRu', 'exTr', 'conf'],
        'rows': rows,
    }
    with io.open(OUT, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))

    size = os.path.getsize(OUT)
    log()
    log('─── SONUC ───')
    for key, value in sorted(stats.items()):
        log(f'  {key:<16} {value}')
    log(f'  dosya           {OUT} ({size/1024/1024:.1f} MB)')


if __name__ == '__main__':
    main()
