import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flipru/providers/writing_test_providers.dart';
import 'package:flipru/app.dart';
import 'package:flipru/data/models/app_settings.dart';
import 'package:flipru/core/i18n/strings.dart';
import 'package:flipru/data/models/deck.dart';
import 'package:flipru/data/models/word.dart';
import 'package:flipru/data/models/word_report.dart';
import 'package:flipru/data/repositories/word_repository.dart';
import 'package:flipru/providers/report_provider.dart';
import 'package:flipru/providers/unit_providers.dart';
import 'package:flipru/providers/app_providers.dart';
import 'package:flipru/providers/daily_provider.dart';
import 'package:flipru/providers/library_providers.dart';
import 'package:flipru/providers/settings_provider.dart';

/// Testler asset'e bağlı kalmasın diye sentetik bir havuz kuruyoruz.
/// Sahte kelimelere rakamsiz bir benzersiz ek.
///
/// Yazma havuzu Turkce karsiligin yalnizca harflerden olusmasini istiyor;
/// "kelime7" gibi bir karsilik havuza girmez ve testler bos liste gorurdu.
String _ek(int i) {
  const harfler = 'abcdefghij';
  return '${harfler[(i ~/ 10) % 10]}${harfler[i % 10]}';
}

Word _word(int i, WordLevel level, WordTheme? theme) => Word(
      id: 'w${i.toString().padLeft(3, '0')}',
      russian: 'слово${_ek(i)}',
      accented: 'сло́во${_ek(i)}',
      transliteration: 'SLO-va${_ek(i)}',
      turkish: 'kelime${_ek(i)}',
      exampleRu: 'Это слово${_ek(i)}.',
      exampleTr: 'Bu kelime${_ek(i)}.',
      level: level,
      theme: theme,
      partOfSpeech: PartOfSpeech.noun,
      confidence: 3,
    );

List<Word> _buildWords() {
  final words = <Word>[];
  var i = 0;
  for (final level in WordLevel.values) {
    for (var n = 0; n < 20; n++) {
      // Her seviyeden 20 kelime; ilk 15'i ekonomi temasına düşsün ki
      // tema destesi eşiğini (12) geçsin.
      words.add(_word(i, level, i < 15 ? WordTheme.economy : null));
      i++;
    }
  }
  return words;
}

void main() {
  late SharedPreferences prefs;
  late WordRepository repository;

  setUp(() async {
    // Tanitim ekrani gorulmus sayiliyor: ekran testleri dogrudan uygulamaya
    // acilsin. Tanitimin kendisi ayri bir testte deneniyor.
    SharedPreferences.setMockInitialValues({
      'app_settings': '{"onboardingDone":true}',
    });
    prefs = await SharedPreferences.getInstance();
    repository = WordRepository.fromWords(_buildWords());
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wordRepositoryProvider.overrideWithValue(repository),
        ],
      );

  Widget harness() => ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wordRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FlipRuApp(),
      );

  /// Açılış animasyonunu atlayıp doğrudan sekmelere geçer.
  ///
  /// Süre, açılış ekranının animasyonu (1,5 sn) + tanıtım metni okunsun diye
  /// eklenen duruşu (1,4 sn) + geçiş animasyonunu (0,42 sn) kapsıyor.
  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  group('veri katmanı', () {
    test('satır dizisinden kelime çözümlenir', () {
      final word = Word.fromRow([
        'w00042', 'возможность', 'возмо́жность', "vaz-MOJ-nast'",
        'imkân, olanak', 'noun', 'b1', 'economy',
        'У нас есть возможность.', 'Bir imkânımız var.', 3,
      ]);

      expect(word.russian, 'возможность');
      expect(word.level, WordLevel.b1);
      expect(word.theme, WordTheme.economy);
      expect(word.partOfSpeech, PartOfSpeech.noun);
      expect(word.hasExample, isTrue);
    });

    test('boş tema alanı null olur ve renk seviyeden gelir', () {
      final word = Word.fromRow([
        'w1', 'дом', 'дом', 'DOM', 'ev', 'noun', 'a1', '', '', '', 2,
      ]);

      expect(word.theme, isNull);
      expect(word.hasExample, isFalse);
      expect(word.tint, isNotNull);
    });

    test('seviye destesi yalnızca o seviyeyi içerir', () {
      final words = repository.wordsOf(Deck.fromLevel(WordLevel.b1));
      expect(words, hasLength(20));
      expect(words.every((w) => w.level == WordLevel.b1), isTrue);
    });

    test('tema destesi yalnızca eşiği geçen temalar için üretilir', () {
      final ids = repository.themeDecks.map((d) => d.theme).toSet();
      expect(ids, {WordTheme.economy});
    });

  });

  group('kütüphane mantığı', () {
    test('yıldız aç/kapa durumu cihazda saklanır', () {
      final c = container();
      final starred = c.read(starredProvider.notifier);

      expect(starred.toggle('w001'), isTrue);
      expect(c.read(starredProvider), {'w001'});
      expect(prefs.getStringList('starred_word_ids'), ['w001']);

      expect(starred.toggle('w001'), isFalse);
      expect(c.read(starredProvider), isEmpty);
    });

    test('yıldızlı deste yıldız değişimini yansıtır', () {
      final c = container();
      expect(c.read(deckWordsProvider(Deck.starred.id)), isEmpty);

      c.read(starredProvider.notifier).toggle('w005');
      expect(
        c.read(deckWordsProvider(Deck.starred.id)).map((w) => w.id),
        ['w005'],
      );
    });

    test('öğrenilen kelime deste ilerlemesini yükseltir', () {
      final c = container();
      final before = c.read(deckProgressProvider('level_a1'));
      expect(before.learned, 0);

      c.read(learnedProvider.notifier).markLearned('w000');
      final after = c.read(deckProgressProvider('level_a1'));

      expect(after.learned, 1);
      expect(after.total, before.total);
    });

    test('tekrar işareti öğrenilenler kümesinden çıkarır', () {
      final c = container();
      final learned = c.read(learnedProvider.notifier);

      learned.markLearned('w010');
      expect(c.read(learnedProvider), contains('w010'));

      learned.markForReview('w010');
      expect(c.read(learnedProvider), isNot(contains('w010')));
    });
  });

  group('günlük hedef', () {
    test('öğrenilen kelime bugünkü sayacı artırır', () {
      final c = container();
      expect(c.read(dailySummaryProvider).today, 0);

      c.read(learnedProvider.notifier).markLearned('w001');
      c.read(learnedProvider.notifier).markLearned('w002');

      expect(c.read(dailySummaryProvider).today, 2);
    });

    test('aynı kelimeyi ikinci kez işaretlemek sayacı artırmaz', () {
      final c = container();
      c.read(learnedProvider.notifier).markLearned('w001');
      c.read(learnedProvider.notifier).markLearned('w001');

      expect(c.read(dailySummaryProvider).today, 1);
    });

    test('tekrar işareti günlük sayacı geri sarar', () {
      final c = container();
      c.read(learnedProvider.notifier).markLearned('w001');
      expect(c.read(dailySummaryProvider).today, 1);

      c.read(learnedProvider.notifier).markForReview('w001');
      expect(c.read(dailySummaryProvider).today, 0);
    });

    test('hedefe ulaşınca seri başlar', () {
      final c = container();
      c.read(settingsProvider.notifier).update((s) => s.copyWith(dailyGoal: 3));
      expect(c.read(dailySummaryProvider).streak, 0);

      for (var i = 0; i < 3; i++) {
        c.read(learnedProvider.notifier).markLearned('w00$i');
      }

      final summary = c.read(dailySummaryProvider);
      expect(summary.goalReached, isTrue);
      expect(summary.streak, 1);
      expect(summary.ratio, 1.0);
    });
  });

  group('bölümler', () {
    test('deste 20şerlik bölümlere ayrılır ve sıra korunur', () {
      final c = container();
      // B1'de 20 kelime var -> tek bölüm; tüm seviye destesi 20'şer bölünür.
      final units = c.read(deckUnitsProvider('level_b1'));
      expect(units, hasLength(1));
      expect(units.first.unit.words, hasLength(20));
      expect(units.first.unit.words.first.id, 'w040');
    });

    test('baştan yalnızca ilk bölüm açık, gerisi kilitli', () {
      final c = container();
      // Yıldızlı deste 100 kelime alacak sekilde dolduruluyor.
      for (var i = 0; i < 100; i++) {
        c.read(starredProvider.notifier).toggle('w${i.toString().padLeft(3, '0')}');
      }
      final units = c.read(deckUnitsProvider('starred'));
      expect(units, hasLength(5));
      // Sıralı ilerleme: hiçbiri geçilmemişken yalnızca ilk bölüm açık.
      expect(units[0].unlocked, isTrue);
      expect(units[1].unlocked, isFalse);
    });

    test('bölüm geçilince açık pencere bir bölüm ilerler', () {
      final c = container();
      for (var i = 0; i < 100; i++) {
        c.read(starredProvider.notifier).toggle('w${i.toString().padLeft(3, '0')}');
      }
      final first = c.read(deckUnitsProvider('starred')).first.unit;

      // Eşik %80 -> 20 kelimenin 16'sı.
      for (final word in first.words.take(16)) {
        c.read(learnedProvider.notifier).markLearned(word.id);
      }

      // 1. bölüm geçilince yalnızca 2. bölüm açılır.
      final units = c.read(deckUnitsProvider('starred'));
      expect(units[0].passed, isTrue);
      expect(units[1].unlocked, isTrue);
      expect(units[2].unlocked, isFalse);
    });
  });

  group('hatalı kelime bildirimi', () {
    test('bildirim kaydedilir ve kalıcı olur', () {
      final c = container();
      final word = repository.allWords.first;

      c.read(reportProvider.notifier).add(
            WordReport(
              wordId: word.id,
              russian: word.russian,
              turkish: word.turkish,
              reason: ReportReason.translation,
              note: 'doğrusu şu',
              createdAt: DateTime(2026, 8, 15),
            ),
          );

      expect(c.read(reportProvider), hasLength(1));
      expect(c.read(reportProvider.notifier).isReported(word.id), isTrue);
      expect(prefs.getString('word_reports'), contains('doğrusu şu'));
    });

    test('aynı kelime için tek bildirim tutulur', () {
      final c = container();
      final notifier = c.read(reportProvider.notifier);
      for (final reason in [ReportReason.translation, ReportReason.example]) {
        notifier.add(
          WordReport(
            wordId: 'w001',
            russian: 'дом',
            turkish: 'ev',
            reason: reason,
            note: '',
            createdAt: DateTime(2026, 8, 15),
          ),
        );
      }

      expect(c.read(reportProvider), hasLength(1));
      expect(c.read(reportProvider).first.reason, ReportReason.example);
    });
  });

  group('icerik erisimi', () {
    // Premium kaldirildi: butun seviyeler ve temalar herkese acik. Bunu test
    // altina aliyoruz ki ileride yanlislikla yeniden kilitlenmesin.
    test('her seviyenin kelimeleri ve ilk bolumu acik', () {
      final c = container();
      for (final id in ['level_a1', 'level_a2', 'level_b1', 'level_b2',
                        'level_c1']) {
        expect(c.read(deckWordsProvider(id)), isNotEmpty, reason: id);
        expect(c.read(deckUnitsProvider(id)).first.unlocked, isTrue,
            reason: id);
      }
    });

    test('butun temalar acik', () {
      final c = container();
      final temalar = c.read(themeDecksProvider);
      expect(temalar, isNotEmpty);
      for (final deck in temalar) {
        expect(c.read(deckUnitsProvider(deck.id)).first.unlocked, isTrue,
            reason: deck.id);
      }
    });
  });

  group('yazma testleri', () {
    test('ilk test acik, sonrakiler sirali acilir', () {
      final c = container();
      final testler = c.read(writingTestsProvider(WritingDirection.trToRu));
      expect(testler, hasLength(kWritingTestCount));
      expect(testler.first.unlocked, isTrue);
      expect(testler[1].unlocked, isFalse);

      c.read(passedUnitsProvider.notifier).markPassed(testler.first.id);
      final sonra = c.read(writingTestsProvider(WritingDirection.trToRu));
      expect(sonra.first.passed, isTrue);
      expect(sonra[1].unlocked, isTrue);
      expect(sonra[2].unlocked, isFalse);
    });

    test('soru sayisi bes ya da on', () {
      final c = container();
      for (final t in c.read(writingTestsProvider(WritingDirection.trToRu))) {
        expect(t.words, hasLength(writingTestSize(t.index)));
        expect(writingTestSize(t.index), anyOf(5, 10));
      }
    });

    test('havuzda C1 ve cok uzun kelime yok, zorluk artiyor', () {
      final c = container();
      final testler = c.read(writingTestsProvider(WritingDirection.trToRu));
      for (final t in testler) {
        for (final w in t.words) {
          expect(w.level.name, isNot('c1'));
          expect(w.level.name, isNot('b2'));
          expect(w.russian.replaceAll(RegExp(r'[ -]'), '').length,
              inInclusiveRange(3, 10));
        }
      }
      // Siralama once seviyeye, sonra uzunluga bakiyor; ikisi de geriye
      // gitmemeli. (Sahte sozlukte kelimeler ayni uzunlukta oldugu icin
      // uzunluk kismi burada esitlikle saglaniyor.)
      const seviye = ['a1', 'a2', 'b1'];
      var oncekiSeviye = 0;
      for (final t in testler) {
        final s = seviye.indexOf(t.words.first.level.name);
        expect(s, greaterThanOrEqualTo(oncekiSeviye));
        oncekiSeviye = s;
      }
      expect(seviye.indexOf(testler.last.words.first.level.name),
          greaterThanOrEqualTo(
              seviye.indexOf(testler.first.words.first.level.name)));
    });
  });

  group('anlamı yaz (Rusça → Türkçe)', () {
    test('havuz duz Turkce karsiliklardan olusuyor', () {
      final c = container();
      final testler = c.read(writingTestsProvider(WritingDirection.ruToTr));
      expect(testler, isNotEmpty);
      for (final t in testler) {
        for (final w in t.words) {
          // Virgullu, parantezli ya da Turkce alfabede olmayan harf tasiyan
          // karsiliklar harf harf yazdirilamaz.
          expect(RegExp(r'^[a-zçğıöşü ]+$').hasMatch(w.turkish.toLowerCase()),
              isTrue, reason: w.turkish);
          expect(w.turkish.replaceAll(' ', '').length,
              inInclusiveRange(3, 10), reason: w.turkish);
        }
      }
    });

    test('iki yonun ilerlemesi ayri tutuluyor', () {
      final c = container();
      final yazma = c.read(writingTestsProvider(WritingDirection.trToRu));
      final anlam = c.read(writingTestsProvider(WritingDirection.ruToTr));
      expect(yazma.first.id, isNot(anlam.first.id));

      c.read(passedUnitsProvider.notifier).markPassed(yazma.first.id);
      expect(c.read(writingTestsProvider(WritingDirection.trToRu))[1].unlocked,
          isTrue);
      expect(c.read(writingTestsProvider(WritingDirection.ruToTr))[1].unlocked,
          isFalse);
    });
  });

  group('bölüm testi', () {
    test('testi geçmek bölümü tamamlar ve sonrakini açar', () {
      final c = container();
      for (var i = 0; i < 100; i++) {
        c.read(starredProvider.notifier).toggle('w${i.toString().padLeft(3, '0')}');
      }
      expect(c.read(deckUnitsProvider('starred'))[1].unlocked, isFalse);

      final first = c.read(deckUnitsProvider('starred')).first.unit;
      c.read(passedUnitsProvider.notifier).markPassed(first.id);

      final units = c.read(deckUnitsProvider('starred'));
      expect(units[0].testPassed, isTrue);
      expect(units[0].passed, isTrue);
      expect(units[1].unlocked, isTrue);
      expect(units[2].unlocked, isFalse);
    });
  });

  group('ayarlar', () {
    test('değişiklikler kalıcı olarak saklanır', () {
      final c = container();
      c.read(settingsProvider.notifier).update(
            (s) => s.copyWith(
              sessionSize: 30,
              direction: StudyDirection.trToRu,
              hapticsEnabled: false,
            ),
          );

      final saved = c.read(settingsProvider);
      expect(saved.sessionSize, 30);
      expect(saved.direction, StudyDirection.trToRu);
      expect(prefs.getString('app_settings'), contains('trToRu'));
    });

    test('sıfırlama varsayılanlara döner', () {
      final c = container();
      final notifier = c.read(settingsProvider.notifier);
      notifier.update((s) => s.copyWith(dailyGoal: 50));
      expect(c.read(settingsProvider).dailyGoal, 50);

      notifier.reset();
      expect(c.read(settingsProvider).dailyGoal, const AppSettings().dailyGoal);
    });
  });

  group('tanıtım ekranı', () {
    testWidgets('ilk açılışta gösterilir, atlanınca bir daha çıkmaz',
        (tester) async {
      // Varsayilan: onboardingDone = false
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(harness());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Once dil sorulur; secenekler kendi dillerinde yazili.
      expect(find.text('Türkçe'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);

      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      expect(find.text('Atla'), findsOneWidget);

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      // Uygulamaya girildi ve ayar kalici olarak isaretlendi.
      expect(find.text('Atla'), findsNothing);
      final c = container();
      expect(c.read(settingsProvider).onboardingDone, isTrue);
    });

    testWidgets('Rusça seçilince tanıtım da Rusça gelir', (tester) async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(harness());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      // Tanitim metinleri secilen dile gecti.
      expect(find.text('Пропустить'), findsOneWidget);
      expect(find.text('Atla'), findsNothing);
      final c = container();
      expect(c.read(settingsProvider).language, AppLanguage.ru);
    });
  });

  group('ekranlar', () {
    testWidgets('ana ekran seviyeleri ve yıldızlı kartı gösterir',
        (tester) async {
      await boot(tester);

      expect(find.byType(CardSwiper), findsNothing);
      expect(find.text('Yıldızlı Kelimelerim'), findsOneWidget);
      expect(find.text('Yıldızlı Kelimelerim'), findsOneWidget);
      expect(find.text('Başlangıç'), findsOneWidget);
    });

    testWidgets('temalar sekmesine geçilebiliyor', (tester) async {
      await boot(tester);

      await tester.tap(find.text('Temalar'));
      await tester.pumpAndSettle();

      expect(find.text('Ekonomi'), findsOneWidget);
    });

    testWidgets('alt menüden ayarlara geçilir ve tema değiştirilebilir',
        (tester) async {
      await boot(tester);

      // Alt menüdeki "Ayarlar" sekmesi.
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();

      expect(find.text('Çalışma yönü'), findsOneWidget);
      expect(find.text('Günlük hedef'), findsOneWidget);

      await tester.tap(find.text('Koyu'));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Görünüm'.toUpperCase()));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('deste bölüm listesini açar, bölüm kelimeleri gösterir',
        (tester) async {
      await boot(tester);

      await tester.tap(find.text('Başlangıç'));
      await tester.pumpAndSettle();

      // 20 kelimelik A1 destesi tek bölüm.
      expect(find.text('0 / 1 bölüm tamamlandı'), findsOneWidget);

      await tester.tap(find.text('Bölüm 1'));
      await tester.pumpAndSettle();

      expect(find.text('Kartlarla çalış'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      // Kelime listesi görünüyor ve yıldızlanabiliyor.
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
    });

    testWidgets('bölümden kart çalışması başlar ve kart çevrilir',
        (tester) async {
      await boot(tester);

      await tester.tap(find.text('Başlangıç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bölüm 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kartlarla çalış'));
      await tester.pumpAndSettle();

      expect(find.byType(CardSwiper), findsOneWidget);
      expect(find.text('ANLAMI'), findsNothing);

      await tester.tapAt(tester.getCenter(find.byType(CardSwiper)));
      await tester.pumpAndSettle();

      expect(find.text('ANLAMI'), findsOneWidget);
      expect(find.text('Bu kelimede hata var'), findsOneWidget);
    });

    testWidgets('bölüm listesinde yıldızlama çalışır', (tester) async {
      await boot(tester);

      await tester.tap(find.text('Başlangıç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bölüm 1'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.text('Kartlarla çalış')),
      );
      expect(container.read(starredProvider), isEmpty);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(container.read(starredProvider), hasLength(1));
    });
  });
}
