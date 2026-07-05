import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return 'Password must contain uppercase, lowercase, and a digit';
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'Confirm password is required';
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _validateAll() {
    final nameErr = _validateName(_nameController.text);
    final emailErr = _validateEmail(_emailController.text.trim());
    final passErr = _validatePassword(_passwordController.text);
    final confirmErr = _validateConfirmPassword(
      _confirmPasswordController.text,
    );

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
    });

    if (nameErr != null ||
        emailErr != null ||
        passErr != null ||
        confirmErr != null) {
      return false;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must accept the terms & conditions to register.',
            style: GoogleFonts.barlow(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _handleRegister() async {
    if (!_validateAll()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: name,
          email: email,
          password: password,
          acceptTerms: _acceptTerms,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
        (route) => false,
      );
    } else {
      final error = ref.read(authControllerProvider);
      final errorMsg = error.hasError
          ? error.error.toString().replaceFirst('Exception: ', '')
          : 'Registration failed';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.barlow()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authState = ref.watch(authControllerProvider);

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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.035),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CREATE',
                          style: GoogleFonts.archivoBlack(
                            fontSize: 45,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ACCOUNT!',
                          style: GoogleFonts.archivoBlack(
                            fontSize: 45,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                            color: const Color(0xFFE85D04),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Let's get started with your details",
                        style: GoogleFonts.barlow(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.045),

                _buildTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hint: 'Name',
                  icon: Icons.person_outline,
                  errorText: _nameError,
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

                _buildTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hint: 'Email Address',
                  icon: Icons.mail_outline,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(
                        () => _emailError = _validateEmail(
                          _emailController.text.trim(),
                        ),
                      );
                    }
                  },
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  errorText: _passwordError,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onObscureToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(
                        () => _passwordError = _validatePassword(
                          _passwordController.text,
                        ),
                      );
                    }
                  },
                  onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  errorText: _confirmPasswordError,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onObscureToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setState(
                        () => _confirmPasswordError = _validateConfirmPassword(
                          _confirmPasswordController.text,
                        ),
                      );
                    }
                  },
                  onSubmitted: (_) => _handleRegister(),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (val) {
                        setState(() {
                          _acceptTerms = val ?? false;
                        });
                      },
                      activeColor: const Color(0xFFE85D04),
                      side: const BorderSide(
                        color: Color(0xFFE85D04),
                        width: 1.5,
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.barlow(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: GoogleFonts.barlow(
                                color: const Color(0xFFE85D04),
                                fontSize: 14,
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

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: ElevatedButton(
                    key: ValueKey(authState.isLoading),
                    onPressed: authState.isLoading ? null : _handleRegister,
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
                    child: authState.isLoading
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
                                'SIGN UP',
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
                ),

                const SizedBox(height: 20),

                Text(
                  'Or Sign up With',
                  style: GoogleFonts.barlow(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 18),

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
                            text: 'Login',
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
    FocusNode? focusNode,
    String? errorText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onObscureToggle,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    const fillColor = Color(0xFF232323);
    const textColor = Colors.white;
    const hintColor = Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: focusNode != null && focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFFE85D04).withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword ? obscureText : false,
            keyboardType: keyboardType,
            textInputAction: isPassword
                ? TextInputAction.done
                : TextInputAction.next,
            style: GoogleFonts.barlow(color: textColor),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: () => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.barlow(
                color: hintColor,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: hintColor, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: hintColor,
                        size: 20,
                      ),
                      onPressed: onObscureToggle,
                    )
                  : null,
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: errorText != null
                    ? const BorderSide(color: Colors.redAccent, width: 1.2)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: errorText != null
                    ? const BorderSide(color: Colors.redAccent, width: 1.5)
                    : const BorderSide(color: Color(0xFFE85D04), width: 1.5),
              ),
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
