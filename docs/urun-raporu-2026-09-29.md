# FlipRU — Ürün İncelemesi ve İyileştirme Raporu

**Tarih:** 29 Eylül 2026 · **Sürüm:** 1.2.0 (versionCode 4) · **Kelime:** 8.819 (A1 692, A2 1195, B1 1970, B2 2435, C1 2527)

---

## 1. Özet

Uygulama sağlam bir temele oturmuş: veri kalitesi yüksek (üç tur çeviri denetimi), arayüz sade ve tutarlı, tamamen çevrimdışı çalışıyor, reklam ve ücret yok. Eksikler ürünün "öğretme" tarafında: **tekrar sistemi yok**, **arama yok**, **yeni kullanıcı nereden başlayacağını bilmiyor** ve **ilerleme yalnızca cihazda duruyor**. Rakiplerin ayrıştığı yer tam olarak burası.

Ayrıca bugün yayındaki sürümü etkileyen **kritik bir hata bulundu ve düzeltildi** (bkz. bölüm 2).

---

## 2. Bulunan kritik hata: bildirimler hiç gönderilmiyordu

**Belirti:** İnternet varken bile "Bu kelimede hata var" bildirimleri Google Formuna ulaşmıyor, hepsi cihazda bekliyor.

**Sebep:** `android/app/src/main/AndroidManifest.xml` dosyasında `INTERNET` izni yoktu. Flutter bu izni yalnızca hata ayıklama (`debug`) ve profil derlemelerine otomatik ekliyor. Yani senin bilgisayarında test ederken çalışıyordu, **Play'den indirilen yayın sürümünde her ağ isteği baştan hata veriyordu**. `ReportSender.send` her seferinde `SocketException` alıp `false` dönüyordu, bildirim de cihazda kalıyordu.

**Düzeltme (yapıldı):**
- `AndroidManifest.xml` içine `INTERNET` izni eklendi.
- `lib/app.dart`: uygulama her açıldığında bekleyen bildirimler sessizce yeniden gönderiliyor. Böylece kullanıcıların cihazlarında birikmiş eski bildirimler, güncellemeden sonra ilk açılışta kendiliğinden bize ulaşacak.

**Not:** Play Console'daki **Veri güvenliği** formunda "uygulama veri topluyor mu" sorusunu, hata bildirimi gönderildiği için "evet, uygulama içi bilgi / kullanıcı tarafından oluşturulan içerik" olarak işaretlemen gerekiyor. Zaten işaretliyse dokunma.

---

## 3. Rakiplerle karşılaştırma

| | FlipRU | Duolingo | Memrise | Anki | Drops | Quizlet |
|---|---|---|---|---|---|---|
| Türkçe → Rusça odak | **var** | zayıf | zayıf | kullanıcıya bağlı | orta | kullanıcıya bağlı |
| Çevrimdışı | **tam** | kısmi | kısmi | tam | kısmi | kısmi |
| Ücretsiz | **tamamen** | reklamlı | kısıtlı | ücretsiz (iOS ücretli) | 5 dk/gün | kısıtlı |
| Kelime sayısı | **8.819, A1–C1** | ~2–3 bin | ~5 bin | sınırsız | ~2 bin | sınırsız |
| Aralıklı tekrar (SRS) | **yok** | var | var | var (en güçlü) | var | var |
| Seviye belirleme testi | **yok** | var | var | yok | yok | yok |
| Dinleme alıştırması | **yok** | var | var | var | var | var |
| Cümle/dilbilgisi | örnek cümle var, alıştırma yok | var | var | yok | yok | yok |
| Bulut yedek / çoklu cihaz | **yok** | var | var | var | var | var |
| Ana ekran widget'ı | **var** | var | yok | yok | yok | yok |
| Seri (streak) | var | var | var | yok | var | yok |
| Liderlik / sosyal | yok | var | yok | yok | yok | var |

**Okuma:** Fiyat, çevrimdışı çalışma, kelime derinliği ve Türkçe odağı FlipRU'nun güçlü yanları; öğrenme bilimi (tekrar), ilk deneyim (nereden başlayayım) ve veri güvenliği (yedek) zayıf yanları.

---

## 4. Alan alan inceleme

### 4.1 İlk açılış ve yönlendirme
- **Seviye belirleme yok.** Kullanıcı 8.819 kelimeyle karşılaşıyor ve nereden başlayacağını bilmiyor. 10-15 soruluk kısa bir yerleştirme testi, sonunda "Sen B1'desin, buradan başla" demeli. Rakiplerin hepsinde var, bizde yok.
- Tanıtım ekranları uygulamayı anlatıyor ama **ilk 60 saniyede kullanıcıya bir şey öğretmiyor.** Duolingo ilk dakikada ders yaptırıyor. Tanıtımın sonunda doğrudan 5 kelimelik mini bir seansa düşürmek, ilk gün elde tutmayı ciddi artırır.
- Widget'ın varlığı yalnızca ayarlarda anlatılıyor. İlk gün sonunda "Ana ekranına günün kelimesini ekle" diye tek seferlik bir öneri kartı gösterilebilir.

### 4.2 Ana ekran (`lib/features/home/home_screen.dart`)
- Düzen temiz: selamlama, seri, günlük hedef, günün testi, seviyeler/temalar. Sorun yok.
- **Seri tanımı tutarsız.** Ana ekrandaki alev `streakProvider`'dan geliyor ve bu yalnızca **uygulamayı açmayı** sayıyor (`visitProvider`). Yani hiç çalışmadan uygulamayı açan kişi seri kazanıyor. Oysa `dailySummaryProvider.streak` hedefi tutturmayı sayıyor ve bildirim metni de seriyi "çalışma" olarak anlatıyor. İki farklı seri tanımı var; kullanıcıya gösterilen ölçüt gerçek çalışmayı yansıtmalı. Öneri: seri = "o gün en az 1 kelime öğrenildi ya da 1 test çözüldü".
- **Kaldığın yerden devam yok.** Ana ekranda "Devam et: A1 · Bölüm 7" gibi tek dokunuşluk bir kart olmalı. Şu an kullanıcı her seferinde seviye → bölüm listesi → bölüm → çalış diye dört adım gidiyor.

### 4.3 Çalışma (kartlar)
- Kart tasarımı, çevirme, kaydırma ve geri alma iyi çalışıyor; kaydırma rozetleri net.
- **Tekrar sistemi yok.** "Tekrar" dediğin kelime `pending_wrong_words` listesine giriyor ama **programlanmış bir tekrar takvimi yok**. Öğrenilen kelime sonsuza kadar öğrenilmiş sayılıyor. Bu, kelime uygulamasında en büyük eksik. En basit hâliyle Leitner kutusu (1, 3, 7, 16, 35 gün) yeterli: her kelimeye "bir sonraki tekrar tarihi" yaz, ana ekranda "Bugün 24 kelime tekrar" kartı çıksın. Mevcut veri yapısı (SharedPreferences + kelime kimliği) buna uygun, büyük bir mimari değişiklik gerektirmiyor.
- **Dinleme alıştırması yok.** Ses altyapısı (TTS) hazır olduğu için "Duyduğun kelimeyi seç" alıştırması az maliyetle eklenebilir ve dinleme becerisi Rusçada en zorlanılan taraf.
- Kartta örnek cümle var ama **cümleyle alıştırma yok** (boşluk doldurma gibi).

### 4.4 Testler
- Çoktan seçmeli, bölüm testleri, seviye testleri, yazma testleri: kapsam iyi.
- **Yazma testleri yalnızca A1–A2–B1** ve 25 test ile sınırlı (`lib/providers/writing_test_providers.dart`, `_levels`, `kWritingTestCount`). B2 ve C1 çalışan kullanıcının yapacak bir şeyi kalmıyor. Havuz zaten var, sınırı yükseltmek küçük bir iş.
- Çeldiriciler aynı seviyeden rastgele seçiliyor. Daha iyisi: **anlamca yakın kelimelerden** çeldirici seçmek (aynı tema ya da aynı kelime türü). Şu an "не" sorusuna "telefon" gibi alakasız şıklar gelebiliyor, bu testi kolaylaştırıyor.
- Yanlış yapılan kelimelerin **test sonunda "bunları tekrar çalış" diye bir seansa dönüştürülmesi** yok; sonuç ekranı çıkmaz sokak.

### 4.5 Alfabe
- Ders akışı (tanıdık / tuzak / yeni şekiller / oku) çok iyi kurgulanmış, rakiplerde bu netlikte yok.
- Eksik: **el yazısı (kurzif) yok**, Rusçada gerçek hayatta karşılaşılıyor. İkinci eksik: harflerin **ayırt edici sesletim alıştırması** yok (ör. ы/и, ш/щ ikilileri için "hangisini duydun").

### 4.6 İstatistik
- Son 7/30 gün grafiği, en verimli gün, çözülen test sayısı var; temiz.
- Eksik: **seviye bazlı ilerleme** (A1 %100, B1 %38 gibi) tek ekranda görünmüyor. Kullanıcıya en çok gurur veren şey bu.
- Eksik: **öğrenme eğrisi / tahmini bitiş** ("bu hızla B1'i 42 günde bitirirsin") — motivasyonu artıran, ucuz bir hesap.

### 4.7 Ayarlar
- Düzen iyi: hesap ve veri üstte, sonra görünüm, çalışma, ses, bildirim.
- Ayar sayısı fazla olabilir (seans uzunluğu, soru sayısı, çalışma yönü, transliterasyon, vurgu işareti, düşük güvenilirlik filtresi, widget tazeleme...). Yeni kullanıcı bunların çoğunu anlamaz. Öneri: ileri düzey olanları "Gelişmiş" başlığı altına almak.
- **Yedekleme yok.** Telefon değiştiren kullanıcı bütün ilerlemesini kaybeder. Bulut gerekmez: "İlerlemeyi dosyaya aktar / dosyadan geri yükle" (JSON) yeterli ve çevrimdışı kimliğine de uyar.

### 4.8 Ses
- Sistem TTS kullanılıyor; Rusça ses paketi kurulu değilse uyarı ve indirme yönlendirmesi var, bu doğru çözüm.
- Zayıf nokta: **ses kalitesi cihaza göre değişiyor** ve bazı cihazlarda vurgu yanlış okunuyor. Uzun vadede A1-A2 kelimeleri için gömülü ses dosyası (yaklaşık 1.900 kelime) düşünülebilir; uygulama boyutu artar ama kalite garanti olur.

### 4.9 Widget
- Tasarım ve içerik iyi.
- **Kendi zamanlayıcısı yok**: kelime yalnızca uygulama açılınca değişiyor (`lib/app.dart`, `_syncWidget`). Uygulamayı üç gün açmayan kullanıcı aynı kelimeyi görüyor — oysa widget'ın işi tam olarak uygulamayı açmayanı geri getirmek. `WorkManager` ya da mevcut bildirim zamanlayıcısıyla günlük tazeleme eklenmeli.

### 4.10 Teknik
- `flutter analyze` temiz, uyarı yok.
- **Otomatik test neredeyse yok**: `test/` altında yalnızca `widget_test.dart` var. En azından kelime çözümleme, seri hesabı, test havuzu ve ilerleme kaydı için birim testleri olmalı; her sürümde elle tıklamak yerine.
- 2,2 MB'lık `words.json` açılışta ayrı bir isolate'te çözümleniyor, bu doğru yapılmış.
- **Çökme takibi yok.** Play Console vitals dışında hiçbir veri yok; kullanıcıda ne çöktüğünü göremiyorsun. Gizlilik duruşunu bozmak istemiyorsan bile, en azından "uygulama çöktü" bilgisini toplayan hafif bir çözüm (Crashlytics yerine Sentry'nin kişisel veri toplamayan kurulumu) değerlendirilebilir.
- iOS tarafında `Info.plist` içindeki `CFBundleDisplayName` hâlâ **"Leksika"**; App Store'a çıkmadan önce düzeltilmeli.

---

## 5. Yapılacaklar listesi

### P0 — Bu güncellemede (Play testi sürüyor, hızlı ve görünür)
- [x] `INTERNET` izni eklendi, bildirimler artık gidiyor
- [x] Açılışta bekleyen bildirimler otomatik gönderiliyor
- [ ] Seri tanımını tek bir ölçüte indir: "o gün çalıştıysa" (ana ekran, widget, bildirim aynı sayıyı göstersin)
- [ ] Ana ekrana **"Kaldığın yerden devam et"** kartı
- [ ] Test sonucu ekranına **"Yanlışları çalış"** düğmesi
- [ ] Yazma testlerini B2 ve C1'e aç, test sayısını artır

### P1 — Sonraki sürüm (ürünü rakiplerle aynı hizaya getirir)
- [ ] **Aralıklı tekrar (Leitner)**: her kelimeye sonraki tekrar tarihi, ana ekranda "Bugün tekrar edilecek X kelime"
- [ ] **Seviye belirleme testi** ve ilk açılışta "buradan başla" yönlendirmesi
- [ ] **Dinleme alıştırması** (duyduğun kelimeyi seç)
- [ ] **İlerlemeyi dışa/içe aktar** (telefon değiştirince kaybolmasın)
- [ ] Widget'ın kendi günlük tazelemesi
- [ ] Çeldiricileri anlamca yakın kelimelerden seç
- [ ] İstatistiklere seviye bazlı ilerleme ve tahmini bitiş

### P2 — Daha sonra
- [ ] Cümleyle alıştırma (boşluk doldurma)
- [ ] Alfabede el yazısı ve benzer ses ayrımı alıştırmaları
- [ ] A1–A2 için gömülü ses dosyaları
- [ ] Ayarlarda "Gelişmiş" ayrımı
- [ ] Birim testleri (kelime çözümleme, seri, test havuzu, ilerleme)
- [ ] iOS: `CFBundleDisplayName` düzeltmesi, ikon, ses paketi uyarısının iOS hâli
- [ ] İngilizce arayüz dili (pazarı genişletir)

---

## 6. Play testi için not

Bu 14 günlük kapalı test döneminde **2-3 küçük güncelleme yayınlamak** başvurunun kabul şansını artırıyor. P0 listesi tam olarak bunun için uygun: her biri küçük, görünür ve sürüm notuna yazılabilir. Örnek sürüm notu:

> 1.2.1 — Hatalı kelime bildirimleri artık doğrudan bize ulaşıyor (test kullanıcılarının bildirdiği sorun). Seri hesabı çalışmaya göre düzeltildi. Ana ekrana "kaldığın yerden devam et" kartı eklendi.
