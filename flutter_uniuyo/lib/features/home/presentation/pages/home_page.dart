import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../directions/presentation/pages/directions_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../study_space/presentation/pages/study_space_page.dart';
import '../../../feedback/presentation/pages/feedback_page.dart';
import '../../../campus_info/presentation/pages/campus_info_page.dart';
import '../../../report_issue/presentation/pages/report_issue_page.dart';
import '../widgets/feature_card_widget.dart';

/// Home page matching MainActivity.kt
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // From activity_main.xml: android:layout_weight="2"
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Image.asset(
                      'assets/images/header.jpeg',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.white,
                          child: Center(
                            child: Text(
                              'UNIUYO TOWN CAMPUS',
                              style: TextStyle(
                                color: AppColors.colorPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // From activity_main.xml: android:layout_weight="8"
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.gridPadding), // 14dp
              child: GridView.count(
                crossAxisCount: 2, // app:columnCount="2"
                mainAxisSpacing: AppDimensions.cardMarginBottom, // 16dp
                crossAxisSpacing: AppDimensions.cardMarginBottom,
                children: [
                  FeatureCardWidget(
                    title: 'Directions',
                    iconPath: 'assets/images/directions.png',
                    onTap: () => _navigateToDirections(context),
                  ),
                  FeatureCardWidget(
                    title: 'Search',
                    iconPath: 'assets/images/search.png',
                    onTap: () => _navigateToSearch(context),
                  ),
                  FeatureCardWidget(
                    title: 'Notifications',
                    iconPath: 'assets/images/notifications.png',
                    onTap: () => _navigateToNotifications(context),
                  ),
                  FeatureCardWidget(
                    title: 'Study Space',
                    iconPath: 'assets/images/study.png',
                    onTap: () => _navigateToStudySpace(context),
                  ),
                  FeatureCardWidget(
                    title: 'Report Issue',
                    iconPath: 'assets/images/feedback.png', // Reuse feedback icon
                    onTap: () => _navigateToReportIssue(context),
                  ),
                  FeatureCardWidget(
                    title: 'Feedback',
                    iconPath: 'assets/images/info.png',
                    onTap: () => _navigateToFeedback(context),
                  ),
                  FeatureCardWidget(
                    title: 'Campus Info',
                    iconPath: 'assets/images/study.png', // Reuse study icon
                    onTap: () => _navigateToCampusInfo(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDirections(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DirectionsPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SearchPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NotificationsPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToStudySpace(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const StudySpacePage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToReportIssue(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ReportIssuePage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FeedbackPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToCampusInfo(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CampusInfoPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
