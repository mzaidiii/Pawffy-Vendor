import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawffy/features/auth/Onboarding_Screen.dart';
import 'package:pawffy/features/onboarding/providers/onboarding_provider.dart';
import 'package:pawffy/features/onboarding/screens/onboarding_flow_screen.dart';

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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = await ref.read(authControllerProvider.notifier).getMe();

      if (!mounted) return;

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

            if (!mounted) return;

            if (status == 'pending' || status == 'verified') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
              );
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
          );
        }
      } else {
        _goToOnboarding();
      }
    } catch (e) {
      if (!mounted) return;
      _goToOnboarding();
    }
  }

  void _goToOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Color(0xFFE85D04))),
    );
  }
}
