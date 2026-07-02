import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/reminders/domain/entities/reminder.dart';

/// Service to manage building reminders with SharedPreferences
/// Stores reminders as JSON array
/// Pattern follows recent_searches_service.dart
class ReminderService {
  static const String _remindersKey = 'building_reminders';
  static const int _maxReminders = 50; // Prevent SharedPreferences overflow

  /// Get all reminders (active and inactive)
  Future<List<Reminder>> getAllReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_remindersKey);

      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ReminderService: Failed to load reminders - $e');
      return [];
    }
  }

  /// Get active reminders only (not past, not cancelled)
  Future<List<Reminder>> getActiveReminders() async {
    final all = await getAllReminders();
    return all.where((r) => r.isActive && !r.isPast).toList();
  }

  /// Get reminders for a specific building
  Future<List<Reminder>> getRemindersForBuilding(String buildingId) async {
    final all = await getAllReminders();
    return all
        .where((r) => r.buildingId == buildingId && r.isActive)
        .toList();
  }

  /// Save a new reminder
  Future<void> saveReminder(Reminder reminder) async {
    try {
      final reminders = await getAllReminders();

      // Check max limit
      if (reminders.length >= _maxReminders) {
        throw Exception('Maximum $_maxReminders reminders allowed');
      }

      reminders.add(reminder);
      await _persistReminders(reminders);
    } catch (e) {
      debugPrint('ReminderService: Failed to save - $e');
      rethrow;
    }
  }

  /// Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    try {
      final reminders = await getAllReminders();
      final index = reminders.indexWhere((r) => r.id == reminder.id);

      if (index != -1) {
        reminders[index] = reminder;
        await _persistReminders(reminders);
      }
    } catch (e) {
      debugPrint('ReminderService: Failed to update - $e');
      rethrow;
    }
  }

  /// Delete a reminder (soft delete by marking inactive)
  Future<void> deleteReminder(String reminderId) async {
    try {
      final reminders = await getAllReminders();
      final index = reminders.indexWhere((r) => r.id == reminderId);

      if (index != -1) {
        reminders[index] = reminders[index].copyWith(isActive: false);
        await _persistReminders(reminders);
      }
    } catch (e) {
      debugPrint('ReminderService: Failed to delete - $e');
      rethrow;
    }
  }

  /// Hard delete (actually remove from storage)
  Future<void> hardDeleteReminder(String reminderId) async {
    try {
      final reminders = await getAllReminders();
      reminders.removeWhere((r) => r.id == reminderId);
      await _persistReminders(reminders);
    } catch (e) {
      debugPrint('ReminderService: Failed to hard delete - $e');
      rethrow;
    }
  }

  /// Clean up past reminders (run on app start)
  /// Keeps active reminders + inactive from last 30 days
  Future<void> cleanupPastReminders() async {
    try {
      final reminders = await getAllReminders();
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Keep: active reminders + recent inactive reminders (last 30 days)
      final filtered = reminders.where((r) {
        if (r.isActive && !r.isPast) return true; // Keep active future
        if (!r.isActive && r.scheduledDateTime.isAfter(thirtyDaysAgo)) {
          return true; // Keep recent inactive
        }
        return false; // Remove old past reminders
      }).toList();

      if (filtered.length != reminders.length) {
        await _persistReminders(filtered);
      }
    } catch (e) {
      debugPrint('ReminderService: Failed to cleanup - $e');
    }
  }

  /// Clear all reminders
  Future<void> clearAllReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_remindersKey);
    } catch (e) {
      debugPrint('ReminderService: Failed to clear - $e');
      rethrow;
    }
  }

  /// Internal: Persist reminders to SharedPreferences
  Future<void> _persistReminders(List<Reminder> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = reminders.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_remindersKey, jsonString);
    } catch (e) {
      debugPrint('ReminderService: Failed to persist - $e');
      rethrow;
    }
  }
}
