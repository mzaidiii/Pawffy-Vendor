import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/auth_provider.dart';
import 'package:pawffy/features/auth/providers/current_user_provider.dart';
import 'package:pawffy/core/Storage/storage_service.dart';

class ChangeContactScreen extends ConsumerStatefulWidget {
  final bool isPhone;

  const ChangeContactScreen({super.key, required this.isPhone});

  @override
  ConsumerState<ChangeContactScreen> createState() => _ChangeContactScreenState();
}

class _ChangeContactScreenState extends ConsumerState<ChangeContactScreen> {
  final _inputCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(); // Only for email updates

  // OTP inputs
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocuses = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _passwordCtrl.dispose();
    for (var ctrl in _otpCtrls) {
      ctrl.dispose();
    }
    for (var node in _otpFocuses) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final value = _inputCtrl.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isPhone ? 'Please enter a mobile number' : 'Please enter an email address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!widget.isPhone && _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password for verification'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final token = await StorageService.getToken();
    if (token == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      if (widget.isPhone) {
        await ref.read(authServiceProvider).requestPhoneChange(newPhone: value, token: token);
      } else {
        await ref.read(authServiceProvider).requestEmailChange(
              newEmail: value,
              password: _passwordCtrl.text.trim(),
              token: token,
            );
      }

      setState(() {
        _isOtpSent = true;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpCtrls.map((ctrl) => ctrl.text.trim()).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final token = await StorageService.getToken();
    if (token == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      String freshToken;
      if (widget.isPhone) {
        freshToken = await ref.read(authServiceProvider).verifyPhoneChange(
              newPhone: _inputCtrl.text.trim(),
              otp: otp,
              token: token,
            );
      } else {
        freshToken = await ref.read(authServiceProvider).verifyEmailChange(
              newEmail: _inputCtrl.text.trim(),
              verificationToken: otp,
              token: token,
            );
      }

      // Save fresh token
      await StorageService.saveToken(freshToken);

      // Refresh current user profile notifier
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isPhone ? 'Phone number updated successfully!' : 'Email address updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Pop back to settings screen
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.isPhone ? 'MOBILE NUMBER' : 'EMAIL ADDRESS';
    final label = widget.isPhone ? 'Mobile Number' : 'Email Address';
    final placeholder = widget.isPhone ? '+919467830645' : 'enter new email';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.white : AppColors.black,
            size: 20,
          ),
          onPressed: () {
            if (_isOtpSent) {
              setState(() => _isOtpSent = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          title,
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.white : AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Contact Change Visual Header
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0x15E85D04),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          widget.isPhone ? Icons.phone_iphone_outlined : Icons.mail_outline_rounded,
                          color: AppColors.orange,
                          size: 46,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isPhone ? 'Update your Mobile Number' : 'Update your Email Address',
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isPhone
                          ? 'We will send a verification code\nto your new number.'
                          : 'We will send a verification code\nto your new email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 36),

                    if (!_isOtpSent) ...[
                      // Input Form View
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLabel(label),
                      ),
                      TextField(
                        controller: _inputCtrl,
                        keyboardType: widget.isPhone ? TextInputType.phone : TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: placeholder,
                        ),
                      ),
                      if (!widget.isPhone) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildLabel('Current Password'),
                        ),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Enter password',
                          ),
                        ),
                      ],
                    ] else ...[
                      // OTP Digit Verification View
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildLabel('Enter OTP'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 46,
                            height: 52,
                            child: TextField(
                              controller: _otpCtrls[index],
                              focusNode: _otpFocuses[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  if (index < 5) {
                                    _otpFocuses[index + 1].requestFocus();
                                  } else {
                                    _otpFocuses[index].unfocus();
                                  }
                                } else {
                                  if (index > 0) {
                                    _otpFocuses[index - 1].requestFocus();
                                  }
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : (_isOtpSent ? _handleVerifyOtp : _handleSendOtp),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isOtpSent ? 'SEND OTP' : 'SEND OTP'), // matching mockup text 'SEND OTP'
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}
