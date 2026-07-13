import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/current_user_provider.dart';
import 'package:pawffy/features/auth/providers/auth_provider.dart';
import 'package:pawffy/core/Storage/storage_service.dart';
import 'package:pawffy/core/utils/image_picker_helper.dart';
import 'package:pawffy/features/profile/providers/profile_controller.dart';

// Settings sub-screens
import 'personal_information_screen.dart';
import 'change_password_screen.dart';
import 'change_contact_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final themeMode = ref.watch(themeModeProvider);

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
          'SETTINGS',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- VENDOR OVERVIEW HUB ---
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final source = await ImagePickerHelper.showSourceBottomSheet(context);
                        if (source != null) {
                          final file = await ImagePickerHelper.pickImageWithPermission(
                            context: context,
                            source: source,
                          );
                          if (file != null) {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Uploading avatar...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              await ref.read(profileControllerProvider.notifier).uploadAvatar(file.path);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Avatar updated successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to upload avatar: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE0E0E0),
                              border: Border.all(
                                color: AppColors.orange,
                                width: 2,
                              ),
                              image:
                                  user?.profileImage != null &&
                                      user!.profileImage!.isNotEmpty
                                  ? DecorationImage(
                                      image: ImagePickerHelper.getImageProvider(
                                        user.profileImage!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                user?.profileImage == null ||
                                    user!.profileImage!.isEmpty
                                ? const Icon(
                                    Icons.person_outline,
                                    color: Colors.grey,
                                    size: 40,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'Aman Patel',
                      style: GoogleFonts.barlow(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'amanpatel@gmail.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      user?.phone ?? '+919652949690',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- ACCOUNTS SECTION ---
              _buildSectionTitle('Accounts'),
              const SizedBox(height: 8),
              _buildSettingCard(
                context,
                isDark,
                items: [
                  _buildSettingTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    subtitle: 'Update your personal information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInformationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.phone_android_outlined,
                    title: 'Mobile Number',
                    subtitle: 'Update your mobile number',
                    trailing: Text(
                      user?.phone ?? '+919434853589',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ChangeContactScreen(isPhone: true),
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.mail_outline_rounded,
                    title: 'Email Address',
                    subtitle: 'Update your email address',
                    trailing: Text(
                      user?.email ?? 'ankita.sharma@gmail.com',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ChangeContactScreen(isPhone: false),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- PREFERENCES SECTION ---
              _buildSectionTitle('Preferences'),
              const SizedBox(height: 8),
              _buildSettingCard(
                context,
                isDark,
                items: [
                  _buildSettingTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage your notification preferences',
                    onTap: () => _showNotificationsDialog(context),
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'App Appearance',
                    subtitle: 'Choose between light and dark themes',
                    trailing: Text(
                      themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- SUPPORT & MORE SECTION ---
              _buildSectionTitle('Support & More'),
              const SizedBox(height: 8),
              _buildSettingCard(
                context,
                isDark,
                items: [
                  _buildSettingTile(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help and Support',
                    subtitle: 'Get help and contact support',
                    onTap: () => _showHelpSupportDialog(context),
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'Read our terms and conditions',
                    onTap: () => _showStaticContentScreen(
                      context,
                      'Terms & Conditions',
                      termsContentProvider,
                      _termsContent,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.security_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Learn how we protect your data',
                    onTap: () => _showStaticContentScreen(
                      context,
                      'Privacy Policy',
                      privacyContentProvider,
                      _privacyContent,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'About PawCare',
                    subtitle: 'App version 1.0.0',
                    onTap: () {},
                  ),
                  _buildDivider(isDark),
                  _buildSettingTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    titleColor: AppColors.error,
                    iconColor: AppColors.error,
                    subtitle: 'Sign out of your account',
                    onTap: () async {
                      // Perform Logout
                      final token = await StorageService.getToken();
                      if (token != null) {
                        try {
                          await ref.read(authServiceProvider).logout(token);
                        } catch (_) {}
                      }
                      await StorageService.clearAll();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.barlow(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.orange,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.barlow(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: titleColor ?? (isDark ? Colors.white : Colors.black),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white54 : Colors.grey.shade500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[trailing, const SizedBox(width: 6)],
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 60,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
    );
  }

  // Dialog triggers
  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final prefsAsync = ref.watch(notificationPreferencesProvider);

          return AlertDialog(
            title: const Text('Notification Preferences'),
            content: prefsAsync.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              ),
              error: (e, stack) => SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'Failed to load preferences: $e',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
              data: (prefs) {
                bool pushRequests = prefs['pushRequests'] ?? false;
                bool pushMessages = prefs['pushMessages'] ?? false;
                bool smsAlerts = prefs['smsAlerts'] ?? false;
                bool emailMarketing = prefs['emailMarketing'] ?? false;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Push Requests'),
                      value: pushRequests,
                      activeColor: AppColors.orange,
                      onChanged: (val) async {
                        if (val != null) {
                          try {
                            await ref
                                .read(notificationPreferencesProvider.notifier)
                                .updatePreferences(
                                  pushRequests: val,
                                  pushMessages: pushMessages,
                                  emailMarketing: emailMarketing,
                                  smsAlerts: smsAlerts,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Push Messages'),
                      value: pushMessages,
                      activeColor: AppColors.orange,
                      onChanged: (val) async {
                        if (val != null) {
                          try {
                            await ref
                                .read(notificationPreferencesProvider.notifier)
                                .updatePreferences(
                                  pushRequests: pushRequests,
                                  pushMessages: val,
                                  emailMarketing: emailMarketing,
                                  smsAlerts: smsAlerts,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('SMS Alerts'),
                      value: smsAlerts,
                      activeColor: AppColors.orange,
                      onChanged: (val) async {
                        if (val != null) {
                          try {
                            await ref
                                .read(notificationPreferencesProvider.notifier)
                                .updatePreferences(
                                  pushRequests: pushRequests,
                                  pushMessages: pushMessages,
                                  emailMarketing: emailMarketing,
                                  smsAlerts: val,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Email Marketing'),
                      value: emailMarketing,
                      activeColor: AppColors.orange,
                      onChanged: (val) async {
                        if (val != null) {
                          try {
                            await ref
                                .read(notificationPreferencesProvider.notifier)
                                .updatePreferences(
                                  pushRequests: pushRequests,
                                  pushMessages: pushMessages,
                                  emailMarketing: val,
                                  smsAlerts: smsAlerts,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedCategory = 'technical_issue';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: isSubmitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => selectedCategory = val);
                        }
                      },
                items: const [
                  DropdownMenuItem(
                    value: 'technical_issue',
                    child: Text('Technical Issue'),
                  ),
                  DropdownMenuItem(
                    value: 'billing',
                    child: Text('Billing & Payments'),
                  ),
                  DropdownMenuItem(
                    value: 'general',
                    child: Text('General Inquiry'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectCtrl,
                enabled: !isSubmitting,
                decoration: const InputDecoration(hintText: 'Subject'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                enabled: !isSubmitting,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe your issue...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            Consumer(
              builder: (context, ref, child) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  minimumSize: const Size(80, 36),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (subjectCtrl.text.trim().isEmpty ||
                            bodyCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill out all fields.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setState(() => isSubmitting = true);
                        try {
                          await ref
                              .read(profileServiceProvider)
                              .createSupportTicket(
                                subject: subjectCtrl.text,
                                category: selectedCategory,
                                description: bodyCtrl.text,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Support ticket submitted successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to submit ticket: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          setState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('SUBMIT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStaticContentScreen(
    BuildContext context,
    String title,
    FutureProvider<String> provider,
    String fallbackContent,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final contentAsync = ref.watch(provider);
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: SafeArea(
                child: contentAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                  error: (err, stack) => SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Offline Mode: Displaying cached document.',
                                style: GoogleFonts.barlow(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fallbackContent,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  data: (content) => SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      content.isNotEmpty ? content : fallbackContent,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Mocks of T&C / Privacy policies
  static const String _termsContent = '''
PAWCARE TERMS AND CONDITIONS
Last Updated: July 2026

Welcome to PawCare. Please read these terms carefully before joining our platform.
1. Relationship: By registering as a vendor partner, you acknowledge you are an independent provider of veterinary, grooming, training, or walking services.
2. Booking: You accept that bookings are requested by registered pet owners on the platform and you agree to execute them according to best professional practices.
3. Verification: You agree to upload valid documentation (licenses, certifications). PawCare holds the right to reject/deactivate accounts that violate terms.
''';

  static const String _privacyContent = '''
PAWCARE PRIVACY POLICY
Last Updated: July 2026

Your privacy matters to us. We process your data to:
1. Identify your provider status and business credentials.
2. Coordinate location coordinates for real-time dog walking live trackers.
3. Facilitate communication logs in chats.
All data is stored securely using industry-standard encryptions. We do not sell user data.
''';
}
