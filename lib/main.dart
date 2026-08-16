import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/word_repository.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
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

  // Tercihler ve 16 bin kelimelik havuz uygulama çizilmeden hazırlanıyor;
  // böylece ilk karede doğru tema ve doğru ilerleme görünüyor. JSON çözümlemesi
  // ayrı bir isolate'te yapıldığı için açılış donmuyor.
  final prefs = await SharedPreferences.getInstance();
  final repository = await WordRepository.load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        wordRepositoryProvider.overrideWithValue(repository),
      ],
      child: const FlipRuApp(),
    ),
  );
}
