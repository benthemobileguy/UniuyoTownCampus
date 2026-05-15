import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// UOB-style route summary card showing distance, time, and route type
/// Displays prominently like UOB's green pill design
class RouteSummaryCard extends StatelessWidget {
  final double distanceMeters;
  final int durationMinutes;
  final String routeType;
  final VoidCallback? onStartNavigation;
  final bool isLoading;

  const RouteSummaryCard({
    super.key,
    required this.distanceMeters,
    required this.durationMinutes,
    this.routeType = 'Shortest',
    this.onStartNavigation,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // UOB-style bright green banner pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5A0), // Bright turquoise like UOB
                  const Color(0xFF00D094),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5A0).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Stages
                Text(
                  '1 Stage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // Divider
                Container(
                  height: 20,
                  width: 2,
                  color: AppColors.white.withOpacity(0.5),
                ),

                // Distance and Duration
                Text(
                  '${_formatDistance(distanceMeters)} ($durationMinutes mins)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // Divider
                Container(
                  height: 20,
                  width: 2,
                  color: AppColors.white.withOpacity(0.5),
                ),

                // Route type
                Text(
                  routeType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Start Route Button (UOB purple style)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onStartNavigation,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B4C7D), // UOB purple
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Start Route',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Compact version for list display
class CompactRouteSummary extends StatelessWidget {
  final double distanceMeters;
  final int durationMinutes;
  final String routeType;
  final bool isSelected;
  final VoidCallback? onTap;

  const CompactRouteSummary({
    super.key,
    required this.distanceMeters,
    required this.durationMinutes,
    this.routeType = 'Shortest',
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$durationMinutes min',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                ),
              ],
            ),
            Text(
              _formatDistance(distanceMeters),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  routeType,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              )
            else
              Text(
                routeType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}
