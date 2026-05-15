import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Notification model for campus announcements
class CampusNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  CampusNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType {
  announcement,
  event,
  reminder,
  alert,
}

/// Provider for campus notifications (mock data for now)
final notificationsProvider = Provider<List<CampusNotification>>((ref) {
  return [
    CampusNotification(
      id: '1',
      title: 'Welcome to Uniuyo Town Campus',
      message: 'Use the navigation features to find your way around campus. Search for buildings, get directions, and discover study spaces.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.announcement,
    ),
    CampusNotification(
      id: '2',
      title: 'Campus Map Updated',
      message: 'The campus map has been updated with the latest building information and road layouts.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.announcement,
    ),
    CampusNotification(
      id: '3',
      title: 'Study Spaces Available',
      message: 'Check out the Study Space feature to find academic buildings and quiet places to study on campus.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.event,
    ),
    CampusNotification(
      id: '4',
      title: 'Navigation Tips',
      message: 'Tap on any building on the map to see its details. Use the "Get Directions" feature to plan your route.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.announcement,
    ),
  ];
});

/// Notifications page showing campus announcements and reminders
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showNotificationSettings,
            tooltip: 'Notification Settings',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Stats header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.colorPrimary.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
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
                        '${notifications.length} Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.colorPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // TODO: Mark all as read
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as read'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.customGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Notifications list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReminder,
        backgroundColor: AppColors.customGreen,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Set Reminder'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(CampusNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead ? Colors.grey[200]! : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showNotificationDetails(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on notification type
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.colorPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.alert:
        return Icons.warning;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.announcement:
        return AppColors.colorPrimary;
      case NotificationType.event:
        return AppColors.customGreen;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.alert:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showNotificationDetails(CampusNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _createReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_alarm, color: Colors.orange),
            SizedBox(width: 8),
            Text('Set Reminder'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create reminders for classes, events, or important locations on campus.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'This feature will be fully integrated in a future update.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 8),
            Text('Notification Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Campus Announcements', style: TextStyle(fontSize: 14)),
              value: true,
              onChanged: (value) {
                // TODO: Save preference
              },
              activeColor: AppColors.customGreen,
            ),
            SwitchListTile(
              title: const Text('Event Notifications', style: TextStyle(fontSize: 14)),
              value: true,
              onChanged: (value) {
                // TODO: Save preference
              },
              activeColor: AppColors.customGreen,
            ),
            SwitchListTile(
              title: const Text('Location Reminders', style: TextStyle(fontSize: 14)),
              value: true,
              onChanged: (value) {
                // TODO: Save preference
              },
              activeColor: AppColors.customGreen,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
