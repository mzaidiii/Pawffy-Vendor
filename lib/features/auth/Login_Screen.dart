import 'package:flutter/gestures.dart';
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

class Country {
  final String name;
  final String code;
  final String dialCode;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          dialCode == other.dialCode;

  @override
  int get hashCode => code.hashCode ^ dialCode.hashCode;
}

const List<Country> _countries = [
  Country(name: 'United States', code: 'US', dialCode: '+1'),
  Country(name: 'United Kingdom', code: 'GB', dialCode: '+44'),
  Country(name: 'Canada', code: 'CA', dialCode: '+1'),
  Country(name: 'India', code: 'IN', dialCode: '+91'),
  Country(name: 'Australia', code: 'AU', dialCode: '+61'),
  Country(name: 'Afghanistan', code: 'AF', dialCode: '+93'),
  Country(name: 'Albania', code: 'AL', dialCode: '+355'),
  Country(name: 'Algeria', code: 'DZ', dialCode: '+213'),
  Country(name: 'Argentina', code: 'AR', dialCode: '+54'),
  Country(name: 'Austria', code: 'AT', dialCode: '+43'),
  Country(name: 'Bahrain', code: 'BH', dialCode: '+973'),
  Country(name: 'Bangladesh', code: 'BD', dialCode: '+880'),
  Country(name: 'Belgium', code: 'BE', dialCode: '+32'),
  Country(name: 'Brazil', code: 'BR', dialCode: '+55'),
  Country(name: 'Chile', code: 'CL', dialCode: '+56'),
  Country(name: 'China', code: 'CN', dialCode: '+86'),
  Country(name: 'Colombia', code: 'CO', dialCode: '+57'),
  Country(name: 'Czech Republic', code: 'CZ', dialCode: '+420'),
  Country(name: 'Denmark', code: 'DK', dialCode: '+45'),
  Country(name: 'Egypt', code: 'EG', dialCode: '+20'),
  Country(name: 'Finland', code: 'FI', dialCode: '+358'),
  Country(name: 'France', code: 'FR', dialCode: '+33'),
  Country(name: 'Germany', code: 'DE', dialCode: '+49'),
  Country(name: 'Greece', code: 'GR', dialCode: '+30'),
  Country(name: 'Hong Kong', code: 'HK', dialCode: '+852'),
  Country(name: 'Hungary', code: 'HU', dialCode: '+36'),
  Country(name: 'Indonesia', code: 'ID', dialCode: '+62'),
  Country(name: 'Ireland', code: 'IE', dialCode: '+353'),
  Country(name: 'Israel', code: 'IL', dialCode: '+972'),
  Country(name: 'Italy', code: 'IT', dialCode: '+39'),
  Country(name: 'Japan', code: 'JP', dialCode: '+81'),
  Country(name: 'Jordan', code: 'JO', dialCode: '+962'),
  Country(name: 'Kenya', code: 'KE', dialCode: '+254'),
  Country(name: 'Kuwait', code: 'KW', dialCode: '+965'),
  Country(name: 'Lebanon', code: 'LB', dialCode: '+961'),
  Country(name: 'Malaysia', code: 'MY', dialCode: '+60'),
  Country(name: 'Mexico', code: 'MX', dialCode: '+52'),
  Country(name: 'Morocco', code: 'MA', dialCode: '+212'),
  Country(name: 'Nepal', code: 'NP', dialCode: '+977'),
  Country(name: 'Netherlands', code: 'NL', dialCode: '+31'),
  Country(name: 'New Zealand', code: 'NZ', dialCode: '+64'),
  Country(name: 'Nigeria', code: 'NG', dialCode: '+234'),
  Country(name: 'Norway', code: 'NO', dialCode: '+47'),
  Country(name: 'Oman', code: 'OM', dialCode: '+968'),
  Country(name: 'Pakistan', code: 'PK', dialCode: '+92'),
  Country(name: 'Peru', code: 'PE', dialCode: '+51'),
  Country(name: 'Philippines', code: 'PH', dialCode: '+63'),
  Country(name: 'Poland', code: 'PL', dialCode: '+48'),
  Country(name: 'Portugal', code: 'PT', dialCode: '+351'),
  Country(name: 'Qatar', code: 'QA', dialCode: '+974'),
  Country(name: 'Romania', code: 'RO', dialCode: '+40'),
  Country(name: 'Russia', code: 'RU', dialCode: '+7'),
  Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966'),
  Country(name: 'Singapore', code: 'SG', dialCode: '+65'),
  Country(name: 'South Africa', code: 'ZA', dialCode: '+27'),
  Country(name: 'South Korea', code: 'KR', dialCode: '+82'),
  Country(name: 'Spain', code: 'ES', dialCode: '+34'),
  Country(name: 'Sri Lanka', code: 'LK', dialCode: '+94'),
  Country(name: 'Sweden', code: 'SE', dialCode: '+46'),
  Country(name: 'Switzerland', code: 'CH', dialCode: '+41'),
  Country(name: 'Taiwan', code: 'TW', dialCode: '+886'),
  Country(name: 'Thailand', code: 'TH', dialCode: '+66'),
  Country(name: 'Turkey', code: 'TR', dialCode: '+90'),
  Country(name: 'Ukraine', code: 'UA', dialCode: '+380'),
  Country(name: 'United Arab Emirates', code: 'AE', dialCode: '+971'),
  Country(name: 'Vietnam', code: 'VN', dialCode: '+84'),
];

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

  Country _selectedCountry = _countries.first;
  String _lastSentPhone = '';

  bool _otpSent = false;
  bool _isLoading = false;

  String? _phoneError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_onFocusChange);
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String _flag(String code) => code
      .toUpperCase()
      .codeUnits
      .map((c) => String.fromCharCode(0x1F1E6 + c - 65))
      .join();

  String _getFullPhoneNumber() {
    String text = _phoneController.text.trim();
    text = text.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (text.startsWith('+')) {
      return text;
    }
    if (text.startsWith('0')) {
      text = text.substring(1);
    }
    return '${_selectedCountry.dialCode}$text';
  }

  String? _validatePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.isEmpty) return 'Phone number is required';
    if (cleaned.startsWith('+')) {
      if (cleaned.length < 8) return 'Enter a valid phone number';
      return null;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Enter valid digits only';
    }
    if (cleaned.length < 6) return 'Phone number is too short';
    if (cleaned.length > 15) return 'Phone number is too long';
    return null;
  }

  String? _validateOtp(String value) {
    if (value.trim().isEmpty) return 'OTP code is required';
    if (value.trim().length != 6) return 'OTP must be 6 digits';
    return null;
  }

  void _showTermsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.archivoBlack(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'Please visit our website or contact support for full details regarding our $title.',
          style: GoogleFonts.barlow(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.barlow(
                color: const Color(0xFFE85D04),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    final error = _validatePhone(_phoneController.text.trim());
    setState(() => _phoneError = error);
    if (error != null) return;

    final fullPhone = _getFullPhoneNumber();

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
            _lastSentPhone = fullPhone;
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
        await Supabase.instance.client.auth.signInWithOtp(phone: fullPhone);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code sent to your phone!'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _lastSentPhone = fullPhone;
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
        if (SupabaseConfig.anonKey == 'YOUR_SUPABASE_ANON_KEY' ||
            SupabaseConfig.anonKey.isEmpty) {
          throw Exception(
            'Please configure your Supabase Anon Key in supabase_config.dart',
          );
        }
        final phone = _lastSentPhone.isNotEmpty
            ? _lastSentPhone
            : _getFullPhoneNumber();
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

                // Phone number field with country dropdown
                _buildPhoneField(
                  isDark: isDark,
                  readOnly: _otpSent && !_isLoading,
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
                          : () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _otpError = null;
                            }),
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
                    ).withValues(alpha: 0.6),
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

                // Terms + consent text (phone entry step only)
                if (!_otpSent) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.barlow(
                          fontSize: 12,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: GoogleFonts.barlow(
                              color: const Color(0xFFE85D04),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFFE85D04),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _showTermsDialog(context, 'Terms of Service'),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.barlow(
                              color: const Color(0xFFE85D04),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFFE85D04),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _showTermsDialog(context, 'Privacy Policy'),
                          ),
                          const TextSpan(
                            text:
                                '. You consent to receive SMS verification codes from ThePawffy. Message frequency varies. Message & data rates may apply.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

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

  Widget _buildPhoneField({required bool isDark, bool readOnly = false}) {
    final fillColor = isDark
        ? const Color(0xFF232323)
        : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _phoneError != null
                  ? Colors.redAccent
                  : (_phoneFocus.hasFocus
                        ? const Color(0xFFE85D04)
                        : Colors.transparent),
              width: _phoneError != null ? 1.2 : 1.5,
            ),
          ),
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Row(
            children: [
              // Country Code Dropdown (flag + dial code)
              DropdownButtonHideUnderline(
                child: DropdownButton<Country>(
                  value: _selectedCountry,
                  isDense: true,
                  dropdownColor: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(12),
                  menuMaxHeight: 350,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                  items: _countries.map((country) {
                    return DropdownMenuItem<Country>(
                      value: country,
                      child: Text(
                        '${_flag(country.code)}  ${country.dialCode}',
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: readOnly
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCountry = val);
                          }
                        },
                ),
              ),
              Container(
                height: 22,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              // Phone Input Field
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  readOnly: readOnly,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.barlow(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: GoogleFonts.barlow(
                      color: hintColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (_) {
                    if (_phoneError != null) {
                      setState(() {
                        _phoneError = _validatePhone(
                          _phoneController.text.trim(),
                        );
                      });
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
              ),
            ],
          ),
        ),
        if (_phoneError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _phoneError!,
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
