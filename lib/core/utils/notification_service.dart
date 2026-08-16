import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../i18n/strings.dart';

/// Günlük çalışma hatırlatması.
///
/// Arka planda çalışan bir görev yok: uygulama her açıldığında (ve ayar
/// değiştiğinde) önümüzdeki günler için bildirimler yeniden planlanıyor.
/// Hedef bugün tamamlandıysa bugünün bildirimi atlanıyor — böylece
/// "tamamlamadınız" mesajı tamamlamış kullanıcıya gitmiyor.
class NotificationService {
  NotificationService();

  static const _channelId = 'daily_reminder';
  static const _horizonDays = 7;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) return;

    try {
      tzdata.initializeTimeZones();
      // Cihazın yerel saatini kullanmak için UTC yerine local konum.
      tz.setLocalLocation(tz.getLocation(await _deviceTimeZone()));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  /// Cihaz saat dilimi okunamazsa Türkiye'ye düşüyoruz.
  Future<String> _deviceTimeZone() async {
    try {
      final offset = DateTime.now().timeZoneOffset;
      if (offset == const Duration(hours: 3)) return 'Europe/Istanbul';
    } catch (_) {}
    return 'Europe/Istanbul';
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (!_available) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted =
          await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? iosGranted ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    if (!_available) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// [hour]:[minute] saatinde, önümüzdeki [_horizonDays] gün için hatırlatma
  /// kurar. [skipToday] bugünün hedefi tamamlandığında true geçilir.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required int goal,
    required Strings strings,
  }) async {
    await _ensureInitialized();
    if (!_available) return;

    try {
      await _plugin.cancelAll();

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          strings.notifChannel,
          channelDescription: strings.notifChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      final now = tz.TZDateTime.now(tz.local);
      for (var day = 0; day < _horizonDays; day++) {
        var when = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          hour,
          minute,
        );
        if (!when.isAfter(now)) continue;
        if (day == 0 && skipToday) continue;

        await _plugin.zonedSchedule(
          id: day,
          title: strings.notificationTitle,
          body: strings.notificationBody.replaceFirst('{}', '$goal'),
          scheduledDate: when,
          notificationDetails: details,
          // Kesin alarm izni istemiyoruz; birkaç dakika sapma sorun değil.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // Bildirim kurulamazsa uygulama çalışmaya devam etsin.
    }
  }
}
