import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/deck.dart';
import '../data/models/word.dart';
import 'app_providers.dart';
import 'daily_provider.dart';
import 'settings_provider.dart';

/// Kullanıcının yıldızladığı kelime kimlikleri.
class StarredNotifier extends Notifier<Set<String>> {
  static const _key = 'starred_word_ids';

  @override
  Set<String> build() {
    final stored = ref.read(sharedPreferencesProvider).getStringList(_key);
    return {...?stored};
  }

  bool contains(String wordId) => state.contains(wordId);

  /// Yıldızı aç/kapa. Yeni durumu (yıldızlı mı) döndürür ki çağıran taraf
  /// doğru haptic/animasyonu tetikleyebilsin.
  bool toggle(String wordId) {
    final next = {...state};
    final added = next.add(wordId);
    if (!added) next.remove(wordId);
    state = next;
    _persist(next);
    return added;
  }

  void clear() {
    state = const {};
    _persist(const {});
  }

  void _persist(Set<String> ids) {
    ref.read(sharedPreferencesProvider).setStringList(_key, ids.toList());
  }
}

final starredProvider =
    NotifierProvider<StarredNotifier, Set<String>>(StarredNotifier.new);

/// "Öğrendim" olarak işaretlenmiş kelimeler. İlerleme yüzdeleri buradan gelir.
class LearnedNotifier extends Notifier<Set<String>> {
  static const _key = 'learned_word_ids';

  @override
  Set<String> build() {
    final stored = ref.read(sharedPreferencesProvider).getStringList(_key);
    return {...?stored};
  }

  void markLearned(String wordId) {
    if (state.contains(wordId)) return;
    state = {...state, wordId};
    _persist(state);
    // Günlük hedef sayacı yalnızca kelime *ilk kez* öğrenildiğinde artar.
    ref.read(dailyProgressProvider.notifier).record();
  }

  /// Sola kaydırma: kelime "tekrar edilecek" havuzuna döner, yani
  /// öğrenilmişler listesinden çıkar.
  void markForReview(String wordId) {
    if (!state.contains(wordId)) return;
    final next = {...state}..remove(wordId);
    state = next;
    _persist(next);
    // Karar geri alındığında günlük sayaç da geri sarılmalı.
    ref.read(dailyProgressProvider.notifier).record(delta: -1);
  }

  void resetDeck(Iterable<String> wordIds) {
    final next = {...state}..removeAll(wordIds);
    state = next;
    _persist(next);
  }

  void clear() {
    state = const {};
    _persist(const {});
  }

  void _persist(Set<String> ids) {
    ref.read(sharedPreferencesProvider).setStringList(_key, ids.toList());
  }
}

final learnedProvider =
    NotifierProvider<LearnedNotifier, Set<String>>(LearnedNotifier.new);

// ───────────────────────────── Türetilmiş veri ────────────────────────────

final levelDecksProvider = Provider<List<Deck>>(
  (ref) => ref.watch(wordRepositoryProvider).levelDecks,
);

final themeDecksProvider = Provider<List<Deck>>(
  (ref) => ref.watch(wordRepositoryProvider).themeDecks,
);

final allDecksProvider = Provider<List<Deck>>((ref) => [
      ...ref.watch(levelDecksProvider),
      ...ref.watch(themeDecksProvider),
      Deck.starred,
    ]);

final deckByIdProvider = Provider.family<Deck, String>(
  (ref, deckId) =>
      ref.watch(allDecksProvider).firstWhere((deck) => deck.id == deckId),
);

/// Bir destenin kelimeleri. Yıldızlı deste dışındakiler kullanıcı verisine
/// bağlı olmadığı için yıldız değişiminde yeniden hesaplanmaz.
final deckWordsProvider = Provider.family<List<Word>, String>((ref, deckId) {
  final deck = ref.watch(deckByIdProvider(deckId));
  final repository = ref.watch(wordRepositoryProvider);

  final words = deck.kind == DeckKind.starred
      ? repository.wordsOf(deck, starredIds: ref.watch(starredProvider))
      : repository.wordsOf(deck);

  // Ayarda istenirse yalnızca birden fazla sözlüğün doğruladığı kelimeler.
  final hideLowConfidence =
      ref.watch(settingsProvider.select((s) => s.hideLowConfidence));
  if (!hideLowConfidence) return words;
  return [
    for (final word in words)
      if (word.confidence >= 3) word,
  ];
});

@immutable
class DeckProgress {
  const DeckProgress({required this.total, required this.learned});

  final int total;
  final int learned;

  double get ratio => total == 0 ? 0 : learned / total;
  bool get isComplete => total > 0 && learned == total;
  int get remaining => total - learned;
}

final deckProgressProvider = Provider.family<DeckProgress, String>((
  ref,
  deckId,
) {
  final words = ref.watch(deckWordsProvider(deckId));
  final learned = ref.watch(learnedProvider);
  return DeckProgress(
    total: words.length,
    learned: words.where((word) => learned.contains(word.id)).length,
  );
});

/// Ana ekranın üst kısmındaki genel ilerleme özeti.
final overallProgressProvider = Provider<DeckProgress>((ref) {
  final all = ref.watch(wordRepositoryProvider).allWords;
  final learned = ref.watch(learnedProvider);
  return DeckProgress(
    total: all.length,
    learned: all.where((word) => learned.contains(word.id)).length,
  );
});
