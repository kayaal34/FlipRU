import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leksika/app.dart';
import 'package:leksika/data/models/app_settings.dart';
import 'package:leksika/data/models/deck.dart';
import 'package:leksika/data/models/word.dart';
import 'package:leksika/data/models/word_report.dart';
import 'package:leksika/data/repositories/word_repository.dart';
import 'package:leksika/data/models/premium.dart';
import 'package:leksika/providers/premium_provider.dart';
import 'package:leksika/providers/report_provider.dart';
import 'package:leksika/providers/unit_providers.dart';
import 'package:leksika/providers/app_providers.dart';
import 'package:leksika/providers/daily_provider.dart';
import 'package:leksika/providers/library_providers.dart';
import 'package:leksika/providers/settings_provider.dart';

/// Testler asset'e bağlı kalmasın diye sentetik bir havuz kuruyoruz.
Word _word(int i, WordLevel level, WordTheme? theme) => Word(
      id: 'w${i.toString().padLeft(3, '0')}',
      russian: 'слово$i',
      accented: 'сло́во$i',
      transliteration: 'SLO-va$i',
      turkish: 'kelime$i',
      exampleRu: 'Это слово$i.',
      exampleTr: 'Bu kelime$i.',
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
    SharedPreferences.setMockInitialValues({});
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
  Future<void> boot(WidgetTester tester) async {
    await tester.pumpWidget(harness());
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

    test('arama rusça ve türkçe tarafta çalışır', () {
      expect(repository.search('слово3'), isNotEmpty);
      expect(repository.search('kelime7'), isNotEmpty);
      expect(repository.search('zzzz'), isEmpty);
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

  group('premium', () {
    test('varsayılan olarak premium yok ve üst seviyeler kilitli', () {
      final c = container();
      expect(c.read(isPremiumProvider), isFalse);
      expect(c.read(deckLockedProvider('level_a1')), isFalse);
      expect(c.read(deckLockedProvider('level_a2')), isFalse);
      expect(c.read(deckLockedProvider('level_b1')), isTrue);
      expect(c.read(deckLockedProvider('level_c1')), isTrue);
    });

    test('premium etkinleşince tüm desteler açılır', () {
      final c = container();
      c.read(premiumProvider.notifier).activate(PremiumPlan.monthly);

      expect(c.read(isPremiumProvider), isTrue);
      expect(c.read(deckLockedProvider('level_c1')), isFalse);
    });

    test('abonelik süresi biterse premium düşer', () {
      final c = container();
      c.read(premiumProvider.notifier).activate(PremiumPlan.yearly);
      expect(c.read(premiumProvider).remainingDays, greaterThan(300));

      c.read(premiumProvider.notifier).deactivate();
      expect(c.read(isPremiumProvider), isFalse);
    });

    test('yıldızlı kelimeleri toplu çalışmak premium gerektirir', () {
      final c = container();
      expect(c.read(deckLockedProvider('starred')), isTrue);

      c.read(premiumProvider.notifier).activate(PremiumPlan.monthly);
      expect(c.read(deckLockedProvider('starred')), isFalse);
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
