import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/auth_provider.dart';
import 'package:pawffy/core/Storage/storage_service.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _hasLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _newPasswordCtrl.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _newPasswordCtrl.removeListener(_validatePassword);
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final text = _newPasswordCtrl.text;
    setState(() {
      _hasLength = text.length >= 8;
      _hasNumber = text.contains(RegExp(r'[0-9]'));
      _hasUppercase = text.contains(RegExp(r'[A-Z]'));
    });
  }

  Future<void> _handleSubmit() async {
    final current = _currentPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!_hasLength || !_hasNumber || !_hasUppercase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password does not meet complexity requirements'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
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
      final freshToken = await ref.read(authServiceProvider).changePassword(
            currentPassword: current,
            newPassword: newPass,
            token: token,
          );

      await StorageService.saveToken(freshToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CHANGE PASSWORD',
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
                    const SizedBox(height: 10),
                    // Shield Lock Icon block
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0x15E85D04),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_outlined, color: AppColors.orange, size: 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose a strong password to\nKeep your account secure',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Current Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildLabel('Current Password'),
                    ),
                    TextField(
                      controller: _currentPasswordCtrl,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        hintText: 'Enter current password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.grey,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildLabel('New Password'),
                    ),
                    TextField(
                      controller: _newPasswordCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.grey,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Validation checklist
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        children: [
                          _buildCheckItem('At least 8 Character', _hasLength),
                          const SizedBox(height: 6),
                          _buildCheckItem('Include a number', _hasNumber),
                          const SizedBox(height: 6),
                          _buildCheckItem('Includes an Upper Case', _hasUppercase),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildLabel('Confirm Password'),
                    ),
                    TextField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.grey,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
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
                  onPressed: _isProcessing ? null : _handleSubmit,
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('UPDATE PASSWORD'),
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

  Widget _buildCheckItem(String text, bool completed) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.circle_outlined,
          color: completed ? AppColors.success : AppColors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: completed ? AppColors.success : AppColors.grey,
            fontWeight: completed ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
