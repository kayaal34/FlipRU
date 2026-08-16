# Leksika — YDS Rusça Kelime Uygulaması

YDS formatına odaklı, premium hissiyatlı Rusça flashcard uygulaması.
**16.234 kelime**, A1'den C1'e kadar seviyelendirilmiş; her kelimede vurgu
işareti, Türkçe okunuş ve mümkün olduğunca örnek cümle var.

## Çalıştırma

```bash
flutter pub get
```

> **Önemli:** Proje klasörünün yolunda Türkçe karakter (`Masaüstü`, `russıan`)
> olduğu için Android derlemesi doğrudan çalışmıyor — Gradle'ın native shader
> derleyicisi bu yola yazamıyor. Kalıcı çözüm klasörü ASCII bir yola taşımak
> (ör. `C:\Users\yahya\Desktop\russian-words-app`). Şu an derlemeler
> `C:\Users\yahya\leksika_build` altındaki kopyadan alınıyor.

Telefonda:

```bash
flutter run
```

Testler:

```bash
flutter test
```

## Veri Boru Hattı

Uygulama verisi `tool/build_dataset.py` ile üretilip
`assets/data/words.json` olarak paketleniyor.

### Kaynaklar

| Kaynak | Ne sağlıyor |
|---|---|
| **Badestrand** Rusça sözlüğü | 58.423 lemma, vurgulu form (`возмо́жность`), kelime türü, çekim tabloları |
| **WikDict ru-tr** | Doğrudan Rusça→Türkçe çeviriler (skorlu) |
| **WikDict ru-en + en-tr** | İngilizce üzerinden köprü — fikir birliği kontrolü |
| **Türkçe Vikisözlük** (kaikki) | Üçüncü doğrulama kaynağı |
| **ru_freq_full** | Yüzey formu frekansları → lemma sırası → CEFR seviyesi |
| **Tatoeba / TED2020 / WikiMatrix / OpenSubtitles** | Örnek cümle çiftleri |

### Çeviri kalitesi

Tek bir sözlüğe güvenmek yeterli değildi: WikDict tek başına `я`'yı
"kişilik", `конкурс`'u "arıza" diye çeviriyordu. Çözüm, **aynı karşılığın
birden fazla bağımsız kaynaktan gelmesini istemek**:

- Doğrudan `ru→tr`
- Köprü `ru→en→tr`
- Türkçe Vikisözlük

Bir karşılık ne kadar çok kaynaktan doğrulanırsa o kadar yüksek puan alıyor.
`conf` alanı bunu taşıyor: **3** = birden çok kaynak anlaştı (14.964 kelime),
**2** = tek güçlü kaynak (1.270 kelime). Puanı düşük 20.706 kayıt tamamen
elendi.

İkincil anlamlarda ayrıca teyit şartı var; yoksa İngilizce eş adlılık
sızıyordu (`кто → who → "DSÖ"`, `мой → mine → "maden"`).

### Örnek cümleler

Kaynaklar kalite sırasıyla taranıyor; bir kelime daha kaliteli bir kaynaktan
cümle aldıysa sonrakiler onu ezmiyor:

1. **Tatoeba** — insan doğrulamalı, kısa ve temiz
2. **TED2020** — eğitimli konuşma dili
3. **WikiMatrix** — ansiklopedik/formal (YDS diline en yakın)
4. **OpenSubtitles** — günlük dil, yalnızca boşluk doldurur

Cümleler 3–14 kelime aralığında, hizalama bozuklukları uzunluk oranıyla
eleniyor. **12.724 kelimenin** (%78) örnek cümlesi var.

### Seviyelendirme

Seviye, *elemeden geçen* kelimeler frekansa göre sıralandıktan sonraki konuma
göre veriliyor:

| Seviye | Kelime |
|---|---|
| A1 | 800 |
| A2 | 1.400 |
| B1 | 2.500 |
| B2 | 3.500 |
| C1 | 8.034 |

Ham frekans sırası kullanılsaydı, karşılığı bulunamayan binlerce sık kelime
yüzünden desteler C1'e yığılıyordu.

### Yeniden üretmek

```bash
cd tool && python build_dataset.py
```

Ham kaynaklar `tool/raw/` altında (depoya dahil değil).

## Klasör Mimarisi

```
lib/
├── main.dart                      Tercihler + kelime havuzu yüklenir, ProviderScope kurulur
├── app.dart                       MaterialApp, tema modu bağlantısı
│
├── core/
│   ├── theme/                     AppPalette (ThemeExtension), tema, tipografi
│   ├── utils/                     haptics.dart, speech_service.dart
│   └── widgets/                   pressable, segmented_switch, progress_ring
│
├── data/
│   ├── models/
│   │   ├── word.dart              Word + WordLevel / WordTheme / PartOfSpeech
│   │   ├── deck.dart              Deste tanımı (seviye | tema | yıldızlı)
│   │   └── app_settings.dart      Kalıcı kullanıcı tercihleri
│   └── repositories/
│       └── word_repository.dart   JSON asset'i isolate'te çözümler, gruplar, arar
│
├── providers/
│   ├── app_providers.dart         SharedPreferences, repository, TTS
│   ├── library_providers.dart     Yıldızlar, öğrenilenler, desteler, ilerleme
│   └── settings_provider.dart     AppSettings kalıcılığı
│
└── features/
    ├── home/                      Kategori & tema seçim ekranı
    ├── study/                     Swipe flashcard + seans özeti
    ├── starred/                   Yıldızlı kelime listesi
    └── settings/                  Ayarlar
```

## Paketler

| Paket | Neden |
|---|---|
| `flutter_riverpod` | `BuildContext`'e bağlı olmayan, test edilebilir state yönetimi |
| `flutter_card_swiper` | Tinder tarzı deste + programatik kaydırma/geri alma |
| `google_fonts` | Inter — tam Kiril desteği, SF Pro'ya yakın metrikler |
| `shared_preferences` | Yıldızlar, ilerleme ve ayarlar cihazda kalıcı |
| `flutter_tts` | Rusça telaffuz; ses yoksa sessizce devre dışı kalır |

## State Management

**Kalıcı durum** Riverpod `Notifier`'larında ve `SharedPreferences`'ta:
`starredProvider`, `learnedProvider`, `settingsProvider`.

**Seansa özgü geçici durum** (hangi kart üstte, çevrildi mi, karar geçmişi)
`StudyScreen`'in kendi `State`'inde — ekrandan çıkınca anlamını yitiren veriyi
global store'a taşımak gereksiz karmaşıklık olurdu.

`StudyScreen` kelime listesini parametre olarak alır ve seans boyunca dondurur;
böylece kullanıcı çalışırken yıldız değiştirse bile deste altından kaymaz.

## Kaydırma Mantığı

| Hareket | Anlam |
|---|---|
| Sağa kaydır | Öğrendim — yeşil katman, `learnedProvider`'a eklenir |
| Sola kaydır | Tekrar et — kırmızı katman, `learnedProvider`'dan çıkarılır |
| Karta dokun | 3B perspektifli flip |
| Sağ üst yıldız | Favorilere ekle/çıkar |
| Geri al | Kelime kaydırma **öncesindeki** durumuna döner |

## Ayarlar

- **Görünüm:** tema (sistem/açık/koyu), vurgu işaretleri, Türkçe okunuş
- **Çalışma:** yön (Rusça→Türkçe / Türkçe→Rusça / karışık), seans uzunluğu,
  günlük hedef, kartları karıştır, öğrenilenleri atla
- **Ses & titreşim:** otomatik telaffuz, konuşma hızı, dokunsal geri bildirim
- **Veri:** havuz/ilerleme sayaçları, yıldızları temizle, ilerlemeyi sıfırla,
  ayarları varsayılana döndür
- **Hakkında:** sürüm ve veri kaynakları

## Bilinen Sınırlar

- Çeviriler otomatik derlendi. Sık kelimelerde isabet yüksek; nadir C1
  kelimelerinde hata görülebilir (`conf` alanı güven düzeyini taşıyor).
- Kelimelerin %21'i bir temaya eşleşiyor; kalanı yalnızca seviye destelerinde.
- `google_fonts` yazı tipini ilk açılışta ağdan indirir. Tam çevrimdışı
  dağıtım için Inter `.ttf` dosyaları `assets/fonts/` altına gömülmeli.
- Aralıklı tekrar (spaced repetition) henüz yok; "tekrar et" kelimeleri
  yalnızca seans sonunda tekrar sunuluyor.
