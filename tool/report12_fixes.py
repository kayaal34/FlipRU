# -*- coding: utf-8 -*-
"""On ikinci tur: yeni yerel yonetim araciyla (tool/word-editor) yapilan ilk
tarama, bu haftaki duzeltmelerin kazara olusturdugu iki kopyayi yakaladi.

- w02984 (rapor7'de 'ezjat'' -> 'ездить' diye duzeltilmisti) ile w00981
  (zaten var olan, dogru 'ездить' kaydi) ayni kelime oldu. w02984 dusuruldu;
  w00981 daha genel/kullanisli oldugu icin kaldi.
- w06652 (rapor9'da 'sena' -> 'сено' diye duzeltilmisti) ile w04746 (zaten
  var olan 'сено' kaydi) ayni kelime oldu. w04746 dusuruldu; w06652'nin
  ornek cumlesi ve cevirisi ("kuru ot") daha dogru oldugu icin o kaldi --
  ama vurgu isareti duzeltilmemis eski haliyle kalmisti ("се́на"), simdi
  duzeltiliyor.
"""

REPORT12_DROP = {
    'w02984',  # ezdit' - w00981 ile ayni, o kaldi
    'w04746',  # seno (saman, orneksiz) - w06652 ile ayni, o kaldi
}

REPORT12_ACCENTED = {
    'w06652': 'се́но',
}
