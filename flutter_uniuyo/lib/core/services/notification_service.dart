import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../features/reminders/domain/entities/reminder.dart';

/// Service for scheduling and managing local notifications
/// Integrates with flutter_local_notifications
/// Pattern matches Android BroadcastAlarm.kt
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Channel ID matches Android BroadcastAlarm.kt line 15
  static const String _channelId = 'UniuyoTownCampus';
  static const String _channelName = 'Building Reminders';

  /// Initialize notification service
  /// Call this in main.dart before runApp()
  Future<void> initialize({
    required Function(String buildingId) onNotificationTapped,
  }) async {
    if (_initialized) return;

    // Initialize timezones with local timezone
    tz.initializeTimeZones();
    // Set local timezone (important for scheduled notifications)
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Lagos')); // Nigeria timezone
    } catch (e) {
      debugPrint('NotificationService: Could not set timezone, using UTC');
    }

    // Android initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Handle notification tap
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          onNotificationTapped(payload); // Pass buildingId for navigation
        }
      },
    );

    // Request permissions (iOS)
    await _requestPermissions();

    _initialized = true;
  }

  /// Request notification permissions (iOS + Android)
  Future<bool> _requestPermissions() async {
    // iOS permissions
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Android 13+ POST_NOTIFICATIONS permission
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Request POST_NOTIFICATIONS permission (Android 13+)
      await androidPlugin.requestNotificationsPermission();

      // Request SCHEDULE_EXACT_ALARM permission (Android 14+)
      // This is CRITICAL for scheduled notifications to work
      await androidPlugin.requestExactAlarmsPermission();

    }

    return iosResult ?? true;
  }

  /// Schedule a reminder notification
  /// Matches Android notification setup from BroadcastAlarm.kt
  Future<void> scheduleReminder(Reminder reminder) async {
    try {

      // Check if exact alarms are permitted (Android 14+)
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      bool canScheduleExact = true;
      if (androidPlugin != null) {
        canScheduleExact = await androidPlugin.canScheduleExactNotifications() ?? false;
        if (!canScheduleExact) {
          // Request permission if not granted
          await androidPlugin.requestExactAlarmsPermission();
          canScheduleExact = await androidPlugin.canScheduleExactNotifications() ?? false;
        }
      }

      // Android notification details - matches BroadcastAlarm.kt lines 21-32
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifications for building appointments',
        importance: Importance.max, // Maximum importance for sound
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        // Uses default notification sound
        enableLights: true,
        ledColor: Color(0xFF0000FF), // Blue, matches Android line 29
        ledOnMs: 1000,
        ledOffMs: 500,
        fullScreenIntent: true, // Wake screen
      );

      // iOS notification details - with foreground presentation
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Time sensitive ensures notification shows prominently
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert DateTime to TZDateTime for proper timezone handling
      final scheduledDate = tz.TZDateTime.from(
        reminder.scheduledDateTime,
        tz.local,
      );

      // Notification text matches Android pattern from BroadcastAlarm.kt lines 55-57
      final title = 'Uniuyo Town Campus'; // Matches Android line 55
      final body = reminder.message ??
          'Reminder: ${reminder.buildingDisplayName}'; // More specific than Android

      // Use exact scheduling if permitted, otherwise use inexact (may be delayed)
      final scheduleMode = canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        reminder.notificationId,
        title,
        body,
        scheduledDate,
        details,
        payload: reminder.buildingId, // Pass buildingId for navigation
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule - $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminder(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel - $e');
      rethrow;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: Failed to cancel all - $e');
      rethrow;
    }
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool?> areNotificationsEnabled() async {
    return await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
  }
}
