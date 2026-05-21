import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

/// Building reminder entity for scheduling notifications
/// Stored in SharedPreferences as JSON array
@freezed
class Reminder with _$Reminder {
  const factory Reminder({
    required String id, // UUID for unique identification
    required String buildingId, // Building.name (e.g., "B11")
    required String buildingDisplayName, // Building.displayName (e.g., "B11 - Library")
    required DateTime scheduledDateTime,
    required int notificationId, // For cancellation via flutter_local_notifications
    required bool isActive, // false if cancelled or past
    String? message, // Optional reminder message
    DateTime? createdAt,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);
}

extension ReminderExtension on Reminder {
  /// Check if reminder is in the past
  bool get isPast => scheduledDateTime.isBefore(DateTime.now());

  /// Check if reminder should fire soon (within 1 minute)
  bool get shouldFireSoon =>
      scheduledDateTime.difference(DateTime.now()).inMinutes < 1;
}
