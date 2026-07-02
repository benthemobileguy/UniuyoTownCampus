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
  return ReminderService();
}

/// Provider for notification service
@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

/// Provider for all active reminders
@riverpod
Future<List<Reminder>> activeReminders(ActiveRemindersRef ref) async {
  final service = ref.watch(reminderServiceProvider);
  return await service.getActiveReminders();
}

/// Provider for reminders of a specific building
@riverpod
Future<List<Reminder>> buildingReminders(
  BuildingRemindersRef ref,
  String buildingId,
) async {
  final service = ref.watch(reminderServiceProvider);
  return await service.getRemindersForBuilding(buildingId);
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
    final service = ref.read(reminderServiceProvider);
    await service.cleanupPastReminders();
  }

  /// Create and schedule a new reminder
  Future<Reminder?> createReminder({
    required String buildingId,
    required String buildingDisplayName,
    required DateTime scheduledDateTime,
    String? message,
  }) async {
    try {
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

      return reminder;
    } catch (e) {
      debugPrint('ReminderManager: Failed to create reminder - $e');
      return null;
    }
  }

  /// Cancel/delete a reminder
  Future<void> cancelReminder(Reminder reminder) async {
    try {
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
    } catch (e) {
      debugPrint('ReminderManager: Failed to cancel reminder - $e');
      rethrow;
    }
  }

  /// Update a reminder (reschedule)
  Future<void> updateReminder(Reminder reminder) async {
    try {
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
    } catch (e) {
      debugPrint('ReminderManager: Failed to update reminder - $e');
      rethrow;
    }
  }
}
