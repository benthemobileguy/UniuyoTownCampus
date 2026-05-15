import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Feature card widget matching CardView from activity_main.xml
class FeatureCardWidget extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  const FeatureCardWidget({
    super.key,
    required this.title,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // From activity_main.xml: app:cardElevation="8dp"
      elevation: AppDimensions.cardElevation,
      // From activity_main.xml: app:cardCornerRadius="8dp"
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardCornerRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardCornerRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // From activity_main.xml: layout_width="30dp"
              Image.asset(
                iconPath,
                width: AppDimensions.featureIconSize,
                height: AppDimensions.featureIconSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error_outline,
                    size: AppDimensions.featureIconSize,
                    color: AppColors.customRed,
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppDimensions.textSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.customTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
