import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/deck.dart';
import '../data/models/premium.dart';
import '../data/models/word.dart';
import 'app_providers.dart';
import 'library_providers.dart';

class PremiumNotifier extends Notifier<PremiumState> {
  static const _key = 'premium_state';

  @override
  PremiumState build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const PremiumState();
    return PremiumState.fromMap(
      (json.decode(raw) as Map<String, dynamic>).cast<String, Object?>(),
    );
  }

  /// Mağaza satın alması doğrulandığında çağrılır.
  ///
  /// Şu an gerçek bir ödeme akışı bağlı değil; bu metot yalnızca doğrulanmış
  /// bir satın almanın sonucunu yazmak için var.
  void activate(PremiumPlan plan) {
    final base = state.isActive ? state.expiresAt! : DateTime.now();
    _persist(
      PremiumState(
        expiresAt: DateTime(base.year, base.month + plan.months, base.day),
      ),
    );
  }

  void deactivate() => _persist(const PremiumState());

  void _persist(PremiumState value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, json.encode(value.toMap()));
  }
}

final premiumProvider =
    NotifierProvider<PremiumNotifier, PremiumState>(PremiumNotifier.new);

final isPremiumProvider =
    Provider<bool>((ref) => ref.watch(premiumProvider).isActive);

/// Bir destenin premium gerektirip gerektirmediği.
final deckLockedProvider = Provider.family<bool, String>((ref, deckId) {
  if (ref.watch(isPremiumProvider)) return false;

  final deck = ref.watch(deckByIdProvider(deckId));
  return switch (deck.kind) {
    // Yıldızlı kelimeleri toplu çalışmak premium.
    DeckKind.starred => true,
    DeckKind.level => !FreeLimits.openLevels.contains(deck.level!.name),
    DeckKind.theme => _themeIndex(ref, deck.theme!) >= FreeLimits.openThemes,
  };
});

int _themeIndex(Ref ref, WordTheme theme) {
  final decks = ref.watch(themeDecksProvider);
  return decks.indexWhere((d) => d.theme == theme);
}

/// Genel testler (bölüm testi dışındakiler) premium gerektiriyor.
final generalTestsLockedProvider = Provider<bool>(
  (ref) => FreeLimits.generalTestsRequirePremium && !ref.watch(isPremiumProvider),
);
