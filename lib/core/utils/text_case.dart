/// Türkçeye uygun büyük harf: Dart'ın `toUpperCase()` yerel ayar bilmiyor,
/// "isim"i "ISIM" yapıyor. Önce i/ı'yı Türkçe karşılıklarına çeviriyoruz.
/// Kiril ve diğer Latin harfler için `toUpperCase()` ile aynı sonucu verir.
String upperTr(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
