import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  const NotificationService._();

  static const String smartNotificationsEnabledKey =
      'smartNotificationsEnabled';

  static const int _fridayNightId = 7001;
  static const int _saturdayNoonId = 7002;
  static const int _sundayChillId = 7003;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool debugSkipPluginCalls = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    if (debugSkipPluginCalls) {
      _isInitialized = true;
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir Tonight'),
      windows: WindowsInitializationSettings(
        appName: 'Tonight',
        appUserModelId: 'Tonight.App.LocalNotifications',
        guid: '5e04b6b8-9f84-4f3f-b7c2-6d9f2f22d6a1',
      ),
    );

    try {
      await _plugin.initialize(settings: initializationSettings);
      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    if (debugSkipPluginCalls || kIsWeb) {
      return true;
    }

    try {
      final androidGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      final iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final macGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      return androidGranted ?? iosGranted ?? macGranted ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    if (debugSkipPluginCalls || kIsWeb) {
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextWeekdayTime(
        weekday: weekday,
        hour: hour,
        minute: minute,
      ),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  static Future<bool> scheduleSmartNotifications() async {
    await initialize();
    final permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      await setSmartNotificationsEnabled(false);
      return false;
    }

    try {
      await cancelNotifications();
      await Future.wait([
        scheduleNotification(
          id: _fridayNightId,
          weekday: DateTime.friday,
          hour: 19,
          minute: 0,
          title: '¿Plan para esta noche?',
          body: 'Tonight puede montarte algo en segundos.',
          payload: 'smart_friday_night',
        ),
        scheduleNotification(
          id: _saturdayNoonId,
          weekday: DateTime.saturday,
          hour: 12,
          minute: 0,
          title: 'Plan rápido para hoy',
          body: 'Café, paseo, cita o sorpresa. Tú eliges.',
          payload: 'smart_saturday_noon',
        ),
        scheduleNotification(
          id: _sundayChillId,
          weekday: DateTime.sunday,
          hour: 18,
          minute: 0,
          title: 'Cierra la semana con un plan Chill',
          body: 'Algo tranquilo también cuenta.',
          payload: 'smart_sunday_chill',
        ),
      ]);
      await setSmartNotificationsEnabled(true);
      return true;
    } catch (_) {
      await setSmartNotificationsEnabled(false);
      return false;
    }
  }

  static Future<void> cancelNotifications() async {
    await initialize();
    if (!debugSkipPluginCalls && !kIsWeb) {
      try {
        await Future.wait([
          _plugin.cancel(id: _fridayNightId),
          _plugin.cancel(id: _saturdayNoonId),
          _plugin.cancel(id: _sundayChillId),
        ]);
      } catch (_) {
        // Cancellation should never break settings toggles.
      }
    }
  }

  static Future<void> cancelSmartNotifications() async {
    await cancelNotifications();
    await setSmartNotificationsEnabled(false);
  }

  static Future<bool> isSmartNotificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(smartNotificationsEnabledKey) ?? false;
  }

  static Future<void> setSmartNotificationsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(smartNotificationsEnabledKey, enabled);
  }

  static NotificationDetails get _notificationDetails {
    const androidDetails = AndroidNotificationDetails(
      'tonight_smart_notifications',
      'Tonight smart reminders',
      channelDescription: 'Recordatorios locales para crear planes en Tonight.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  static tz.TZDateTime _nextWeekdayTime({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final daysUntil = (weekday - scheduledDate.weekday) % DateTime.daysPerWeek;
    scheduledDate = scheduledDate.add(Duration(days: daysUntil));

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: DateTime.daysPerWeek),
      );
    }

    return scheduledDate;
  }
}
