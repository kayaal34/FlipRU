import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/notification_service.dart';
import '../core/utils/speech_service.dart';
import '../data/repositories/word_repository.dart';
import 'settings_provider.dart';

/// `main()` içinde `overrideWithValue` ile gerçek örneği enjekte edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider main() içinde override edilmelidir.',
  ),
);

/// Kelime havuzu açılışta bir kez yüklenir; burada hazır örnek beklenir.
final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => throw UnimplementedError(
    'wordRepositoryProvider main() içinde override edilmelidir.',
  ),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  // Ayarlardaki hız değişimini motora yansıt.
  service.setRate(ref.watch(settingsProvider.select((s) => s.speechRate)).value);
  ref.onDispose(service.stop);
  return service;
});
