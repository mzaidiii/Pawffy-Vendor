import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/current{_user_provider.dart';
import 'package:pawffy/features/profile/data/models/vendor_profile_model.dart';
import 'package:pawffy/features/profile/providers/profile_controller.dart';
import 'package:pawffy/core/utils/image_picker_helper.dart';
import 'package:pawffy/features/profile/setting/settings_screen.dart';
import 'package:pawffy/features/profile/setting/personal_information_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _selectedPeriod = 'month';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;

    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(profileControllerProvider.notifier).refresh();
          },
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
            error: (e, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile details',
                    style: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                    onPressed: () => ref.read(profileControllerProvider.notifier).refresh(),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            data: (profileData) {
              final isVerified = profileData.applicationStatus.isVerified;
              final appStatusLabel = profileData.applicationStatus.label;
              final appStatusMsg = profileData.applicationStatus.message;

              // Stats
              final bookingsCount = profileData.performance.totalBookings.count;
              final bookingsChange = profileData.performance.totalBookings.changePercent;
              final earningsDisplay = profileData.performance.totalEarning.display;
              final earningsChange = profileData.performance.totalEarning.changePercent;
              final ratingAverage = profileData.performance.rating.average;
              final ratingReviews = profileData.performance.rating.reviewCount;
              final repeatPercent = profileData.performance.repeatClients.percent;
              final repeatChange = profileData.performance.repeatClients.changePercent;

              // Info
              final name = profileData.profile.name;
              final title = profileData.profile.title ?? 'Pet Care Specialist';
              final phone = profileData.profile.phone ?? user?.phone ?? '';
              final location = profileData.profile.location ?? 'Delhi, India';

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Row(
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
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
                            Stack(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                if (profileData.unreadNotifications > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.orange,
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
                    const SizedBox(height: 24),

                    // --- USER PROFILE INFO BLOCK ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                                border: Border.all(color: AppColors.orange, width: 2),
                                image: profileData.profile.profileImage != null && profileData.profile.profileImage!.isNotEmpty
                                    ? DecorationImage(
                                        image: ImagePickerHelper.getImageProvider(profileData.profile.profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : (user?.profileImage != null && user!.profileImage!.isNotEmpty
                                        ? DecorationImage(
                                            image: ImagePickerHelper.getImageProvider(user.profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: (profileData.profile.profileImage == null || profileData.profile.profileImage!.isEmpty) &&
                                      (user?.profileImage == null || user!.profileImage!.isEmpty)
                                  ? const Icon(Icons.person_outline, color: Colors.grey, size: 36)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
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
                                    child: Text(
                                      name.isNotEmpty ? name : (user?.name ?? 'Amit Patel'),
                                      style: GoogleFonts.barlow(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const PersonalInformationScreen()),
                                      );
                                      ref.read(profileControllerProvider.notifier).refresh();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.orange),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.edit, size: 10, color: AppColors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Edit Profile',
                                            style: GoogleFonts.barlow(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- APPLICATION STATUS CARD (HIDDEN IF VERIFIED) ---
                    if (!isVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.orange, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.hourglass_empty,
                                    color: AppColors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Application Status',
                                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                                      ),
                                      Text(
                                        appStatusLabel,
                                        style: GoogleFonts.barlow(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              appStatusMsg,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening onboarding status details...')),
                                );
                              },
                              child: Text(
                                'View Details',
                                style: GoogleFonts.barlow(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- PRO MEMBER CARD ---
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profileData.membership.label.isNotEmpty ? profileData.membership.label : 'Free Member',
                                  style: GoogleFonts.barlow(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  profileData.membership.validTill != null
                                      ? 'Valid till ${profileData.membership.validTill}'
                                      : 'No expiration date',
                                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange.withOpacity(0.1),
                              foregroundColor: AppColors.orange,
                              elevation: 0,
                              minimumSize: const Size(100, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {},
                            child: Row(
                              children: [
                                Text(
                                  'View Benefits',
                                  style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_outward, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- PERFORMANCE OVERVIEW SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PERFORMANCE OVERVIEW',
                          style: GoogleFonts.barlow(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                        PopupMenuButton<String>(
                          initialValue: _selectedPeriod,
                          onSelected: (String period) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                            ref.read(profileControllerProvider.notifier).changePeriod(period);
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'week',
                              child: Text('This Week'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'month',
                              child: Text('This Month'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'year',
                              child: Text('This Year'),
                            ),
                          ],
                          child: Row(
                            children: [
                              Text(
                                _selectedPeriod == 'week'
                                    ? 'This Week'
                                    : (_selectedPeriod == 'year' ? 'This Year' : 'This Month'),
                                style: GoogleFonts.barlow(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.grey.shade700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.72,
                      children: [
                        _buildMetricCard(
                          context,
                          isDark,
                          icon: Icons.calendar_today_outlined,
                          iconBg: Colors.green.withOpacity(0.12),
                          iconColor: Colors.green,
                          value: bookingsCount.toString(),
                          label: 'Total Bookings',
                          trend: '${bookingsChange >= 0 ? "↑" : "↓"} ${bookingsChange.abs().toStringAsFixed(0)}%',
                          trendColor: bookingsChange >= 0 ? Colors.green : Colors.red,
                        ),
                        _buildMetricCard(
                          context,
                          isDark,
                          icon: Icons.attach_money_rounded,
                          iconBg: Colors.purple.withOpacity(0.12),
                          iconColor: Colors.purple,
                          value: earningsDisplay,
                          label: 'Total Earning',
                          trend: '${earningsChange >= 0 ? "↑" : "↓"} ${earningsChange.abs().toStringAsFixed(0)}%',
                          trendColor: earningsChange >= 0 ? Colors.green : Colors.red,
                        ),
                        _buildRatingMetricCard(
                          context,
                          isDark,
                          averageRating: ratingAverage,
                          reviewsCount: ratingReviews,
                        ),
                        _buildMetricCard(
                          context,
                          isDark,
                          icon: Icons.person_outline_rounded,
                          iconBg: Colors.blue.withOpacity(0.12),
                          iconColor: Colors.blue,
                          value: '${repeatPercent.toStringAsFixed(0)}%',
                          label: 'Repeat Clients',
                          trend: '${repeatChange >= 0 ? "↑" : "↓"} ${repeatChange.abs().toStringAsFixed(0)}%',
                          trendColor: repeatChange >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- MY SERVICES SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MY SERVICES',
                          style: GoogleFonts.barlow(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAddServiceDialog(context),
                          child: Row(
                            children: [
                              Text(
                                'Add New',
                                style: GoogleFonts.barlow(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                              const Icon(Icons.add, size: 14, color: AppColors.orange),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: profileData.services.length + 1,
                        itemBuilder: (context, index) {
                          if (index == profileData.services.length) {
                            return GestureDetector(
                              onTap: () => _showAddServiceDialog(context),
                              child: _buildAddServiceCard(isDark),
                            );
                          }
                          final service = profileData.services[index];
                          return GestureDetector(
                            onTap: () => _showEditServiceDialog(context, service),
                            child: _buildServiceCard(
                              isDark,
                              icon: _getServiceIcon(service.serviceType),
                              name: service.name,
                              desc: service.description,
                              price: service.priceDisplay,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- ACTIONS MENU BOX ---
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                          width: 1,
                        ),
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                            showDivider: true,
                          ),
                          _buildMenuItem(
                            context,
                            icon: Icons.headset_mic_outlined,
                            title: 'Help and Support',
                            subtitle: 'Get help and contact support',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening Support ticket page...')),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'groomer':
        return Icons.cut_outlined;
      case 'vet':
        return Icons.local_hospital_outlined;
      case 'walker':
        return Icons.directions_walk_outlined;
      case 'trainer':
        return Icons.sports_soccer_outlined;
      case 'sitter':
        return Icons.home_outlined;
      case 'boarding':
        return Icons.hotel_outlined;
      default:
        return Icons.work_outline;
    }
  }

  Widget _buildMetricCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.barlow(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(fontSize: 8, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: TextStyle(fontSize: 8, color: trendColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingMetricCard(
    BuildContext context,
    bool isDark, {
    required double averageRating,
    required int reviewsCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: AppColors.orange, size: 14),
          ),
          const Spacer(),
          Text(
            averageRating.toStringAsFixed(1),
            style: GoogleFonts.barlow(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Text(
            'Rating',
            style: TextStyle(fontSize: 8, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 8),
              const SizedBox(width: 2),
              Text(
                '($reviewsCount)',
                style: const TextStyle(fontSize: 7, color: AppColors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    bool isDark, {
    required IconData icon,
    required String name,
    required String desc,
    required String price,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange, size: 18),
          const Spacer(),
          Text(
            name,
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            desc,
            style: const TextStyle(fontSize: 8, color: AppColors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddServiceCard(bool isDark) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: AppColors.orange, size: 24),
          SizedBox(height: 6),
          Text(
            'Add New',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            'Add more services',
            style: TextStyle(fontSize: 8, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

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
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
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
                          color: isDark ? Colors.white70 : const Color(0xFF888888),
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
          Divider(
            height: 1,
            indent: 70,
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEEEEEE),
          ),
      ],
    );
  }

  // --- CRUD BOTTOM SHEETS FOR SERVICES ---

  void _showAddServiceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ServiceFormBottomSheet(),
    );
  }

  void _showEditServiceDialog(BuildContext context, VendorServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceFormBottomSheet(service: service),
    );
  }
}

class ServiceFormBottomSheet extends ConsumerStatefulWidget {
  final VendorServiceModel? service;

  const ServiceFormBottomSheet({super.key, this.service});

  @override
  ConsumerState<ServiceFormBottomSheet> createState() => _ServiceFormBottomSheetState();
}

class _ServiceFormBottomSheetState extends ConsumerState<ServiceFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _serviceType;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _inclusionsController;
  late TextEditingController _durationController;
  late String _priceType;
  late TextEditingController _priceController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late String _serviceLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.service?.serviceType ?? 'groomer';
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descController = TextEditingController(text: widget.service?.description ?? '');
    _inclusionsController = TextEditingController(text: widget.service?.inclusions.join(', ') ?? '');
    _durationController = TextEditingController(text: widget.service?.durationMinutes.toString() ?? '60');
    _priceType = widget.service?.priceType ?? 'fixed';
    _priceController = TextEditingController(text: widget.service?.price?.toString() ?? '');
    _minPriceController = TextEditingController(text: widget.service?.minPrice?.toString() ?? '');
    _maxPriceController = TextEditingController(text: widget.service?.maxPrice?.toString() ?? '');
    _serviceLocation = widget.service?.serviceLocation ?? 'at_my_place';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _inclusionsController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final inclusions = _inclusionsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final duration = int.tryParse(_durationController.text) ?? 60;
    final price = double.tryParse(_priceController.text);
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);

    try {
      if (widget.service == null) {
        // Create
        await ref.read(servicesControllerProvider.notifier).addService(
              serviceType: _serviceType,
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              inclusions: inclusions,
              durationMinutes: duration,
              priceType: _priceType,
              price: price,
              minPrice: minPrice,
              maxPrice: maxPrice,
              serviceLocation: _serviceLocation,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service added successfully!')),
          );
        }
      } else {
        // Update
        await ref.read(servicesControllerProvider.notifier).updateService(
              serviceId: widget.service!.id,
              serviceType: _serviceType,
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              inclusions: inclusions,
              durationMinutes: duration,
              priceType: _priceType,
              price: price,
              minPrice: minPrice,
              maxPrice: maxPrice,
              serviceLocation: _serviceLocation,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service updated successfully!')),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (widget.service == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(servicesControllerProvider.notifier).deleteService(widget.service!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _buildInputDeco(String hintText, bool isDark) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.barlow(
        color: isDark ? Colors.white30 : Colors.grey.shade400,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.barlow(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.orange,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.service == null ? 'Add Service' : 'Edit Service',
                    style: GoogleFonts.barlow(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (widget.service != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                      onPressed: _isLoading ? null : _delete,
                    ),
                ],
              ),
              const Divider(height: 20),

              // Service Type Dropdown
              _buildLabel('Service Type'),
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: _buildInputDeco('Select service type', isDark),
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey),
                items: const [
                  DropdownMenuItem(value: 'groomer', child: Text('Groomer')),
                  DropdownMenuItem(value: 'vet', child: Text('Vet')),
                  DropdownMenuItem(value: 'walker', child: Text('Walker')),
                  DropdownMenuItem(value: 'trainer', child: Text('Trainer')),
                  DropdownMenuItem(value: 'sitter', child: Text('Sitter')),
                  DropdownMenuItem(value: 'boarding', child: Text('Boarding')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _serviceType = val;
                    });
                  }
                },
              ),

              // Name
              _buildLabel('Service Name'),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _buildInputDeco('Enter service name', isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),

              // Description
              _buildLabel('Description'),
              TextFormField(
                controller: _descController,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _buildInputDeco('Enter description', isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),

              // Inclusions (comma-separated)
              _buildLabel('Inclusions (comma separated)'),
              TextFormField(
                controller: _inclusionsController,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _buildInputDeco('Bath, Haircut, Nail trimming', isDark),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),

              // Duration
              _buildLabel('Duration (Minutes)'),
              TextFormField(
                controller: _durationController,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _buildInputDeco('e.g. 60', isDark),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Must be a valid number';
                  return null;
                },
              ),

              // Price Type Dropdown
              _buildLabel('Price Type'),
              DropdownButtonFormField<String>(
                value: _priceType,
                decoration: _buildInputDeco('Select price type', isDark),
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey),
                items: const [
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
                  DropdownMenuItem(value: 'range', child: Text('Price Range')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _priceType = val;
                    });
                  }
                },
              ),

              if (_priceType == 'fixed') ...[
                _buildLabel('Price (\$)'),
                TextFormField(
                  controller: _priceController,
                  style: GoogleFonts.barlow(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _buildInputDeco('Enter price', isDark),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (_priceType == 'fixed') {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Must be a valid price';
                    }
                    return null;
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Min Price (\$)'),
                          TextFormField(
                            controller: _minPriceController,
                            style: GoogleFonts.barlow(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDeco('Min', isDark),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (_priceType == 'range') {
                                  if (val == null || val.isEmpty) return 'Required';
                                  if (double.tryParse(val) == null) return 'Must be a valid price';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Max Price (\$)'),
                          TextFormField(
                            controller: _maxPriceController,
                            style: GoogleFonts.barlow(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _buildInputDeco('Max', isDark),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (_priceType == 'range') {
                                  if (val == null || val.isEmpty) return 'Required';
                                  if (double.tryParse(val) == null) return 'Must be a valid price';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // Location Dropdown
              _buildLabel('Service Location'),
              DropdownButtonFormField<String>(
                value: _serviceLocation,
                decoration: _buildInputDeco('Select location', isDark),
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                style: GoogleFonts.barlow(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey),
                items: const [
                  DropdownMenuItem(value: 'at_my_place', child: Text('At My Place')),
                  DropdownMenuItem(value: 'at_client_place', child: Text('At Client Place')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _serviceLocation = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE85D04), Color(0xFFF48C06)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE85D04).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.service == null ? 'Create Service' : 'Save Changes',
                          style: GoogleFonts.barlow(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
