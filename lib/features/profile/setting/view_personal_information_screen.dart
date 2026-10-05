import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/auth/providers/current_user_provider.dart';
import 'package:pawffy/features/profile/providers/profile_controller.dart';
import 'package:pawffy/features/profile/setting/personal_information_screen.dart';

class ViewPersonalInformationScreen extends ConsumerWidget {
  const ViewPersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileControllerProvider);
    final user = ref.watch(currentUserProvider).asData?.value;
    final profile = profileAsync.asData?.value;

    // Dynamic Theme colors
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.white : AppColors.black;
    final subtextColor = isDark ? AppColors.white.withOpacity(0.7) : AppColors.black.withOpacity(0.7);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final avatarUrl = profile?.profile.profileImage ?? user?.profileImage;
    final name = profile?.profile.name ?? user?.name ?? 'Vendor';
    final email = profile?.profile.email ?? user?.email ?? 'Not specified';
    final phone = profile?.profile.phone ?? user?.phone ?? 'Not specified';
    final location = profile?.profile.location ?? user?.address ?? 'Not specified';
    final city = profile?.profile.city ?? user?.city ?? 'Not specified';
    final state = profile?.profile.state ?? user?.state ?? 'Not specified';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PERSONAL INFORMATION',
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // --- AVATAR & USER SUMMARY CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.orange, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: isDark ? AppColors.darkBg : Colors.grey.shade200,
                            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Icon(Icons.person_rounded, size: 50, color: AppColors.grey)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.barlow(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (user?.role ?? 'SERVICE PROVIDER').toUpperCase(),
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- CONTACT DETAILS SECTION ---
              _buildSectionHeader('CONTACT DETAILS', textColor),
              const SizedBox(height: 8),
              _buildInfoGroupCard(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                items: [
                  _buildDetailRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Address',
                    value: email,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Mobile Number',
                    value: phone,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- PERSONAL DETAILS SECTION ---
              _buildSectionHeader('PERSONAL DETAILS', textColor),
              const SizedBox(height: 8),
              _buildInfoGroupCard(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                items: [
                  _buildDetailRow(
                    icon: Icons.wc_rounded,
                    label: 'Gender',
                    value: 'Male', // Default profile setting
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: '12 May 1995', // Placeholder
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- LOCATION DETAILS SECTION ---
              _buildSectionHeader('LOCATION DETAILS', textColor),
              const SizedBox(height: 8),
              _buildInfoGroupCard(
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                items: [
                  _buildDetailRow(
                    icon: Icons.home_work_outlined,
                    label: 'Street Address',
                    value: location,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    icon: Icons.location_city_rounded,
                    label: 'City',
                    value: city,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    icon: Icons.map_outlined,
                    label: 'State',
                    value: state,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    icon: Icons.markunread_mailbox_outlined,
                    label: 'Pin Code',
                    value: '546014',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
              shadowColor: AppColors.orange.withOpacity(0.35),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalInformationScreen(),
                ),
              );
              ref.read(profileControllerProvider.notifier).refresh();
              ref.read(currentUserProvider.notifier).refresh();
            },
            icon: const Icon(Icons.edit_rounded, color: AppColors.white, size: 20),
            label: Text(
              'EDIT PROFILE',
              style: GoogleFonts.barlow(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.barlow(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.orange,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoGroupCard({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
    );
  }
}
