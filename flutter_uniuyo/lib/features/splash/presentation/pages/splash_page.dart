import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/pages/home_page.dart';

/// Splash screen page matching SplashActivity.kt
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // From fade_in_splash.xml: duration="3000"
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // From SplashActivity.kt: SPLASH_TIME_OUT = 8000L
    Future.delayed(const Duration(seconds: 8), _navigateToHome);
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionDuration: const Duration(milliseconds: 500), // From fade_in.xml
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // From activity_splash.xml: layout_width="180dp" layout_height="180dp"
            Center(
              child: Image.asset(
                'assets/images/logo_image.jpeg',
                width: 180,
                height: 180,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 180,
                    color: AppColors.customRed.withOpacity(0.1),
                    child: const Icon(
                      Icons.school,
                      size: 100,
                      color: AppColors.customRed,
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // From build.gradle: versionName "2.0"
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'v2.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.customRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
