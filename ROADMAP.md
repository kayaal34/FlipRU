# FlipRU — Yol Haritası

Uygulamanın bugünkü hâli sağlam bir kelime öğrenme döngüsü sunuyor. Aşağıdaki
liste, bunu neyin gerçekten ileri taşıyacağına dair önceliklendirilmiş bir
öneri. Sıralama tahmini etkiye göre: yukarıdakiler kullanıcıyı en çok tutar.

---

## 1. Şimdi yapılmalı — temeldeki boşluklar

### 1.1 Aralıklı tekrar (SRS) · **en yüksek etki**
Şu an bir kelimeyi "öğrendim" işaretledikten sonra onu bir daha görmüyorsun.
Oysa kelime öğrenmenin tamamı unutma eğrisiyle savaşmak. SM-2 benzeri basit bir
motor yeter: doğru bilinen kelime 1 → 3 → 7 → 21 → 60 gün sonra tekrar gelir,
yanlış bilinen başa döner.

Ana ekranda "Bugün tekrar edilecek: 23 kelime" kartı, uygulamayı her gün açmak
için tek başına yeterli sebep olur. Seri (streak) mekanizması zaten var; SRS
onu anlamlı kılar.

### 1.2 Kelime detay sayfasının eksikleri
Sayfanın kendisi yapıldı (`word_detail_screen.dart`): bölüm listesinden ve
yıldızlılardan açılıyor, vurgulu hâli, okunuşu, dinleme, anlamı ve örnek
cümlesi var. Eklenmesi gerekenler:
- **Çekim tablosu** — Badestrand verisinde isim hâlleri ve fiil çekimleri
  zaten var, sadece derleyiciye eklenmesi gerekiyor
- Aynı kökten kelimeler (работа / работать / рабочий)
- Bu kelimeyi içeren diğer örnek cümleler

### 1.3 Arama
`WordRepository.search()` yazıldı ama hiçbir ekran kullanmıyor. Ana ekrana bir
arama çubuğu: Rusça, Türkçe ya da okunuş üzerinden 8.996 kelimede anlık arama.

### 1.4 "Zorlandıklarım" otomatik listesi
Sola kaydırılan ve testte yanlış yapılan kelimeler kendiliğinden bir listede
toplansın. Yıldız manuel; bu otomatik olanı.

---

## 2. Öğrenme derinliği

### 2.1 Yazma modu
Çoktan seçmeli tanımayı ölçer, yazmak üretimi. Türkçe anlamı göster, Rusçasını
klavyeden yazdır. Vurgu işareti hariç eşleştir, yakın yanlışlarda "неделя →
недела, bir harf eksik" tarzı geri bildirim ver.

### 2.2 Dinleme modu
Sesi çal, dört şıktan doğru anlamı seçtir. Rusça telaffuz zaten çalışıyor.

### 2.3 Cümle tamamlama
Örnek cümlede hedef kelimeyi boş bırak, şıklardan doldurt. 13.700 örnek cümle
hazır — sadece kelimeyi cümlede bulup gizlemek yeterli.

### 2.4 Ters yön testi
Şu an test hep Rusça → Türkçe. Türkçe → Rusça çok daha zorlayıcı; ayarlardaki
çalışma yönü testlere de uygulanmalı.

### 2.5 Kelime aileleri
Aynı kökten kelimeleri birlikte öğretmek verimliliği ciddi artırır. Badestrand
verisinde `derived_from_word_id` alanı var.

---

## 3. İçerik kalitesi

### 3.1 Elle doğrulanmış kelime sayısını artır
276 kelime elle yazıldı — en sık kullanılanlar ve soyut bağlaçlar. Sıradaki
300–500 kelime (özellikle B1 seviyesindeki fiiller) aynı şekilde geçilmeli.
Otomatik sözlükler somut isimlerde iyi, soyut kelimelerde zayıf.

### 3.2 Kullanıcı bildirimlerini geri besle
Hata bildirim mekanizması çalışıyor ama gelen bildirimler elle işleniyor.
Bildirimleri toplayıp `curated_overrides.py`'a dönüştüren küçük bir betik.

### 3.3 Örnek cümle kapsamını %94'ten yukarı çek
833 kelimenin cümlesi yok. Bunlar için ek derlem (OPUS'ta ru-tr için başka
koleksiyonlar var) taranabilir.

### 3.4 Görsel destek
Somut isimlerde (hayvan, yiyecek, vücut) küçük bir görsel hafızayı ciddi
güçlendirir. Açık lisanslı ikon setleri ya da emoji eşlemesi yeterli olabilir.

---

## 4. Motivasyon ve alışkanlık

### 4.1 Rozetler
"İlk 100 kelime", "7 gün seri", "Bir bölümü hatasız geç", "A1 tamamlandı".
Ucuz ama etkili.

### 4.2 Seri koruma (streak freeze)
Bir gün kaçırma hakkı. Kullanıcıyı tek bir kötü günde kaybetmemek için —
Duolingo'nun en işe yarayan mekaniklerinden.

### 4.3 Haftalık özet
Pazar akşamı bildirimi: "Bu hafta 84 kelime öğrendin, geçen haftaya göre %20
fazla." İstatistik verisi zaten toplanıyor.

### 4.4 Ana ekran widget'ı
Telefonun ana ekranında günün kelimesi. Uygulamayı açmadan da temas.

---

## 5. Ürün ve dağıtım

### 5.1 Gerçek ödeme akışı · **premium için şart**
`in_app_purchase` paketi, Play Console'da üç abonelik ürünü, satın alma
doğrulaması. Şu an ekran hazır, arkası bağlı değil.

### 5.2 Proje klasörünü ASCII yola taşı
`C:\Masaüstü\russıan words app` yolundaki Türkçe karakterler yüzünden Android
derlemesi doğrudan çalışmıyor; şu an ayrı bir kopyadan derleniyor. Klasörü
`C:\Users\yahya\Desktop\fliipru` gibi bir yola taşımak bu çifte yapıyı bitirir.

### 5.3 iOS sürümü
Kod tamamen platform bağımsız. Mac ve Apple Developer hesabı gerekir.

### 5.4 Mağaza hazırlığı
Ekran görüntüleri, tanıtım metni, kategori, gizlilik formu. Logo ve 1024px
mağaza görseli hazır.

### 5.5 Yedekleme
İlerlemeyi Google Drive'a yedekleme. Telefon değiştirince veri kaybı, kullanıcı
kaybının en sinir bozucu sebebi.

---

## 6. Teknik borç

- **Kelime detay ekranı** yazılmadı (bkz. 1.2) — kelime satırına dokunma şu an
  ölü
- `WordRepository.search()` kullanılmıyor (bkz. 1.3)
- Widget test kapsamı quiz akışını ve premium perdelerini içermiyor
- Veri seti 3,5 MB JSON; 30.000 kelimeye çıkılırsa SQLite'a geçmek gerekir
- Örnek cümlelerin hangi derlemden geldiği veri setinde tutulmuyor; kalite
  takibi için `src` alanı eklenmeli

---

## Öneri: sıradaki üç adım

1. **Kelime detay sayfası** — yarım kalan tek şey, kullanıcı zaten dokunmayı
   deniyor
2. **Aralıklı tekrar** — uygulamayı "kelime listesi" olmaktan çıkarıp gerçek
   bir öğrenme aracına dönüştüren şey
3. **Gerçek ödeme akışı** — premium ekranları hazır, gelir kapısı kapalı
