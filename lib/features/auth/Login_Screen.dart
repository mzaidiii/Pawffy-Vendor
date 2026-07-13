import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawffy/main.dart';
import 'package:pawffy/core/config/supabase_config.dart';
import 'package:pawffy/features/auth/providers/auth_controller.dart';
import 'package:pawffy/features/auth/create_account_screen.dart';
import 'package:pawffy/features/onboarding/screens/onboarding_flow_screen.dart';
import 'package:pawffy/features/onboarding/providers/onboarding_provider.dart';
import 'package:pawffy/features/home/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _isLoading = false;

  String? _phoneError;
  String? _otpError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String? _validatePhone(String value) {
    if (value.trim().isEmpty) return 'Phone number is required';
    if (!value.startsWith('+'))
      return 'Must start with + and country code (e.g. +1)';
    if (value.length < 10) return 'Enter a valid phone number';
    return null;
  }

  String? _validateOtp(String value) {
    if (value.trim().isEmpty) return 'OTP code is required';
    if (value.trim().length != 6) return 'OTP must be 6 digits';
    return null;
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    final error = _validatePhone(phone);
    setState(() => _phoneError = error);
    if (error != null) return;

    setState(() => _isLoading = true);

    try {
      if (SupabaseConfig.useMockAuth) {
        // Simulated send
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mock OTP Code "123456" sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _otpSent = true;
            _isLoading = false;
          });
          _otpFocus.requestFocus();
        }
      } else {
        if (SupabaseConfig.anonKey == 'YOUR_SUPABASE_ANON_KEY' || SupabaseConfig.anonKey.isEmpty) {
          throw Exception('Please configure your Supabase Anon Key in supabase_config.dart');
        }
        await Supabase.instance.client.auth.signInWithOtp(
          phone: phone,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your phone!'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _otpSent = true;
            _isLoading = false;
          });
          _otpFocus.requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyAndLogin() async {
    final otp = _otpController.text.trim();
    final error = _validateOtp(otp);
    setState(() => _otpError = error);
    if (error != null) return;

    setState(() => _isLoading = true);

    try {
      String? accessToken;

      if (SupabaseConfig.useMockAuth) {
        await Future.delayed(const Duration(seconds: 1));
        if (otp == '123456') {
          accessToken = 'mock_access_token_supabase_session_login_2026';
        } else {
          throw Exception('Invalid OTP code. Use "123456"');
        }
      } else {
        if (SupabaseConfig.anonKey == 'YOUR_SUPABASE_ANON_KEY' || SupabaseConfig.anonKey.isEmpty) {
          throw Exception('Please configure your Supabase Anon Key in supabase_config.dart');
        }
        final phone = _phoneController.text.trim();
        final response = await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.sms,
          phone: phone,
          token: otp,
        );
        accessToken = response.session?.accessToken;
        if (accessToken == null) {
          throw Exception(
            'Verification succeeded but no session token was found.',
          );
        }
      }

      final success = await ref
          .read(authControllerProvider.notifier)
          .login(accessToken: accessToken);

      if (!mounted) return;

      if (success) {
        final onboardingService = ref.read(onboardingServiceProvider);
        try {
          final res = await onboardingService.getOnboardingState();
          final ok = res['success'] as bool? ?? false;

          if (ok && res['data'] != null) {
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
        final authState = ref.read(authControllerProvider);
        final errorMsg = authState.hasError
            ? authState.error.toString().replaceFirst('Exception: ', '')
            : 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.12),

                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'HELLO,',
                              style: GoogleFonts.archivoBlack(
                                fontSize: 52,
                                fontWeight: FontWeight.w400,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'android/assets/LoginDog.png',
                                width: 102,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 105,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE85D04),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'WELCOME BACK!',
                          style: GoogleFonts.archivoBlack(
                            fontSize: 35,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.08),

                // Phone number field
                _buildTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  hint: 'Phone Number (e.g. +15551234567)',
                  icon: Icons.phone,
                  errorText: _phoneError,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                  readOnly: _otpSent && !_isLoading,
                  onChanged: (_) {
                    if (_phoneError != null) {
                      setState(
                        () =>
                            _phoneError = _validatePhone(_phoneController.text),
                      );
                    }
                  },
                  onSubmitted: (_) {
                    if (!_otpSent) {
                      _handleSendOtp();
                    } else {
                      _otpFocus.requestFocus();
                    }
                  },
                ),
                const SizedBox(height: 14),

                // OTP verification code field (revealed once OTP is sent)
                if (_otpSent) ...[
                  _buildTextField(
                    controller: _otpController,
                    focusNode: _otpFocus,
                    hint: '6-digit Verification Code',
                    icon: Icons.lock_outline,
                    errorText: _otpError,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    onChanged: (_) {
                      if (_otpError != null) {
                        setState(
                          () => _otpError = _validateOtp(_otpController.text),
                        );
                      }
                    },
                    onSubmitted: (_) => _handleVerifyAndLogin(),
                  ),
                  const SizedBox(height: 14),
                ],

                if (_otpSent)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () => setState(() => _otpSent = false),
                      child: Text(
                        'Change phone number?',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFFE85D04),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _handleVerifyAndLogin : _handleSendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE85D04),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFFE85D04,
                    ).withOpacity(0.6),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _otpSent ? 'VERIFY & LOGIN' : 'SEND OTP',
                              style: GoogleFonts.barlow(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_outward, size: 18),
                          ],
                        ),
                ),
                const SizedBox(height: 22),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateAccountScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: 'Create account',
                            style: GoogleFonts.barlow(
                              color: const Color(0xFFE85D04),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    FocusNode? focusNode,
    String? errorText,
    bool readOnly = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final fillColor = isDark
        ? const Color(0xFF232323)
        : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.barlow(color: textColor),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.barlow(
              color: hintColor,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: hintColor, size: 20),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.redAccent, width: 1.2)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : const BorderSide(color: Color(0xFFE85D04), width: 1.5),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: GoogleFonts.barlow(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
