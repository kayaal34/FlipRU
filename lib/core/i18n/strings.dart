import 'package:flutter/foundation.dart';

import '../../data/models/word.dart';

/// Arayüz dili.
enum AppLanguage {
  tr('Türkçe'),
  ru('Русский');

  const AppLanguage(this.label);

  final String label;

  static AppLanguage byKey(String? key) {
    for (final language in values) {
      if (language.name == key) return language;
    }
    return tr;
  }
}

/// Uygulamanın bütün arayüz metinleri.
///
/// Kelime verisi doğası gereği Rusça-Türkçe kalıyor; burada değişen yalnızca
/// arayüz. Tek bir sınıfta tutmak, bir dilde eksik metin kalmasını imkânsız
/// kılıyor: yeni alan eklendiğinde iki dil de derleyici tarafından zorunlu.
@immutable
class Strings {
  const Strings({
    required this.tabHome,
    required this.tabTests,
    required this.tabStats,
    required this.tabSettings,
    required this.greetingNight,
    required this.greetingMorning,
    required this.greetingDay,
    required this.greetingEvening,
    required this.streakDays,
    required this.streakNone,
    required this.todayProgress,
    required this.goalDone,
    required this.comeBackTomorrow,
    required this.learnedWords,
    required this.starredTitle,
    required this.starredEmptyHint,
    required this.starredWaiting,
    required this.levels,
    required this.themes,
    required this.deckEmpty,
    required this.wordsOf,
    required this.allDone,
    required this.unitsDone,
    required this.unit,
    required this.locked,
    required this.unitLockedHint,
    required this.unitProgress,
    required this.studyWithCards,
    required this.test,
    required this.listen,
    required this.pronunciation,
    required this.starAdd,
    required this.starRemove,
    required this.reportWord,
    required this.meaning,
    required this.example,
    required this.status,
    required this.learnedYes,
    required this.learnedNo,
    required this.starredYes,
    required this.starredNo,
    required this.markLearned,
    required this.markReview,
    required this.tapForMeaning,
    required this.tapForRussian,
    required this.swipeLegend,
    required this.badgeLearned,
    required this.badgeReview,
    required this.undo,
    required this.flip,
    required this.wordsCounter,
    required this.sessionLearned,
    required this.sessionReview,
    required this.percentLearned,
    required this.sessionSummary,
    required this.studyReviewWords,
    required this.backHome,
    required this.resultGreat,
    required this.resultGood,
    required this.resultHalf,
    required this.resultPoor,
    required this.quizQuestion,
    required this.quizProgress,
    required this.quizCorrect,
    required this.writingTest,
    required this.writingTestSub,
    required this.writingPrompt,
    required this.writingOpenKeyboard,
    required this.joker,
    required this.learnedMixedSub,
    required this.learnedListSub,
    required this.searchLearned,
    required this.searchNoResult,
    required this.learnedEmpty,
    required this.nextQuestion,
    required this.seeResult,
    required this.finish,
    required this.unitUnlocked,
    required this.correctOf,
    required this.quizNotEnough,
    required this.testsTitle,
    required this.testsSubtitle,
    required this.dailyTest,
    required this.dailyTestSub,
    required this.myLearned,
    required this.myStarred,
    required this.fromWords,
    required this.needFourLearned,
    required this.starredTestSub,
    required this.unitTestsTitle,
    required this.levelTests,
    required this.levelTestNeed,
    required this.levelTestKnown,
    required this.statsTitle,
    required this.statLearned,
    required this.statStreak,
    required this.statWeek,
    required this.statMonth,
    required this.last7,
    required this.last30,
    required this.allTime,
    required this.statsNoData,
    required this.bestDay,
    required this.activeDays,
    required this.dailyAverage,
    required this.goalHitDays,
    required this.quizSection,
    required this.quizCount,
    required this.quizAccuracy,
    required this.quizBest,
    required this.quizLast,
    required this.quizNone,
    required this.weekdays,
    required this.settingsTitle,
    required this.appearance,
    required this.theme,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.language,
    required this.study,
    required this.direction,
    required this.dirRuTr,
    required this.dirTrRu,
    required this.dirRuTrDesc,
    required this.dirTrRuDesc,
    required this.sessionSize,
    required this.sessionSizeSub,
    required this.allCards,
    required this.cards,
    required this.dailyGoal,
    required this.dailyGoalSub,
    required this.shuffle,
    required this.shuffleSub,
    required this.skipLearned,
    required this.skipLearnedSub,
    required this.stressMarks,
    required this.stressMarksSub,
    required this.translitTitle,
    required this.translitSub,
    required this.reminder,
    required this.dailyReminder,
    required this.dailyReminderSub,
    required this.reminderTime,
    required this.reminderFooter,
    required this.soundVibration,
    required this.autoSpeak,
    required this.autoSpeakSub,
    required this.speechRate,
    required this.rateSlow,
    required this.rateNormal,
    required this.rateFast,
    required this.haptics,
    required this.hapticsSub,
    required this.soundFooter,
    required this.myData,
    required this.accountAndData,
    required this.reports,
    required this.account,
    required this.accountSub,
    required this.about,
    required this.appSubtitle,
    required this.version,
    required this.privacy,
    required this.terms,
    required this.aboutFooter,
    required this.onboardSkip,
    required this.onboardNext,
    required this.onboardStart,
    required this.onboardTitle1,
    required this.onboardBody1,
    required this.onboardTitle2,
    required this.onboardBody2,
    required this.onboardTitleWidget,
    required this.onboardBodyWidget,
    required this.onboardTitle3,
    required this.onboardBody3,
    required this.deleteOps,
    required this.deleteOpsFooter,
    required this.clearStars,
    required this.clearStarsSub,
    required this.resetProgress,
    required this.resetProgressSub,
    required this.resetSettings,
    required this.resetSettingsSub,
    required this.deleteAll,
    required this.deleteAllSub,
    required this.irreversible,
    required this.cancel,
    required this.confirmDelete,
    required this.uninstallNote,
    required this.reportTitle,
    required this.reportSubmit,
    required this.reportNote,
    required this.reportSaved,
    required this.reportReasonTranslation,
    required this.reportReasonExample,
    required this.reportReasonPronunciation,
    required this.reportReasonOther,
    required this.reportsTitle,
    required this.reportsEmpty,
    required this.reportsEmptyBody,
    required this.reportsSend,
    required this.reportsClear,
    required this.reportRemove,
    required this.starredScreenEmpty,
    required this.starredScreenEmptyBody,
    required this.studyAll,
    required this.splashTagline,
    required this.retryWrong,
    required this.quizWrong,
    required this.perfectScore,
    required this.encourageStart,
    required this.encourageGoing,
    required this.encourageAlmost,
    required this.notificationTitle,
    required this.notificationBody,
    required this.notifChannel,
    required this.notifChannelDesc,
    required this.levelDescriptions,
    required this.themeLabels,
    required this.posLabels,
    required this.themeSubtitle,
    required this.deckEmptyHint,
    required this.singleSourceWarning,
    required this.wordForms,
    required this.dayForms,
    required this.letterForms,
    required this.widgetSection,
    required this.widgetRefreshTitle,
    required this.widgetRefreshSub,
    required this.widgetEvery6h,
    required this.widgetEvery12h,
    required this.widgetDaily,
    required this.widgetFooter,
  });

  final String tabHome, tabTests, tabStats, tabSettings;
  final String greetingNight, greetingMorning, greetingDay, greetingEvening;
  final String streakDays, streakNone;
  final String todayProgress, goalDone, comeBackTomorrow, learnedWords;
  final String starredTitle, starredEmptyHint, starredWaiting;
  final String levels, themes, deckEmpty;
  final String wordsOf, allDone, unitsDone, unit, locked, unitLockedHint;
  final String unitProgress, studyWithCards, test, listen, pronunciation;
  final String starAdd, starRemove, reportWord;
  final String meaning, example, status;
  final String learnedYes, learnedNo, starredYes, starredNo;
  final String markLearned, markReview;
  final String tapForMeaning, tapForRussian, swipeLegend;
  final String badgeLearned, badgeReview, undo, flip;
  final String wordsCounter, sessionLearned, sessionReview, percentLearned;
  final String sessionSummary, studyReviewWords, backHome;
  final String resultGreat, resultGood, resultHalf, resultPoor;
  final String quizQuestion, quizProgress, quizCorrect, joker;
  final String writingTest, writingTestSub, writingPrompt;
  final String writingOpenKeyboard;
  final String learnedMixedSub, learnedListSub;
  final String searchLearned, searchNoResult, learnedEmpty;
  final String nextQuestion, seeResult, finish, unitUnlocked, correctOf;
  final String quizNotEnough;
  final String testsTitle, testsSubtitle, dailyTest, dailyTestSub;
  final String myLearned, myStarred, fromWords;
  final String needFourLearned, starredTestSub;
  final String unitTestsTitle;
  final String levelTests, levelTestNeed, levelTestKnown;
  final String statsTitle, statLearned, statStreak, statWeek, statMonth;
  final String last7, last30, bestDay, activeDays, dailyAverage;
  final String goalHitDays;
  final String allTime, statsNoData;
  final String quizSection, quizCount, quizAccuracy, quizBest, quizLast;
  final String quizNone;

  /// Pazartesiden pazara, grafik ekseninde kullanılıyor.
  final List<String> weekdays;
  final String settingsTitle, appearance, theme;
  final String themeSystem, themeLight, themeDark, language;
  final String study, direction, dirRuTr, dirTrRu;
  final String dirRuTrDesc, dirTrRuDesc;
  final String sessionSize, sessionSizeSub, allCards, cards;
  final String dailyGoal, dailyGoalSub, shuffle, shuffleSub;
  final String skipLearned, skipLearnedSub;
  final String stressMarks, stressMarksSub, translitTitle, translitSub;
  final String reminder, dailyReminder, dailyReminderSub;
  final String reminderTime, reminderFooter;
  final String soundVibration, autoSpeak, autoSpeakSub, speechRate;
  final String rateSlow, rateNormal, rateFast, haptics, hapticsSub;
  final String soundFooter;
  final String myData, accountAndData, reports, account, accountSub;
  final String about, appSubtitle, version, privacy, terms, aboutFooter;
  final String onboardSkip, onboardNext, onboardStart;
  final String onboardTitle1, onboardBody1;
  final String onboardTitle2, onboardBody2;
  final String onboardTitleWidget, onboardBodyWidget;
  final String onboardTitle3, onboardBody3;
  final String deleteOps, deleteOpsFooter;
  final String clearStars, clearStarsSub, resetProgress, resetProgressSub;
  final String resetSettings, resetSettingsSub, deleteAll, deleteAllSub;
  final String irreversible, cancel, confirmDelete, uninstallNote;
  final String reportTitle, reportSubmit, reportNote, reportSaved;
  final String reportReasonTranslation, reportReasonExample;
  final String reportReasonPronunciation, reportReasonOther;
  final String reportsTitle, reportsEmpty, reportsEmptyBody;
  final String reportsSend, reportsClear, reportRemove;
  final String starredScreenEmpty, starredScreenEmptyBody, studyAll;
  final String splashTagline, notificationTitle, notificationBody;
  final String retryWrong, quizWrong, perfectScore;
  final String encourageStart, encourageGoing, encourageAlmost;
  final String notifChannel, notifChannelDesc;
  final String widgetSection, widgetRefreshTitle, widgetRefreshSub;
  final String widgetEvery6h, widgetEvery12h, widgetDaily, widgetFooter;
  final String deckEmptyHint, singleSourceWarning;

  /// Tema destesinin alt basligi; `{}` yerine tema adi gelir.
  final String themeSubtitle;

  /// Enum adlarina gore etiketler. Sirali listeler yerine map kullaniyoruz
  /// ki enum'a yeni deger eklendiginde diger diller sessizce kaymasin.
  final Map<String, String> levelDescriptions, themeLabels, posLabels;

  /// Sayi uyumu icin [tekil, azlik, coguk] bicimleri.
  ///
  /// Rusca'da sayidan sonraki isim ucе ayrilir: 1 слово, 2 слова, 5 слов.
  /// Turkce'de üçü de ayni, ama alan yine uc elemanli — boylece cagri yeri
  /// dilden bagimsiz kaliyor.
  final List<String> wordForms, dayForms, letterForms;

  /// Rusca sayi uyumu kurali.
  static String _agree(List<String> forms, int count) {
    final n = count.abs();
    if (n % 100 >= 11 && n % 100 <= 14) return forms[2];
    if (n % 10 == 1) return forms[0];
    if (n % 10 >= 2 && n % 10 <= 4) return forms[1];
    return forms[2];
  }

  /// "5 слов" / "5 kelime"
  String words(int count) => '$count ${_agree(wordForms, count)}';

  /// "5 дней" / "5 gün"
  String days(int count) => '$count ${_agree(dayForms, count)}';

  /// "7 harf" / "7 букв"
  String letters(int count) => '$count ${_agree(letterForms, count)}';

  /// Sayiyi kendin yazdiginda ("3 / 20 слов") yalnizca ismin dogru bicimi.
  String wordUnit(int count) => _agree(wordForms, count);

  static Strings of(AppLanguage language) =>
      language == AppLanguage.ru ? _ru : _tr;

  // ───────────────────────────── Türkçe ─────────────────────────────
  static const _tr = Strings(
    tabHome: 'Ana ekran',
    tabTests: 'Pratik',
    tabStats: 'İstatistik',
    tabSettings: 'Ayarlar',
    greetingNight: 'İyi geceler',
    greetingMorning: 'Günaydın',
    greetingDay: 'İyi günler',
    greetingEvening: 'İyi akşamlar',
    streakDays: 'günlük seri',
    streakNone: 'seri yok',
    todayProgress: 'Bugün',
    goalDone: 'Günlük hedefin tamam!',
    comeBackTomorrow: 'Yarın tekrar gel — seriyi bozma.',
    learnedWords: 'öğrendin',
    starredTitle: 'Yıldızlı Kelimelerim',
    starredEmptyHint: 'Zorlandığın kelimeleri buraya kaydet',
    starredWaiting: 'seni bekliyor',
    levels: 'Seviyeler',
    themes: 'Temalar',
    deckEmpty: 'Bu destede henüz kelime yok.',
    wordsOf: 'kelime',
    allDone: 'kelimenin tamamı tamam',
    unitsDone: 'bölüm tamamlandı',
    unit: 'Bölüm',
    locked: 'Kilitli',
    unitLockedHint: 'Bu bölüm kilitli. Önceki bölümü tamamlayınca açılır.',
    unitProgress: 'kelime öğrenildi · geçmek için',
    studyWithCards: 'Kartlarla çalış',
    test: 'Test',
    listen: 'Dinle',
    pronunciation: 'Telaffuz',
    starAdd: 'Yıldızla',
    starRemove: 'Yıldızı kaldır',
    reportWord: 'Bu kelimede hata var',
    meaning: 'ANLAMI',
    example: 'ÖRNEK CÜMLE',
    status: 'DURUM',
    learnedYes: 'Öğrendin',
    learnedNo: 'Henüz öğrenmedin',
    starredYes: 'Yıldızlı',
    starredNo: 'Yıldızlanmadı',
    markLearned: 'Öğrendim',
    markReview: 'Tekrara al',
    tapForMeaning: 'Anlamı için karta dokun',
    tapForRussian: 'Rusçası için karta dokun',
    swipeLegend: 'Sağa: öğrendim · Sola: tekrar et',
    badgeLearned: 'ÖĞRENDİM',
    badgeReview: 'TEKRAR',
    undo: 'Son kartı geri al',
    flip: 'Kartı çevir',
    wordsCounter: 'kelime',
    sessionLearned: 'Öğrendim',
    sessionReview: 'Tekrar edilecek',
    percentLearned: 'öğrenildi',
    sessionSummary: 'kelime çalıştın',
    studyReviewWords: 'Tekrar edilecekleri çalış',
    backHome: 'Ana ekrana dön',
    resultGreat: 'Отлично! Neredeyse kusursuz.',
    resultGood: 'Молодец! İyi gidiyorsun.',
    resultHalf: 'Fena değil, tekrar sırası.',
    resultPoor: 'Bu deste biraz zorladı.',
    quizQuestion: 'Bu kelimenin anlamı ne?',
    quizProgress: 'Soru',
    quizCorrect: 'doğru',
    writingTest: 'Kelimeyi yaz',
    writingTestSub: 'Türkçesini gör, Rusçasını harf harf yaz',
    writingPrompt: 'Bu kelimenin Rusçası',
    writingOpenKeyboard: 'Klavyeyi aç',
    joker: 'Joker',
    learnedMixedSub: 'Öğrendiğin kelimelerden karışık tekrar',
    learnedListSub: 'Öğrendiğin kelimelerin listesi',
    searchLearned: 'Öğrendiğin kelimelerde ara',
    searchNoResult: 'Eşleşen kelime yok',
    learnedEmpty: 'Henüz kelime öğrenmedin. Bir bölüm çalış, '
        'öğrendiklerin burada birikir.',
    nextQuestion: 'Sonraki soru',
    seeResult: 'Sonucu gör',
    finish: 'Bitir',
    unitUnlocked: 'Bu bölümü geçtin — sonraki bölüm açıldı.',
    correctOf: 'doğru',
    quizNotEnough: 'Test için yeterli kelime yok. Önce birkaç kelime öğren.',
    testsTitle: 'Pratik',
    testsSubtitle: 'Bildiklerini ölç, yazarak pekiştir',
    dailyTest: 'Günün testi',
    dailyTestSub: 'Öğrendiklerinden 15 rastgele soru',
    myLearned: 'Öğrendiğim Kelimeler',
    myStarred: 'Yıldızlı kelimelerim',
    fromWords: 'öğrenildi',
    needFourLearned: 'En az 20 kelime öğrenince açılır',
    starredTestSub: 'Yıldızladığın kelimelerle test',
    unitTestsTitle: 'BÖLÜM TESTLERİ',
    levelTests: 'SEVİYE TESTLERİ',
    levelTestNeed: 'Bu seviyeden en az 20 kelime öğren',
    levelTestKnown: 'öğrenilmiş kelime',
    statsTitle: 'İstatistikler',
    statLearned: 'Öğrenilen kelime',
    statStreak: 'Günlük seri',
    statWeek: 'Son 7 gün',
    statMonth: 'Son 30 gün',
    last7: '7 gün',
    last30: '30 gün',
    allTime: 'Tüm zamanlar',
    statsNoData: 'Henüz kayıtlı gün yok',
    bestDay: 'En verimli gün',
    activeDays: 'Çalışılan gün sayısı',
    dailyAverage: 'Günlük ortalama',
    goalHitDays: 'Hedefe ulaşılan gün',
    quizSection: 'TESTLER',
    quizCount: 'Çözülen test',
    quizAccuracy: 'Doğruluk oranı',
    quizBest: 'En iyi sonuç',
    quizLast: 'Son test',
    quizNone: 'Henüz test çözmedin',
    weekdays: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
    settingsTitle: 'Ayarlar',
    appearance: 'Görünüm',
    theme: 'Tema',
    themeSystem: 'Sistem',
    themeLight: 'Açık',
    themeDark: 'Koyu',
    language: 'Uygulama dili',
    study: 'Çalışma',
    direction: 'Çalışma yönü',
    dirRuTr: 'Rusça → Türkçe',
    dirTrRu: 'Türkçe → Rusça',
    dirRuTrDesc: 'Rusça kelimeyi görüp anlamını hatırla',
    dirTrRuDesc: 'Türkçe anlamı görüp Rusçasını hatırla',
    sessionSize: 'Seans uzunluğu',
    sessionSizeSub: 'Bir oturumda kaç kart gelsin',
    allCards: 'Tümü',
    cards: 'kart',
    dailyGoal: 'Günlük hedef',
    dailyGoalSub: 'Ana ekranda ilerlemen buna göre ölçülür',
    shuffle: 'Kartları karıştır',
    shuffleSub: 'Kapalıysa kelimeler sıklık sırasına göre gelir',
    skipLearned: 'Öğrenilenleri atla',
    skipLearnedSub: 'Yeni seanslarda yalnızca bilmediklerin gelsin',
    stressMarks: 'Vurgu işaretleri',
    stressMarksSub: 'возмо́жность — hangi hecenin vurgulu olduğunu gösterir',
    translitTitle: 'Türkçe okunuş',
    translitSub: "vaz-MOJ-nast' — kartın altında görünür",
    reminder: 'Hatırlatma',
    dailyReminder: 'Günlük hatırlatma',
    dailyReminderSub: 'Setini tamamlamadıysan hatırlatalım',
    reminderTime: 'Hatırlatma saati',
    reminderFooter: 'Bildirim yalnızca o gün hedefini tamamlamadıysan gelir.',
    soundVibration: 'Ses ve titreşim',
    autoSpeak: 'Otomatik telaffuz',
    autoSpeakSub: 'Yeni kart geldiğinde Rusçasını sesli oku',
    speechRate: 'Konuşma hızı',
    rateSlow: 'Yavaş',
    rateNormal: 'Normal',
    rateFast: 'Hızlı',
    haptics: 'Dokunsal geri bildirim',
    hapticsSub: 'Kart çevirme ve kaydırmada hafif titreşim',
    soundFooter: 'Telaffuz cihazının Rusça ses paketini kullanır.',
    myData: 'Verilerim',
    accountAndData: 'Hesap ve veri',
    reports: 'Hatalı kelime bildirimleri',
    account: 'Hesap',
    accountSub: 'Verilerim, sıfırlama ve silme işlemleri',
    about: 'Hakkında',
    appSubtitle: 'Rusça kelime öğrenme uygulaması',
    version: 'Sürüm 1.0.0',
    privacy: 'Gizlilik Politikası',
    terms: 'Hizmet Kullanım Şartları',
    aboutFooter: 'Sözlük verisi Vikisözlük (WikDict) ve Badestrand Rusça '
        'sözlüğünden; örnek cümleler Tatoeba, TED2020, WikiMatrix ve '
        'OpenSubtitles derlemlerinden derlenmiştir.',
    onboardSkip: 'Atla',
    onboardNext: 'Devam',
    onboardStart: 'Başlayalım',
    onboardTitle1: 'Rusça öğrenmeye başla',
    onboardBody1: '8.000 kelimeden fazlası, okunuşu ve örnek cümlesiyle. '
        'Başlangıçtan ileri seviyeye, adım adım.',
    onboardTitle2: 'Kartı çevir, kaydır',
    onboardBody2: 'Karta dokun, anlamı görün. Bildiğin kelimeyi sağa kaydır, '
        'tekrar etmen gerekeni sola. Her bölüm 20 kelime.',
    onboardTitleWidget: 'Widget’ı ana ekranına ekle',
    onboardBodyWidget: 'Her gün yeni bir kelime ve günlük serin, uygulamayı '
        'açmadan telefonunun ana ekranında. Ana ekranına uzun bas, widget '
        'listesinden FlipRU’yu seç.',
    onboardTitle3: 'Günlük hedefin ne olsun?',
    onboardBody3: 'Her gün bu kadar yeni kelime. Sonradan ayarlardan '
        'değiştirebilirsin.',
    deleteOps: 'Silme işlemleri',
    deleteOpsFooter: 'Buradaki işlemlerin hiçbiri geri alınamaz.',
    clearStars: 'Yıldızları temizle',
    clearStarsSub: 'Kaydettiğin kelimeler listeden çıkar',
    resetProgress: 'İlerlemeyi sıfırla',
    resetProgressSub: 'Öğrenilenler, bölümler, seri ve istatistikler',
    resetSettings: 'Ayarları varsayılana döndür',
    resetSettingsSub: 'Tercihler sıfırlanır, kelime verisi kalır',
    deleteAll: 'Her şeyi sil',
    deleteAllSub: 'İlerleme, yıldızlar, ayarlar ve bildirimler',
    irreversible: 'Bu işlem geri alınamaz.',
    cancel: 'Vazgeç',
    confirmDelete: 'Sil',
    uninstallNote: 'Uygulamayı telefondan kaldırmak da bütün veriyi siler.',
    reportTitle: 'Neyi bildirmek istiyorsun?',
    reportSubmit: 'Bildir',
    reportNote: 'İstersen doğrusunu yaz (isteğe bağlı)',
    reportSaved: 'Bildirimin kaydedildi. Ayarlar › Hesap ve veri bölümünden '
        'bize gönderebilirsin.',
    reportReasonTranslation: 'Çeviri yanlış',
    reportReasonExample: 'Örnek cümle saçma',
    reportReasonPronunciation: 'Okunuş / vurgu yanlış',
    reportReasonOther: 'Başka bir sorun',
    reportsTitle: 'Hatalı kelimeler',
    reportsEmpty: 'Henüz bildirim yok',
    reportsEmptyBody: 'Çeviri ya da örnek cümle sana yanlış geldiyse kartın '
        'altındaki bağlantıya dokun.',
    reportsSend: 'Bize gönder',
    reportsClear: 'Tümünü sil',
    reportRemove: 'Bildirimi kaldır',
    starredScreenEmpty: 'Henüz yıldızlı kelime yok',
    starredScreenEmptyBody: 'Çalışırken zorlandığın kelimenin yıldızına dokun; '
        'hepsi burada toplansın.',
    studyAll: 'Hepsini çalış',
    splashTagline: '8.000+ kelime, örnek cümlelerle',
    retryWrong: 'Yanlışlarına dön',
    quizWrong: 'yanlış',
    perfectScore: 'Kusursuz! Hepsi doğru.',
    encourageStart: 'Bugüne başlamadın, hadi bir kelime!',
    encourageGoing: 'İyi gidiyorsun, devam et',
    encourageAlmost: 'Harika gidiyorsun, az kaldı!',
    notificationTitle: 'Bugünkü çalışman seni bekliyor',
    notificationBody: '{} kelimelik günlük setini henüz tamamlamadın.',
    wordForms: ['kelime', 'kelime', 'kelime'],
    dayForms: ['gün', 'gün', 'gün'],
    letterForms: ['harf', 'harf', 'harf'],
    widgetSection: 'Ana ekran widget’ı',
    widgetRefreshTitle: 'Kelime yenileme',
    widgetRefreshSub: 'Widget’taki kelime kaç saatte bir değişsin',
    widgetEvery6h: '6 saatte bir',
    widgetEvery12h: '12 saatte bir',
    widgetDaily: 'Günde bir',
    widgetFooter: 'Widget’ı ana ekranına eklersen her gün yeni bir kelimeyi '
        've günlük serini uygulamayı açmadan görürsün. Eklemek için ana '
        'ekranına uzun bas, widget listesinden FlipRU’yu seç. Widget '
        'yalnızca uygulamayı açtığında tazelenir.',
    notifChannel: 'Günlük hatırlatma',
    notifChannelDesc: 'Çalışma setini tamamlamadığında hatırlatır',
    deckEmptyHint: 'Kartların üzerindeki yıldıza dokunarak kelime ekleyebilirsin.',
    singleSourceWarning: 'Bu çeviri tek kaynaktan; hatalı olabilir',
    themeSubtitle: '{} terimleri',
    levelDescriptions: {
      'a1': 'Başlangıç',
      'a2': 'Temel',
      'b1': 'Orta',
      'b2': 'Orta-Üstü',
      'c1': 'İleri',
    },
    posLabels: {
      'noun': 'isim',
      'verb': 'fiil',
      'adjective': 'sıfat',
      'other': 'edat/zamir',
    },
    themeLabels: {
      'politics': 'Siyaset',
      'economy': 'Ekonomi',
      'health': 'Sağlık',
      'science': 'Bilim',
      'environment': 'Çevre',
      'education': 'Eğitim',
      'technology': 'Teknoloji',
      'work': 'İş & Kariyer',
      'law': 'Hukuk',
      'transport': 'Ulaşım',
      'food': 'Yeme & İçme',
      'family': 'Aile',
      'emotion': 'Duygular',
      'body': 'Vücut',
      'home': 'Ev & Yaşam',
      'time': 'Zaman',
      'culture': 'Sanat & Kültür',
      'sport': 'Spor',
      'military': 'Askeriye',
      'religion': 'Din & İnanç',
      'geography': 'Coğrafya',
      'agriculture': 'Tarım',
      'construction': 'İnşaat',
      'clothing': 'Giyim',
      'shopping': 'Alışveriş',
      'media': 'Medya',
      'animals': 'Hayvanlar',
      'travel': 'Seyahat',
      'personality': 'Kişilik',
      'quantity': 'Ölçü & Miktar',
    },
  );

  // ───────────────────────────── Русский ────────────────────────────
  static const _ru = Strings(
    tabHome: 'Главная',
    tabTests: 'Практика',
    tabStats: 'Статистика',
    tabSettings: 'Настройки',
    greetingNight: 'Доброй ночи',
    greetingMorning: 'Доброе утро',
    greetingDay: 'Добрый день',
    greetingEvening: 'Добрый вечер',
    streakDays: 'дней подряд',
    streakNone: 'нет серии',
    todayProgress: 'Сегодня',
    goalDone: 'Дневная цель выполнена!',
    comeBackTomorrow: 'Возвращайся завтра — не прерывай серию.',
    learnedWords: 'выучено',
    starredTitle: 'Избранные слова',
    starredEmptyHint: 'Сохраняй сюда трудные слова',
    starredWaiting: 'в избранном',
    levels: 'Уровни',
    themes: 'Темы',
    deckEmpty: 'В этой колоде пока нет слов.',
    wordsOf: 'слов',
    allDone: 'все слова выучены',
    unitsDone: 'разделов пройдено',
    unit: 'Раздел',
    locked: 'Закрыто',
    unitLockedHint: 'Раздел закрыт. Он откроется после предыдущего.',
    unitProgress: 'слов выучено · для прохождения нужно',
    studyWithCards: 'Учить карточками',
    test: 'Тест',
    listen: 'Слушать',
    pronunciation: 'Произношение',
    starAdd: 'В избранное',
    starRemove: 'Убрать из избранного',
    reportWord: 'В этом слове ошибка',
    meaning: 'ЗНАЧЕНИЕ',
    example: 'ПРИМЕР',
    status: 'СТАТУС',
    learnedYes: 'Выучено',
    learnedNo: 'Ещё не выучено',
    starredYes: 'В избранном',
    starredNo: 'Не в избранном',
    markLearned: 'Выучил',
    markReview: 'На повтор',
    tapForMeaning: 'Нажми на карточку, чтобы увидеть значение',
    tapForRussian: 'Нажми, чтобы увидеть слово по-русски',
    swipeLegend: 'Вправо — выучил · Влево — повторить',
    badgeLearned: 'ВЫУЧИЛ',
    badgeReview: 'ПОВТОР',
    undo: 'Вернуть карточку',
    flip: 'Перевернуть',
    wordsCounter: 'слов',
    sessionLearned: 'Выучено',
    sessionReview: 'На повтор',
    percentLearned: 'выучено',
    sessionSummary: 'слов пройдено',
    studyReviewWords: 'Повторить сложные',
    backHome: 'На главную',
    resultGreat: 'Отлично! Почти безупречно.',
    resultGood: 'Молодец! Дела идут хорошо.',
    resultHalf: 'Неплохо, но стоит повторить.',
    resultPoor: 'Эта колода оказалась сложной.',
    quizQuestion: 'Что означает это слово?',
    quizProgress: 'Вопрос',
    quizCorrect: 'верно',
    writingTest: 'Напиши слово',
    writingTestSub: 'Видишь перевод — пишешь слово по буквам',
    writingPrompt: 'Как это будет по-русски',
    writingOpenKeyboard: 'Открыть клавиатуру',
    joker: 'Джокер',
    learnedMixedSub: 'Повторение выученных слов вперемешку',
    learnedListSub: 'Список выученных слов',
    searchLearned: 'Поиск среди выученных',
    searchNoResult: 'Ничего не найдено',
    learnedEmpty: 'Ты ещё не выучил слов. Позанимайся разделом — '
        'выученное соберётся здесь.',
    nextQuestion: 'Следующий вопрос',
    seeResult: 'Посмотреть результат',
    finish: 'Завершить',
    unitUnlocked: 'Раздел пройден — следующий открыт.',
    correctOf: 'верно',
    quizNotEnough: 'Слов недостаточно. Сначала выучи несколько слов.',
    testsTitle: 'Практика',
    testsSubtitle: 'Проверяй знания и закрепляй письмом',
    dailyTest: 'Тест дня',
    dailyTestSub: '15 случайных вопросов из выученного',
    myLearned: 'Выученные слова',
    myStarred: 'Избранные слова',
    fromWords: 'выучено',
    needFourLearned: 'Откроется после 20 выученных слов',
    starredTestSub: 'Тест по избранным словам',
    unitTestsTitle: 'ТЕСТЫ ПО РАЗДЕЛАМ',
    levelTests: 'ТЕСТЫ ПО УРОВНЯМ',
    levelTestNeed: 'Выучи хотя бы 20 слов этого уровня',
    levelTestKnown: 'выученных слов',
    statsTitle: 'Статистика',
    statLearned: 'Выучено слов',
    statStreak: 'Дней подряд',
    statWeek: 'За 7 дней',
    statMonth: 'За 30 дней',
    last7: '7 дней',
    last30: '30 дней',
    allTime: 'Всё время',
    statsNoData: 'Пока нет данных',
    bestDay: 'Лучший день',
    activeDays: 'Дней занятий',
    dailyAverage: 'В среднем за день',
    goalHitDays: 'Дней с выполненной целью',
    quizSection: 'ТЕСТЫ',
    quizCount: 'Пройдено тестов',
    quizAccuracy: 'Точность',
    quizBest: 'Лучший результат',
    quizLast: 'Последний тест',
    quizNone: 'Тестов пока не было',
    weekdays: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    settingsTitle: 'Настройки',
    appearance: 'Внешний вид',
    theme: 'Тема',
    themeSystem: 'Системная',
    themeLight: 'Светлая',
    themeDark: 'Тёмная',
    language: 'Язык приложения',
    study: 'Занятия',
    direction: 'Направление',
    dirRuTr: 'Русский → Турецкий',
    dirTrRu: 'Турецкий → Русский',
    dirRuTrDesc: 'Видишь русское слово, вспоминаешь значение',
    dirTrRuDesc: 'Видишь перевод, вспоминаешь русское слово',
    sessionSize: 'Длина сессии',
    sessionSizeSub: 'Сколько карточек за один раз',
    allCards: 'Все',
    cards: 'карт.',
    dailyGoal: 'Дневная цель',
    dailyGoalSub: 'По ней измеряется прогресс на главной',
    shuffle: 'Перемешивать карточки',
    shuffleSub: 'Если выключено — слова идут по частотности',
    skipLearned: 'Пропускать выученные',
    skipLearnedSub: 'В новых сессиях только незнакомые слова',
    stressMarks: 'Знаки ударения',
    stressMarksSub: 'возмо́жность — показывает ударный слог',
    translitTitle: 'Транскрипция',
    translitSub: "vaz-MOJ-nast' — показана под словом",
    reminder: 'Напоминание',
    dailyReminder: 'Ежедневное напоминание',
    dailyReminderSub: 'Напомним, если не выполнил дневную норму',
    reminderTime: 'Время напоминания',
    reminderFooter: 'Уведомление приходит, только если цель не выполнена.',
    soundVibration: 'Звук и вибрация',
    autoSpeak: 'Автопроизношение',
    autoSpeakSub: 'Озвучивать слово при появлении карточки',
    speechRate: 'Скорость речи',
    rateSlow: 'Медленно',
    rateNormal: 'Обычно',
    rateFast: 'Быстро',
    haptics: 'Тактильный отклик',
    hapticsSub: 'Лёгкая вибрация при переворотах и свайпах',
    soundFooter: 'Произношение использует голосовой движок устройства.',
    myData: 'Мои данные',
    accountAndData: 'Аккаунт и данные',
    reports: 'Сообщения об ошибках',
    account: 'Аккаунт',
    accountSub: 'Мои данные, сброс и удаление',
    about: 'О приложении',
    appSubtitle: 'Приложение для изучения русских слов',
    version: 'Версия 1.0.0',
    privacy: 'Политика конфиденциальности',
    terms: 'Условия использования',
    aboutFooter: 'Словарные данные — из Викисловаря (WikDict) и русского '
        'словаря Badestrand; примеры — из корпусов Tatoeba, TED2020, '
        'WikiMatrix и OpenSubtitles.',
    onboardSkip: 'Пропустить',
    onboardNext: 'Далее',
    onboardStart: 'Начнём',
    onboardTitle1: 'Начни учить слова',
    onboardBody1: 'Более 8.000 слов с произношением и примерами. '
        'От начального уровня до продвинутого, шаг за шагом.',
    onboardTitle2: 'Переверни карточку, свайпни',
    onboardBody2: 'Нажми на карточку, чтобы увидеть значение. Знаешь слово — '
        'свайп вправо, нужно повторить — влево. В разделе 20 слов.',
    onboardTitleWidget: 'Добавь виджет на главный экран',
    onboardBodyWidget: 'Каждый день новое слово и твоя серия — прямо на '
        'главном экране, без запуска приложения. Долгое нажатие на главном '
        'экране, затем FlipRU в списке виджетов.',
    onboardTitle3: 'Какая у тебя дневная цель?',
    onboardBody3: 'Столько новых слов каждый день. Потом можно изменить '
        'в настройках.',
    deleteOps: 'Удаление данных',
    deleteOpsFooter: 'Ни одно из этих действий нельзя отменить.',
    clearStars: 'Очистить избранное',
    clearStarsSub: 'Сохранённые слова исчезнут из списка',
    resetProgress: 'Сбросить прогресс',
    resetProgressSub: 'Выученное, разделы, серия и статистика',
    resetSettings: 'Сбросить настройки',
    resetSettingsSub: 'Настройки сбросятся, словарь останется',
    deleteAll: 'Удалить всё',
    deleteAllSub: 'Прогресс, избранное, настройки и сообщения',
    irreversible: 'Это действие нельзя отменить.',
    cancel: 'Отмена',
    confirmDelete: 'Удалить',
    uninstallNote: 'Удаление приложения также стирает все данные.',
    reportTitle: 'О чём хочешь сообщить?',
    reportSubmit: 'Отправить',
    reportNote: 'Напиши верный вариант (необязательно)',
    reportSaved: 'Сообщение сохранено. Отправить можно в разделе '
        '«Аккаунт и данные».',
    reportReasonTranslation: 'Неверный перевод',
    reportReasonExample: 'Странный пример',
    reportReasonPronunciation: 'Ошибка в ударении',
    reportReasonOther: 'Другая проблема',
    reportsTitle: 'Ошибки в словах',
    reportsEmpty: 'Сообщений пока нет',
    reportsEmptyBody: 'Если перевод или пример кажется неверным, нажми на '
        'ссылку под карточкой.',
    reportsSend: 'Отправить нам',
    reportsClear: 'Удалить все',
    reportRemove: 'Убрать сообщение',
    starredScreenEmpty: 'Избранных слов пока нет',
    starredScreenEmptyBody: 'Нажимай на звёздочку у трудных слов — они '
        'соберутся здесь.',
    studyAll: 'Учить все',
    splashTagline: '8.000+ слов с примерами',
    retryWrong: 'Вернуться к ошибкам',
    quizWrong: 'неверно',
    perfectScore: 'Безупречно! Всё верно.',
    encourageStart: 'Сегодня ещё не начинал — вперёд!',
    encourageGoing: 'Хорошо идёшь, продолжай',
    encourageAlmost: 'Отлично идёшь, немного осталось!',
    notificationTitle: 'Твоё занятие ждёт',
    notificationBody: 'Дневная норма ({} слов) ещё не выполнена.',
    wordForms: ['слово', 'слова', 'слов'],
    letterForms: ['буква', 'буквы', 'букв'],
    dayForms: ['день', 'дня', 'дней'],
    widgetSection: 'Виджет на экране',
    widgetRefreshTitle: 'Обновление слова',
    widgetRefreshSub: 'Как часто меняется слово в виджете',
    widgetEvery6h: 'Каждые 6 часов',
    widgetEvery12h: 'Каждые 12 часов',
    widgetDaily: 'Раз в день',
    widgetFooter: 'Добавь виджет на главный экран — каждый день новое слово '
        'и твоя серия будут видны без запуска приложения. Долгое нажатие '
        'на главном экране, затем FlipRU в списке виджетов. Виджет '
        'обновляется при открытии приложения.',
    notifChannel: 'Ежедневное напоминание',
    notifChannelDesc: 'Напоминает, если занятие не завершено',
    deckEmptyHint: 'Нажми на звёздочку на карточке, чтобы добавить слово.',
    singleSourceWarning: 'Перевод из одного источника — возможна ошибка',
    themeSubtitle: 'Термины: {}',
    levelDescriptions: {
      'a1': 'Начальный',
      'a2': 'Базовый',
      'b1': 'Средний',
      'b2': 'Выше среднего',
      'c1': 'Продвинутый',
    },
    posLabels: {
      'noun': 'сущ.',
      'verb': 'глаг.',
      'adjective': 'прил.',
      'other': 'служ.',
    },
    themeLabels: {
      'politics': 'Политика',
      'economy': 'Экономика',
      'health': 'Здоровье',
      'science': 'Наука',
      'environment': 'Природа',
      'education': 'Образование',
      'technology': 'Технологии',
      'work': 'Работа и карьера',
      'law': 'Право',
      'transport': 'Транспорт',
      'food': 'Еда и напитки',
      'family': 'Семья',
      'emotion': 'Эмоции',
      'body': 'Тело',
      'home': 'Дом и быт',
      'time': 'Время',
      'culture': 'Искусство и культура',
      'sport': 'Спорт',
      'military': 'Армия',
      'religion': 'Религия',
      'geography': 'География',
      'agriculture': 'Сельское хозяйство',
      'construction': 'Строительство',
      'clothing': 'Одежда',
      'shopping': 'Покупки',
      'media': 'СМИ',
      'animals': 'Животные',
      'travel': 'Путешествия',
      'personality': 'Характер',
      'quantity': 'Мера и количество',
    },
  );
}

/// Enum etiketlerini arayuz diline cevirir.
///
/// Etiketler model katmaninda sabit yazilamiyor (iki dil var), ama her cagri
/// yerinde map'e elle bakmak da hataya acik; bu uzanti ikisinin arasini buluyor.
extension EnumLabels on Strings {
  String levelName(WordLevel level) =>
      levelDescriptions[level.name] ?? level.label;

  String themeName(WordTheme theme) => themeLabels[theme.name] ?? theme.name;

  String posName(PartOfSpeech pos) => posLabels[pos.name] ?? pos.name;

  String themeDeckSubtitle(WordTheme theme) =>
      themeSubtitle.replaceFirst('{}', themeName(theme));
}
