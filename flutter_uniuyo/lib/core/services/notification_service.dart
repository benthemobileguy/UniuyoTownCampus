import 'dart:typed_data';
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

    debugPrint('🔔 NotificationService: Initializing...');

    // Initialize timezones
    tz.initializeTimeZones();

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
          debugPrint(
              '👆 NotificationService: Notification tapped, building: $payload');
          onNotificationTapped(payload); // Pass buildingId
        }
      },
    );

    // Request permissions (iOS)
    await _requestPermissions();

    _initialized = true;
    debugPrint('✅ NotificationService: Initialized');
  }

  /// Request notification permissions (iOS)
  Future<bool> _requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? true;
  }

  /// Schedule a reminder notification
  /// Matches Android notification setup from BroadcastAlarm.kt
  Future<void> scheduleReminder(Reminder reminder) async {
    try {
      debugPrint(
          '⏰ NotificationService: Scheduling reminder ${reminder.notificationId}');

      // Android notification details - matches BroadcastAlarm.kt lines 21-32
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifications for building appointments',
        importance: Importance.high, // IMPORTANCE_HIGH from Android
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Matches Android line 30
        playSound: true,
        enableLights: true,
        ledColor: const Color(0xFF0000FF), // Blue, matches Android line 29
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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

      await _notifications.zonedSchedule(
        reminder.notificationId,
        title,
        body,
        scheduledDate,
        details,
        payload: reminder.buildingId, // Pass buildingId for navigation
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
          '✅ NotificationService: Scheduled notification ${reminder.notificationId} for ${reminder.scheduledDateTime}');
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to schedule notification - $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminder(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      debugPrint('🔕 NotificationService: Cancelled notification $notificationId');
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to cancel notification - $e');
      rethrow;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🔕 NotificationService: Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to cancel all notifications - $e');
      rethrow;
    }
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled (for debugging)
  Future<bool?> areNotificationsEnabled() async {
    return await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
  }
}
