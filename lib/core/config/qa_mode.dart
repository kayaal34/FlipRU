import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/unit_providers.dart';
import '../../providers/writing_test_providers.dart';

/// True yalnızca `lib/main_qa.dart` üzerinden başlatılan derlemede.
///
/// Play Store'a giden asıl uygulama (lib/main.dart) bunu hiç görmez; her
/// zaman false kalır. QA derlemesi ayrı bir applicationId ile (bkz.
/// android/app/build.gradle.kts, "qa" flavor'ı) telefona kurulduğu için
/// Play Console'daki kapalı test sürümüyle yan yana durabilir, birbirine
/// karışmaz.
bool qaMode = false;

/// Bütün kelimeleri "öğrenilmiş", bütün bölüm/testleri "geçilmiş" işaretler.
///
/// Amaç ilerleme ölçmek değil — içerik incelemesi: kilit açmak, testi
/// çözmek gibi hiçbir adım atmadan her seviyeyi, her temayı, her kelimeyi
/// gezip kontrol edebilmek. `container` henüz `runApp` çağrılmadan, ana
/// widget ağacının dışında kuruluyor; bu yüzden `ProviderContainer` üzerinden
/// doğrudan okunuyor.
void seedQaProgress(ProviderContainer container) {
  final repository = container.read(wordRepositoryProvider);
  container
      .read(learnedProvider.notifier)
      .seedAll(repository.allWords.map((w) => w.id));

  final unitIds = <String>[
    for (final deck in [
      ...container.read(levelDecksProvider),
      ...container.read(themeDecksProvider),
    ])
      for (final progress in container.read(deckUnitsProvider(deck.id)))
        progress.unit.id,
    for (final direction in WritingDirection.values)
      for (final test in container.read(writingTestsProvider(direction)))
        test.id,
  ];
  container.read(passedUnitsProvider.notifier).seedAll(unitIds);
}
