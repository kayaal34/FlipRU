import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  /// Seri uyarisinin kimligi; gunluk hatirlatmalar 0.._horizonDays
  /// araligini kullaniyor, cakismasin.
  static const _streakId = 100;

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
      await _syncLocalZone();

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

  /// Bildirim saatlerini cihazın kendi saat dilimine bağlar.
  ///
  /// Eskiden herkes için İstanbul kabul ediliyordu: Berlin'deki kullanıcının
  /// 20:00 hatırlatması 19:00'da geliyordu. Artık cihazın IANA adı okunuyor
  /// (ör. "Europe/Berlin"); yaz saati geçişlerini de timezone paketi biliyor.
  /// Her planlamadan önce yeniden okunuyor, kullanıcı başka şehre gidip
  /// uygulamayı açtığında bildirimler yeni yerel saate kayıyor.
  Future<void> _syncLocalZone() async {
    tz.Location? location;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      location = tz.getLocation(info.identifier);
    } catch (_) {
      location = _locationForOffset(DateTime.now().timeZoneOffset);
    }
    tz.setLocalLocation(location);
  }

  /// Ad okunamaz ya da veritabanında yoksa şu anki farkı tutan bir bölge;
  /// o da yoksa UTC. Yaz saati geçişini kaçırabilir ama saat bugün doğru.
  tz.Location _locationForOffset(Duration offset) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.timeZone(now).offset == offset) return loc;
    }
    return tz.UTC;
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (!_available) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? iosGranted ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Sistem bildirim izni açık mı? Okunamazsa açık sayıyoruz: emin
  /// olmadığımız durumda kullanıcıya boşuna hatırlatıcı kartı göstermeyelim.
  Future<bool> areEnabled() async {
    await _ensureInitialized();
    if (!_available) return true;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Günlük hatırlatmaları ve seri uyarısını siler; günün kelimesine
  /// dokunmaz. İki tür birbirinden bağımsız açılıp kapanabiliyor.
  Future<void> cancelReminders() async {
    await _ensureInitialized();
    if (!_available) return;
    try {
      for (var day = 0; day < _horizonDays; day++) {
        await _plugin.cancel(id: day);
      }
      await _plugin.cancel(id: _streakId);
    } catch (_) {}
  }

  Future<void> cancelWordOfDay() async {
    await _ensureInitialized();
    if (!_available) return;
    try {
      for (var day = 0; day < _horizonDays; day++) {
        await _plugin.cancel(id: _wordOfDayId + day);
      }
    } catch (_) {}
  }

  /// Yalnızca QA derlemesi: üç bildirim türünü gerçek içerikleriyle hemen
  /// gösterir. Saatini beklemeden görünüşü ve metni kontrol etmek için.
  Future<void> showTestNotifications({
    required (String, String) wordOfDay,
    required int goal,
    required int streak,
    required Strings strings,
  }) async {
    await _ensureInitialized();
    if (!_available) return;
    await requestPermission();

    NotificationDetails details(String channel, String name, String desc) =>
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            name,
            channelDescription: desc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        );

    try {
      await _plugin.show(
        id: 900,
        title: wordOfDay.$1,
        body: wordOfDay.$2,
        notificationDetails: _expand(
          details(
            _wordChannelId,
            strings.wordOfDayToggle,
            strings.wordOfDayToggleSub,
          ),
          wordOfDay.$2,
        ),
      );
      await _plugin.show(
        id: 901,
        title: strings.notificationTitle,
        body: strings.notificationBody.replaceFirst('{}', '$goal'),
        notificationDetails: _expand(
          details(_channelId, strings.notifChannel, strings.notifChannelDesc),
          strings.notificationBody.replaceFirst('{}', '$goal'),
        ),
      );
      await _plugin.show(
        id: 902,
        title: strings.streakNotifTitle,
        body: strings.streakNotifBody.replaceFirst(
          '{}',
          '${streak > 0 ? streak : 5}',
        ),
        notificationDetails: _expand(
          details(_channelId, strings.notifChannel, strings.notifChannelDesc),
          strings.streakNotifBody.replaceFirst(
            '{}',
            '${streak > 0 ? streak : 5}',
          ),
        ),
      );
      // Anında gösterim zamanlanmış yolu sınamıyor: alıcı eksikken bile
      // yukarıdakiler görünüyordu. Bu bildirim bir dakika sonra çalmalı.
      await _plugin.zonedSchedule(
        id: 903,
        title: strings.notificationTitle,
        body: '⏰ ${strings.notificationBody.replaceFirst('{}', '$goal')}',
        scheduledDate: tz.TZDateTime.now(
          tz.local,
        ).add(const Duration(minutes: 1)),
        notificationDetails: details(
          _channelId,
          strings.notifChannel,
          strings.notifChannelDesc,
        ),
        androidScheduleMode: await _scheduleMode(),
      );
    } catch (_) {}
  }

  /// Tam saatli alarm izni varsa onu, yoksa esnek alarmı kullan.
  ///
  /// Esnek alarmın penceresi kurulduğu andan çalacağı ana kadarki sürenin
  /// dörtte üçü kadar: akşam 20:00'ye kurulan hatırlatma gece 2'de, 22:30'daki
  /// seri uyarısı ertesi sabah (seri kopmuşken) gelebiliyordu. Android 12-13'te
  /// izin kendiliğinden verilir; 14+'ta kullanıcı vermediyse esneğe düşüyoruz.
  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (await android?.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Uzun gövde tek satırda kesiliyordu ("...bir t.."); bildirim aşağı
  /// çekilince metnin tamamı görünsün.
  NotificationDetails _expand(NotificationDetails base, String body) {
    final a = base.android!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        a.channelId,
        a.channelName,
        channelDescription: a.channelDescription,
        importance: a.importance,
        priority: a.priority,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: base.iOS,
    );
  }

  /// Günün kelimesi bildirimleri; kimlikleri hatırlatmalarla çakışmasın.
  static const _wordOfDayId = 200;
  static const _wordChannelId = 'word_of_day';

  /// Önümüzdeki günlerin kelimesini [hour]:[minute] saatine kurar.
  ///
  /// Arka planda çalışan bir şey olmadığı için bir haftalık bildirim
  /// peşinen kuruluyor ve her açılışta tazeleniyor. [wordFor] o günün
  /// saatinde gösterilecek (başlık, gövde) çiftini veriyor; kelime widget'taki
  /// günün kelimesiyle aynı hesaptan geliyor.
  Future<void> scheduleWordOfDay({
    required int hour,
    required int minute,
    required (String, String) Function(DateTime when) wordFor,
    required Strings strings,
  }) async {
    await _ensureInitialized();
    if (!_available) return;

    try {
      await _syncLocalZone();
      await cancelWordOfDay();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _wordChannelId,
          strings.wordOfDayToggle,
          channelDescription: strings.wordOfDayToggleSub,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      final mode = await _scheduleMode();
      final now = tz.TZDateTime.now(tz.local);
      for (var day = 0; day < _horizonDays; day++) {
        final when = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + day,
          hour,
          minute,
        );
        if (!when.isAfter(now)) continue;
        final (title, body) = wordFor(when);
        await _plugin.zonedSchedule(
          id: _wordOfDayId + day,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: _expand(details, body),
          androidScheduleMode: mode,
        );
      }
    } catch (_) {
      // Bildirim kurulamazsa uygulama çalışmaya devam etsin.
    }
  }

  /// [hour]:[minute] saatinde, önümüzdeki [_horizonDays] gün için hatırlatma
  /// kurar. [skipToday] bugünün hedefi tamamlandığında true geçilir.
  ///
  /// [streak] sıfırdan büyükse ayrıca bir "serin tehlikede" uyarısı
  /// kuruluyor: bugün henüz çalışılmadıysa ([studiedToday] false) bu akşama,
  /// çalışıldıysa yarın akşama. Uygulama açılıp bir şey yapıldığında bütün
  /// bildirimler yeniden kuruluyor, yani uyarı yalnızca gerçekten çalışılmayan
  /// gün çalıyor. Daha ileriye kurmanın anlamı yok — seri o noktada zaten
  /// kopmuş olur ve "serini kaybetme" demek yanlış olurdu.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool skipToday,
    required int goal,
    required int streak,
    required bool studiedToday,
    required Strings strings,
  }) async {
    await _ensureInitialized();
    if (!_available) return;

    try {
      await _syncLocalZone();
      await cancelReminders();

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

      final mode = await _scheduleMode();
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
          notificationDetails: _expand(
            details,
            strings.notificationBody.replaceFirst('{}', '$goal'),
          ),
          androidScheduleMode: mode,
        );
      }

      if (streak > 0) {
        // Hatirlatmadan sonra, gunun bitmesine yakin bir saat.
        var uyariSaat = hour + 2;
        if (uyariSaat < 21) uyariSaat = 21;
        if (uyariSaat > 23) uyariSaat = 23;

        var uyari = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + (studiedToday ? 1 : 0),
          uyariSaat,
          30,
        );
        // Bugünün uyarı saati geçtiyse (gece yarısına az kala açıldı) yarına
        // kurmak yanlış olur: seri o zaman bu gece kopmuş olacak.
        if (!uyari.isAfter(now)) return;
        await _plugin.zonedSchedule(
          id: _streakId,
          title: strings.streakNotifTitle,
          body: strings.streakNotifBody.replaceFirst('{}', '$streak'),
          scheduledDate: uyari,
          notificationDetails: _expand(
            details,
            strings.streakNotifBody.replaceFirst('{}', '$streak'),
          ),
          androidScheduleMode: mode,
        );
      }
    } catch (_) {
      // Bildirim kurulamazsa uygulama çalışmaya devam etsin.
    }
  }
}
