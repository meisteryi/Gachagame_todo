import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../translations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize Timezone
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('Failed to get local timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android Initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Update notifications based on user settings
    await updateDailyReminders();
  }

  // Update daily reminder schedules based on Settings
  Future<void> updateDailyReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final notifyUncompleted = prefs.getBool('notify_uncompleted') ?? true;
    final notifyDayStart = prefs.getBool('notify_day_start') ?? true;

    // 1. 11 PM Uncompleted To-Dos Reminder (ID: 99998)
    if (notifyUncompleted) {
      await scheduleDailyNotification(
        id: 99998,
        title: '미완료 할 일 알림'.tr,
        body: '아직 끝내지 않은 할 일이 있어요!'.tr,
        hour: 23,
        minute: 0,
      );
    } else {
      await cancelNotification(99998);
    }

    // 2. 8 AM Day Start Reminder (ID: 99997)
    if (notifyDayStart) {
      await scheduleDailyNotification(
        id: 99997,
        title: '하루 시작 알림'.tr,
        body: '좋은 아침입니다. 계획을 세워 볼까요?'.tr,
        hour: 8,
        minute: 0,
      );
    } else {
      await cancelNotification(99997);
    }

    // Cancel old 10 PM daily reminder (ID: 99999) to clean up
    await cancelNotification(99999);
  }

  // Request notifications permission (Android 13+ & iOS)
  Future<bool> requestPermission() async {
    // Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    bool? androidGranted = false;
    if (androidImplementation != null) {
      androidGranted = await androidImplementation
          .requestNotificationsPermission();
    }

    // iOS
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    bool? iosGranted = false;
    if (iosImplementation != null) {
      iosGranted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return (androidGranted ?? false) || (iosGranted ?? false);
  }

  // Schedule notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Avoid scheduling in the past
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'gacha_todo_channel_id',
          'Todo Notifications',
          channelDescription: 'Channel for To-Do reminders',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'gacha_todo_daily_channel_id',
          'Daily Reminder Notifications',
          channelDescription: 'Channel for daily task check reminder',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }
}
