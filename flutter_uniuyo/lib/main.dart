import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/search/presentation/pages/search_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // From bools.xml: portrait_only=true
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification service for building reminders
  final notificationService = NotificationService();
  await notificationService.initialize(
    onNotificationTapped: (buildingId) {
      // Navigate to SearchPage with building pre-selected
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => SearchPage(
            initialBuildingName: buildingId,
          ),
        ),
      );
    },
  );

  runApp(const ProviderScope(child: UniuyoTownCampusApp()));
}

class UniuyoTownCampusApp extends StatelessWidget {
  const UniuyoTownCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // For notification navigation
      title: 'Uniuyo Town Campus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashPage(),
    );
  }
}
