import 'core/config/qa_mode.dart' as qa;
import 'main.dart' as base;

/// QA derlemesinin giriş noktası.
///
/// `flutter build apk --flavor qa -t lib/main_qa.dart` ile derlenir; ayrı
/// bir applicationId'ye sahip olduğu için (bkz. android/app/build.gradle.kts)
/// Play Store'daki kapalı test sürümüyle aynı telefonda yan yana durur,
/// birbirine karışmaz. Tek farkı: açılışta bütün kelimeler öğrenilmiş,
/// bütün bölüm/testler geçilmiş gösterilir — içerik incelemek için.
Future<void> main() async {
  qa.qaMode = true;
  await base.bootstrap();
}
