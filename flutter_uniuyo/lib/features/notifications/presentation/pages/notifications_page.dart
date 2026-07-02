import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reminders/data/providers/reminder_providers.dart';
import '../../../reminders/domain/entities/reminder.dart';
import '../../../search/presentation/pages/search_page.dart';

/// Notifications page showing scheduled building reminders
/// Matches the native Android app behavior:
/// - Empty state: "You have no notifications yet" with "Set Notifications" button
/// - With reminders: List of scheduled notifications with building info
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(activeRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: remindersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Error loading notifications',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return _buildEmptyState();
          }
          return _buildRemindersList(reminders);
        },
      ),
    );
  }

  /// Empty state matching native Android app exactly
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You have no notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          // Card-style button matching native Android app
          Material(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _navigateToSearch,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Text(
                  'Set Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.colorPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// List of scheduled reminders
  Widget _buildRemindersList(List<Reminder> reminders) {
    // Sort by scheduled time (nearest first)
    final sortedReminders = List<Reminder>.from(reminders)
      ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.colorPrimary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.colorPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${sortedReminders.length} Scheduled Reminder${sortedReminders.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.colorPrimary,
                ),
              ),
              const Spacer(),
              if (sortedReminders.length > 1)
                TextButton(
                  onPressed: () => _showClearAllDialog(sortedReminders),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Reminders list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedReminders.length,
            itemBuilder: (context, index) {
              return _buildReminderCard(sortedReminders[index]);
            },
          ),
        ),
      ],
    );
  }

  /// Card for each reminder
  Widget _buildReminderCard(Reminder reminder) {
    final now = DateTime.now();
    final isUpcoming = reminder.scheduledDateTime.isAfter(now);
    final timeDiff = reminder.scheduledDateTime.difference(now);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToBuildingOnMap(reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Building icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.colorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.colorPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Building name
                    Text(
                      reminder.buildingDisplayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Message (if any)
                    if (reminder.message != null && reminder.message!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          reminder.message!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Scheduled time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isUpcoming ? AppColors.customGreen : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatScheduledTime(reminder.scheduledDateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUpcoming ? AppColors.customGreen : Colors.grey,
                            fontWeight: isUpcoming ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isUpcoming && timeDiff.inHours < 24) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatTimeUntil(timeDiff),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () => _deleteReminder(reminder),
                tooltip: 'Delete reminder',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    final isTomorrow = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1;

    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, yyyy');

    if (isToday) {
      return 'Today at ${timeFormat.format(dateTime)}';
    } else if (isTomorrow) {
      return 'Tomorrow at ${timeFormat.format(dateTime)}';
    } else {
      return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
    }
  }

  String _formatTimeUntil(Duration diff) {
    if (diff.inMinutes < 60) {
      return 'in ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'in ${diff.inHours}h';
    } else {
      return 'in ${diff.inDays}d';
    }
  }

  void _navigateToSearch() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  void _navigateToBuildingOnMap(Reminder reminder) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SearchPage(
          initialBuildingName: reminder.buildingDisplayName,
        ),
      ),
    );
  }

  void _deleteReminder(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text(
          'Are you sure you want to delete the reminder for "${reminder.buildingDisplayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete(reminder);
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _performDelete(Reminder reminder) async {
    try {
      await ref.read(reminderManagerProvider.notifier).cancelReminder(reminder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder for "${reminder.buildingDisplayName}" deleted'),
            backgroundColor: AppColors.customGreen,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                // Re-create the reminder
                ref.read(reminderManagerProvider.notifier).createReminder(
                  buildingId: reminder.buildingId,
                  buildingDisplayName: reminder.buildingDisplayName,
                  scheduledDateTime: reminder.scheduledDateTime,
                  message: reminder.message,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearAllDialog(List<Reminder> reminders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Reminders'),
        content: Text(
          'Are you sure you want to delete all ${reminders.length} reminders?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllReminders(reminders);
            },
            child: Text(
              'CLEAR ALL',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllReminders(List<Reminder> reminders) async {
    try {
      for (final reminder in reminders) {
        await ref.read(reminderManagerProvider.notifier).cancelReminder(reminder);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleared ${reminders.length} reminders'),
            backgroundColor: AppColors.customGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
