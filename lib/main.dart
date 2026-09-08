import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/qa_mode.dart';
import 'data/repositories/word_repository.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  await bootstrap();
}

/// Gerçek Play Store girişi ve QA girişi (bkz. main_qa.dart) aynı kurulumu
/// paylaşıyor; ikisini ayıran tek şey `qaMode` bayrağı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Tercihler ve ~9 bin kelimelik havuz uygulama çizilmeden hazırlanıyor;
  // böylece ilk karede doğru tema ve doğru ilerleme görünüyor. JSON çözümlemesi
  // ayrı bir isolate'te yapıldığı için açılış donmuyor.
  final prefs = await SharedPreferences.getInstance();
  final repository = await WordRepository.load();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      wordRepositoryProvider.overrideWithValue(repository),
    ],
  );

  // QA derlemesinde arayüz çizilmeden önce her şeyi "öğrenilmiş/geçilmiş"
  // olarak isaretliyoruz ki uygulama acildiginda zaten tamami acik gelsin.
  if (qaMode) seedQaProgress(container);

  runApp(
    UncontrolledProviderScope(container: container, child: const FlipRuApp()),
  );
}
