import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawffy/features/auth/providers/current{_user_provider.dart';

import 'package:pawffy/core/utils/image_picker_helper.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MY PROFILE',
                      style: GoogleFonts.barlow(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Notification bell (already wired in home, can keep placeholder)
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE85D04),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Profile Info (Dynamic)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFE0E0E0),
                              border: Border.all(
                                color: const Color(0xFFE85D04),
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
                                    size: 36,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE85D04),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: userAsync.when(
                                  data: (user) => Text(
                                    user?.name ?? 'Pet Parent',
                                    style: GoogleFonts.barlow(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  loading: () => const Text('Loading...'),
                                  error: (_, __) => const Text('Pet Parent'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE85D04,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE85D04,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        size: 12,
                                        color: Color(0xFFE85D04),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Edit Profile',
                                        style: GoogleFonts.barlow(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFE85D04),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          userAsync.when(
                            data: (user) => Text(
                              user?.email ?? '',
                              style: GoogleFonts.barlow(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF888888),
                              ),
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                          // Add phone/location if available later
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // === MY PETS SECTION ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Pets',
                      style: GoogleFonts.barlow(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'See All',
                        style: GoogleFonts.barlow(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE85D04),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.calendar_today_outlined,
                        title: 'My Bookings',
                        subtitle: 'View your upcoming and past bookings',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.credit_card_outlined,
                        title: 'Payments and Wallets',
                        subtitle: 'Manage payments and refunds',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.location_on_outlined,
                        title: 'Addresses',
                        subtitle: 'Manage your saved addresses',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Notification, Privacy and more',
                        onTap: () {},
                        showDivider: true,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.headset_mic_outlined,
                        title: 'Help and Support',
                        subtitle: 'Get help and contact support',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Keep your existing _buildMenuItem method unchanged
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    required bool showDivider,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white60 : const Color(0xFF888888),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 70, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}
