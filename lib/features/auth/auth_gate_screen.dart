import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawffy/features/auth/Onboarding_Screen.dart';
import 'package:pawffy/features/onboarding/providers/onboarding_provider.dart';
import 'package:pawffy/features/onboarding/screens/onboarding_flow_screen.dart';
import 'package:pawffy/features/auth/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../home/home_screen.dart';
import 'providers/auth_controller.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    // Remove the native splash screen after the first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final startTime = DateTime.now();
    Widget nextScreen;

    try {
      final user = await ref.read(authControllerProvider.notifier).getMe();

      if (user != null) {
        final onboardingService = ref.read(onboardingServiceProvider);

        try {
          final res = await onboardingService.getOnboardingState();
          final success = res['success'] as bool? ?? false;

          if (success && res['data'] != null) {
            final data = res['data'] as Map<String, dynamic>;
            final business = data['business'] as Map<String, dynamic>?;
            final status =
                business?['verificationStatus']?.toString() ?? 'draft';

            if (status == 'pending' || status == 'verified') {
              nextScreen = const HomeScreen();
            } else {
              nextScreen = const OnboardingFlowScreen();
            }
          } else {
            nextScreen = const OnboardingFlowScreen();
          }
        } catch (e) {
          nextScreen = const OnboardingFlowScreen();
        }
      } else {
        nextScreen = const OnboardingScreen();
      }
    } catch (e) {
      nextScreen = const OnboardingScreen();
    }

    // Ensure the splash screen is displayed for at least 2 seconds
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
