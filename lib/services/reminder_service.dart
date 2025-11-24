// services/reminder_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';

class ReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    print('Notification clicked: ${notificationResponse.id}');
  }

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    print('Notification clicked (background): ${notificationResponse.id}');
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // Android channel - HAPUS sound specification yang bermasalah
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_reminder_channel',
      'Prayer Reminders',
      description: 'Reminder untuk sholat dan doa harian',
      importance: Importance.high,
      // HAPUS baris sound di sini
      // sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
      onDidReceiveBackgroundNotificationResponse,
    );
  }

  // static Future<String> _getTimeZoneName() async => 'Asia/Jakarta';

  static Future<void> schedulePrayerReminders() async {
    final hasPermission = await requestNotificationPermission();
    if (!hasPermission) {
      print('Izin notification tidak diberikan');
      return;
    }

    final prayerTimes = [
      _TimeOfDay(5, 30, "Subuh"),
      _TimeOfDay(12, 0, "Dzuhur"),
      _TimeOfDay(15, 30, "Ashar"),
      _TimeOfDay(18, 0, "Maghrib"),
      _TimeOfDay(19, 30, "Isya"),
    ];

    for (final time in prayerTimes) {
      final type = 'sholat_${time.prayerName.toLowerCase()}';
      await _scheduleDailyReminder(
        time.hour,
        time.minute,
        "Waktunya Sholat ${time.prayerName} 🕌",
        "Jangan lupa sholat ${time.prayerName} ya! Allah sayang pada anak yang rajin sholat.",
        type,
      );
    }

    await _scheduleDailyReminder(
      7, 0, "Doa Pagi 📿", "Jangan lupa baca doa pagi ya! Semoga hari mu menyenangkan.", 'doa_pagi',
    );
    await _scheduleDailyReminder(
      18, 30, "Doa Sore 📿", "Jangan lupa baca doa sore ya! Semoga dimalam hari kamu dilindungi Allah.", 'doa_sore',
    );

    print('Semua reminder berhasil dijadwalkan');
  }

  static Future<void> _scheduleDailyReminder(
      int hour,
      int minute,
      String title,
      String body,
      String type,
      ) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Notification details - HAPUS sound specification yang bermasalah
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminder_channel',
          'Prayer Reminders',
          channelDescription: 'Reminder untuk sholat dan doa',
          importance: Importance.high,
          priority: Priority.high,
          // HAPUS baris sound di sini
          // sound: RawResourceAndroidNotificationSound('notification'),
          playSound: true, // Biarkan menggunakan default sound
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        _generateId(type, hour, minute),
        title,
        body,
        scheduledDate,
        notificationDetails,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: type,
      );

      print(
          '✅ Reminder $type dijadwalkan untuk ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('❌ Error scheduling reminder $type: $e');
    }
  }

  static int _generateId(String type, int hour, int minute) {
    return type.hashCode + hour * 100 + minute;
  }

  static Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    print('Semua reminder dibatalkan');
  }

  static Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isMacOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
      await androidImplementation?.requestNotificationsPermission();
      return granted ?? true;
    }

    return true; // platform lain
  }

  static Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    final pendingNotifications =
    await _notificationsPlugin.pendingNotificationRequests();

    return pendingNotifications.map((notification) {
      return {
        'id': notification.id,
        'title': notification.title ?? '',
        'body': notification.body ?? '',
        'type': notification.payload ?? 'unknown',
        'scheduledTime': _extractTimeFromId(notification.id),
      };
    }).toList();
  }

  static String _extractTimeFromId(int id) {
    final minute = id % 100;
    final hour = (id ~/ 100) % 100;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _TimeOfDay {
  final int hour;
  final int minute;
  final String prayerName;
  _TimeOfDay(this.hour, this.minute, this.prayerName);
}