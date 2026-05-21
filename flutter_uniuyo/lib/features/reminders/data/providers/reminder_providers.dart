import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/reminder.dart';

part 'reminder_providers.g.dart';

/// Provider for reminder service
@riverpod
ReminderService reminderService(ReminderServiceRef ref) {
  debugPrint('🔧 Provider: Creating ReminderService');
  return ReminderService();
}

/// Provider for notification service
@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  debugPrint('🔧 Provider: Creating NotificationService');
  return NotificationService();
}

/// Provider for all active reminders
@riverpod
Future<List<Reminder>> activeReminders(ActiveRemindersRef ref) async {
  debugPrint('📍 Provider: Fetching active reminders...');
  final service = ref.watch(reminderServiceProvider);
  final reminders = await service.getActiveReminders();
  debugPrint('✅ Provider: Fetched ${reminders.length} active reminders');
  return reminders;
}

/// Provider for reminders of a specific building
@riverpod
Future<List<Reminder>> buildingReminders(
  BuildingRemindersRef ref,
  String buildingId,
) async {
  debugPrint('📍 Provider: Fetching reminders for building $buildingId...');
  final service = ref.watch(reminderServiceProvider);
  final reminders = await service.getRemindersForBuilding(buildingId);
  debugPrint(
      '✅ Provider: Fetched ${reminders.length} reminders for $buildingId');
  return reminders;
}

/// Provider to check if a building has active reminders
@riverpod
Future<bool> hasBuildingReminders(
  HasBuildingRemindersRef ref,
  String buildingId,
) async {
  final reminders =
      await ref.watch(buildingRemindersProvider(buildingId).future);
  return reminders.isNotEmpty;
}

/// State notifier for managing reminders (CRUD operations)
@riverpod
class ReminderManager extends _$ReminderManager {
  @override
  Future<void> build() async {
    // Initialize - cleanup old reminders on app start
    debugPrint('🔧 ReminderManager: Initializing...');
    final service = ref.read(reminderServiceProvider);
    await service.cleanupPastReminders();
    debugPrint('✅ ReminderManager: Initialized');
  }

  /// Create and schedule a new reminder
  Future<Reminder?> createReminder({
    required String buildingId,
    required String buildingDisplayName,
    required DateTime scheduledDateTime,
    String? message,
  }) async {
    try {
      debugPrint(
          '📝 ReminderManager: Creating reminder for $buildingDisplayName');

      // Generate unique ID and notification ID
      final id = const Uuid().v4();
      // Use timestamp modulo max int for notification ID (must be unique)
      final notificationId =
          DateTime.now().millisecondsSinceEpoch % 2147483647;

      final reminder = Reminder(
        id: id,
        buildingId: buildingId,
        buildingDisplayName: buildingDisplayName,
        scheduledDateTime: scheduledDateTime,
        notificationId: notificationId,
        isActive: true,
        message: message,
        createdAt: DateTime.now(),
      );

      // Save to storage
      final reminderService = ref.read(reminderServiceProvider);
      await reminderService.saveReminder(reminder);

      // Schedule notification
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.scheduleReminder(reminder);

      // Invalidate providers to refresh UI
      ref.invalidate(activeRemindersProvider);
      ref.invalidate(buildingRemindersProvider(buildingId));
      ref.invalidate(hasBuildingRemindersProvider(buildingId));

      debugPrint('✅ ReminderManager: Created reminder ${reminder.id}');
      return reminder;
    } catch (e) {
      debugPrint('❌ ReminderManager: Failed to create reminder - $e');
      return null;
    }
  }

  /// Cancel/delete a reminder
  Future<void> cancelReminder(Reminder reminder) async {
    try {
      debugPrint('🔕 ReminderManager: Cancelling reminder ${reminder.id}');

      // Cancel notification
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelReminder(reminder.notificationId);

      // Mark as inactive
      final reminderService = ref.read(reminderServiceProvider);
      await reminderService.deleteReminder(reminder.id);

      // Invalidate providers
      ref.invalidate(activeRemindersProvider);
      ref.invalidate(buildingRemindersProvider(reminder.buildingId));
      ref.invalidate(hasBuildingRemindersProvider(reminder.buildingId));

      debugPrint('✅ ReminderManager: Cancelled reminder ${reminder.id}');
    } catch (e) {
      debugPrint('❌ ReminderManager: Failed to cancel reminder - $e');
      rethrow;
    }
  }

  /// Update a reminder (reschedule)
  Future<void> updateReminder(Reminder reminder) async {
    try {
      debugPrint('📝 ReminderManager: Updating reminder ${reminder.id}');

      // Cancel old notification
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelReminder(reminder.notificationId);

      // Schedule new notification
      await notificationService.scheduleReminder(reminder);

      // Update storage
      final reminderService = ref.read(reminderServiceProvider);
      await reminderService.updateReminder(reminder);

      // Invalidate providers
      ref.invalidate(activeRemindersProvider);
      ref.invalidate(buildingRemindersProvider(reminder.buildingId));

      debugPrint('✅ ReminderManager: Updated reminder ${reminder.id}');
    } catch (e) {
      debugPrint('❌ ReminderManager: Failed to update reminder - $e');
      rethrow;
    }
  }
}
