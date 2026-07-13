import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawffy/main.dart';
import 'package:pawffy/core/config/supabase_config.dart';
import 'package:pawffy/features/auth/providers/auth_controller.dart';
import 'package:pawffy/features/onboarding/screens/onboarding_flow_screen.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _acceptTerms = false;
  bool _otpSent = false;
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _otpError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Full name is required';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.\+\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
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

  bool _validateInitialInputs() {
    final nameErr = _validateName(_nameController.text);
    final emailErr = _validateEmail(_emailController.text.trim());
    final phoneErr = _validatePhone(_phoneController.text);

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
    });

    if (nameErr != null || emailErr != null || phoneErr != null) {
      return false;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the terms and conditions'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _handleSendOtp() async {
    if (!_validateInitialInputs()) return;

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();

    try {
      if (SupabaseConfig.useMockAuth) {
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
        if (SupabaseConfig.anonKey == 'YOUR_SUPABASE_ANON_KEY' ||
            SupabaseConfig.anonKey.isEmpty) {
          throw Exception(
            'Please configure your Supabase Anon Key in supabase_config.dart',
          );
        }
        await Supabase.instance.client.auth.signInWithOtp(phone: phone);
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

  Future<void> _handleVerifyAndRegister() async {
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
          accessToken = 'mock_access_token_supabase_session_register_2026';
        } else {
          throw Exception('Invalid OTP code. Use "123456"');
        }
      } else {
        if (SupabaseConfig.anonKey == 'YOUR_SUPABASE_ANON_KEY' ||
            SupabaseConfig.anonKey.isEmpty) {
          throw Exception(
            'Please configure your Supabase Anon Key in supabase_config.dart',
          );
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

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      final success = await ref
          .read(authControllerProvider.notifier)
          .register(
            name: name,
            email: email,
            accessToken: accessToken,
            acceptTerms: _acceptTerms,
          );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
        );
      } else {
        final authState = ref.read(authControllerProvider);
        final errorMsg = authState.hasError
            ? authState.error.toString().replaceFirst('Exception: ', '')
            : 'Registration failed';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.05),

                // Top Header Text
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CREATE',
                          style: GoogleFonts.archivoBlack(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'YOUR PARTNER ACCOUNT',
                          style: GoogleFonts.archivoBlack(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                // Full Name field
                _buildTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  errorText: _nameError,
                  isDark: isDark,
                  readOnly: _otpSent && !_isLoading,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(
                        () => _nameError = _validateName(_nameController.text),
                      );
                    }
                  },
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                ),
                const SizedBox(height: 14),

                // Email field
                _buildTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hint: 'Email Address',
                  icon: Icons.mail_outline,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                  readOnly: _otpSent && !_isLoading,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(
                        () =>
                            _emailError = _validateEmail(_emailController.text),
                      );
                    }
                  },
                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                ),
                const SizedBox(height: 14),

                // Phone field
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
                    onSubmitted: (_) => _handleVerifyAndRegister(),
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
                        'Change details?',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFFE85D04),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Terms Acceptance Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (_otpSent && !_isLoading)
                            ? null
                            : (val) => setState(() => _acceptTerms = val!),
                        activeColor: const Color(0xFFE85D04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFE85D04),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.barlow(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: GoogleFonts.barlow(
                                color: const Color(0xFFE85D04),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' & '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: GoogleFonts.barlow(
                                color: const Color(0xFFE85D04),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_otpSent ? _handleVerifyAndRegister : _handleSendOtp),
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
                              _otpSent ? 'VERIFY & REGISTER' : 'SEND OTP',
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
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: 'Log In',
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
          textInputAction: TextInputAction.next,
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
