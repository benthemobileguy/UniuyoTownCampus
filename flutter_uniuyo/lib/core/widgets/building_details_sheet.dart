import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/directions/domain/entities/building.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Professional Material 3 bottom sheet for building details
/// Inspired by UOB and modern campus apps
class BuildingDetailsSheet extends StatelessWidget {
  final Building building;
  final VoidCallback? onGetDirections;
  final VoidCallback? onSetReminder;
  final VoidCallback? onViewDetails;

  const BuildingDetailsSheet({
    super.key,
    required this.building,
    this.onGetDirections,
    this.onSetReminder,
    this.onViewDetails,
  });

  static void show(
    BuildContext context, {
    required Building building,
    VoidCallback? onGetDirections,
    VoidCallback? onSetReminder,
    VoidCallback? onViewDetails,
  }) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BuildingDetailsSheet(
        building: building,
        onGetDirections: onGetDirections,
        onSetReminder: onSetReminder,
        onViewDetails: onViewDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with icon and close button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getBuildingColor(building.buildingFunction).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      _getBuildingIcon(building.buildingFunction),
                      size: AppSpacing.iconLg,
                      color: _getBuildingColor(building.buildingFunction),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          building.buildingFunction,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Building information
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    icon: Icons.tag,
                    label: 'Building ID',
                    value: '#${building.gid}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    context,
                    icon: Icons.square_foot,
                    label: 'Area',
                    value: '${building.areaM2.toStringAsFixed(0)} m²',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    context,
                    icon: Icons.business,
                    label: 'Function',
                    value: building.buildingFunction,
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  // Get Directions - Primary action
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        onGetDirections?.call();
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Set Reminder - Secondary action
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        onSetReminder?.call();
                      },
                      icon: const Icon(Icons.notifications_outlined, size: 20),
                      label: const Text('Remind'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // More options
            if (onViewDetails != null)
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  onViewDetails?.call();
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View More Details'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  IconData _getBuildingIcon(String function) {
    final lowerFunction = function.toLowerCase();
    if (lowerFunction.contains('library')) return Icons.local_library;
    if (lowerFunction.contains('laboratory') || lowerFunction.contains('academic')) {
      return Icons.science;
    }
    if (lowerFunction.contains('lecture') || lowerFunction.contains('classroom')) {
      return Icons.school;
    }
    if (lowerFunction.contains('admin')) return Icons.business;
    if (lowerFunction.contains('cafeteria') || lowerFunction.contains('food')) {
      return Icons.restaurant;
    }
    if (lowerFunction.contains('hostel') || lowerFunction.contains('residential')) {
      return Icons.home;
    }
    if (lowerFunction.contains('sport')) return Icons.sports;
    if (lowerFunction.contains('medical') || lowerFunction.contains('health')) {
      return Icons.local_hospital;
    }
    return Icons.apartment;
  }

  Color _getBuildingColor(String function) {
    final lowerFunction = function.toLowerCase();
    if (lowerFunction.contains('library')) return AppColors.info;
    if (lowerFunction.contains('laboratory') || lowerFunction.contains('academic')) {
      return AppColors.secondary;
    }
    if (lowerFunction.contains('lecture') || lowerFunction.contains('classroom')) {
      return AppColors.primary;
    }
    if (lowerFunction.contains('admin')) return AppColors.tertiary;
    if (lowerFunction.contains('cafeteria') || lowerFunction.contains('food')) {
      return AppColors.warning;
    }
    if (lowerFunction.contains('hostel') || lowerFunction.contains('residential')) {
      return AppColors.success;
    }
    if (lowerFunction.contains('sport')) return AppColors.info;
    if (lowerFunction.contains('medical') || lowerFunction.contains('health')) {
      return AppColors.error;
    }
    return AppColors.textSecondary;
  }
}
