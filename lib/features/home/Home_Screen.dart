import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:pawffy/core/utils/location_provider.dart';
import 'package:pawffy/features/message/message_screen.dart';
import 'package:pawffy/features/notification/notification_screen.dart';
import 'package:pawffy/features/profile/profile_screen.dart';
import 'package:pawffy/features/calendar/calendar_screen.dart';
import 'package:pawffy/features/requests/screens/requests_screen.dart';
import 'package:pawffy/features/home/providers/home_provider.dart';
import 'package:pawffy/main.dart';

import 'data/models/home_data_model.dart';
import 'providers/home_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(navigationIndexProvider);
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    final pages = [
      const HomeTabBody(),
      const RequestsScreen(),
      const CalendarScreen(),
      const MessageScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.assignment_outlined, 'label': 'Requests'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Calendar'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Message'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            width: 1,
          ),
        ),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final currentIndex = ref.watch(navigationIndexProvider);
              final isActive = currentIndex == index;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(navigationIndexProvider.notifier).setIndex(index);
                },
                child: SizedBox(
                  width: 65,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isActive
                            ? AppColors.orange
                            : (isDark
                                  ? const Color(0xFF888888)
                                  : const Color(0xFF555555)),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index]['label'] as String,
                        style: GoogleFonts.barlow(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.orange
                              : (isDark
                                    ? const Color(0xFF888888)
                                    : const Color(0xFF555555)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeTabBody extends ConsumerWidget {
  const HomeTabBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeControllerProvider);
    final locationAsync = ref.watch(locationTextProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return homeAsync.when(
      data: (homeData) {
        if (homeData == null) {
          return const Center(child: Text('No dashboard data found.'));
        }

        final header = homeData.header;
        final appStatus = homeData.applicationStatus;
        final banner = homeData.banner;
        final glance = homeData.todayAtAGlance;
        final bookings = homeData.upcomingBookings;

        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.orange,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            onRefresh: () =>
                ref.read(homeControllerProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Top location and Notification bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => ref.refresh(positionProvider),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                header.location.isNotEmpty
                                    ? header.location
                                    : (locationAsync.value ?? 'Ghaziabad, UP'),
                                style: GoogleFonts.barlow(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => const NotificationScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withOpacity(0.08),
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 20,
                                ),
                              ),
                              if (header.unreadNotifications > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '${header.unreadNotifications}',
                                      style: GoogleFonts.barlow(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Welcome and Status capsule row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: GoogleFonts.barlow(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                header.name.toUpperCase(),
                                style: GoogleFonts.barlow(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _buildOnlineStatusCapsule(
                          context,
                          ref,
                          header.isOnline,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Search Bar
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.08),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Search is only available inside Requests tab',
                                      style: GoogleFonts.barlow(),
                                    ),
                                    backgroundColor: AppColors.orange,
                                  ),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by Store Name...',
                                hintStyle: GoogleFonts.barlow(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.tune_rounded,
                            color: AppColors.orange,
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 1. Application Status Card (conditional)
                    if (appStatus.status != 'verified')
                      _buildApplicationStatusCard(context, appStatus),

                    const SizedBox(height: 16),

                    // 2. Carousel Banner
                    _buildRequestBanner(context, banner),

                    const SizedBox(height: 24),

                    // 3. TODAY AT A GLANCE
                    Text(
                      'TODAY AT A GLANCE',
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTodayGlanceGrid(context, glance),

                    const SizedBox(height: 24),

                    // 4. UPCOMING BOOKINGS
                    Text(
                      'UPCOMING BOOKINGS',
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUpcomingBookings(
                      context,
                      bookings,
                      appStatus.isPending,
                    ),

                    const SizedBox(height: 24),

                    // 5. QUICK ACTIONS
                    Text(
                      'QUICK ACTIONS',
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 20),

                    // 6. Grow your Business Banner
                    _buildPremiumBanner(context),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to fetch home screen data',
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  style: GoogleFonts.barlow(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(homeControllerProvider.notifier).fetchHomeData(),
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCapsule(
    BuildContext context,
    WidgetRef ref,
    bool isOnline,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(cardColor: isDark ? AppColors.darkCard : Colors.white),
      child: PopupMenuButton<bool>(
        offset: const Offset(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) async {
          if (value != isOnline) {
            final success = await ref
                .read(homeControllerProvider.notifier)
                .toggleOnlineStatus();
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'You are now Online' : 'You are now Offline',
                    style: GoogleFonts.barlow(),
                  ),
                  backgroundColor: AppColors.orange,
                ),
              );
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<bool>(
            value: true,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Online',
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<bool>(
            value: false,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Offline',
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isOnline ? AppColors.success : AppColors.grey)
                  .withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: GoogleFonts.barlow(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationStatusCard(
    BuildContext context,
    HomeApplicationStatus appStatus,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221108) : const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Status',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appStatus.label,
                  style: GoogleFonts.barlow(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  appStatus.message,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _showStatusDetailsDialog(context, appStatus);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.barlow(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.orange,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestBanner(BuildContext context, HomeBanner banner) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFF333333), const Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background graphic elements
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.pets_rounded,
                size: 150,
                color: AppColors.orange,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "LET'S MAKE TAILS\nWAG TODAY",
                        style: GoogleFonts.barlow(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Highlight the number in orange:
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          children: [
                            const TextSpan(text: 'You have '),
                            TextSpan(
                              text: '${banner.newRequestsCount} new requests',
                              style: const TextStyle(
                                color: AppColors.orangeLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' waiting for your response'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'VIEW REQUESTS',
                              style: GoogleFonts.barlow(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_outward_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1534361960057-19889db9621e?auto=format&fit=crop&q=80&w=250',
                        fit: SystemThemeCompat.fitType,
                        width: 90,
                        height: 90,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.withOpacity(0.1),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'android/assets/LoginDog.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayGlanceGrid(BuildContext context, TodayAtAGlance glance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGlanceCard(
                context: context,
                title: "Today's Schedule",
                value: glance.schedule.count.toString(),
                label: glance.schedule.label,
                labelColor: AppColors.success,
                icon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlanceCard(
                context: context,
                title: 'New Requests',
                value: glance.newRequests.count.toString(),
                label: glance.newRequests.label,
                labelColor: AppColors.orange,
                icon: Icons.assignment_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGlanceCard(
                context: context,
                title: 'Earnings (Today)',
                value: glance.earnings.display,
                label: glance.earnings.changeLabel,
                labelColor: AppColors.success,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlanceCard(
                context: context,
                title: 'Rating',
                value: glance.rating.average == 0.0
                    ? 'N/A'
                    : glance.rating.average.toStringAsFixed(1),
                label: '(${glance.rating.reviewCount} Reviews)',
                labelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.5),
                icon: Icons.star_rounded,
                isRating: true,
                ratingScore: glance.rating.average,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlanceCard({
    required BuildContext context,
    required String title,
    required String value,
    required String label,
    required Color labelColor,
    required IconData icon,
    bool isRating = false,
    double ratingScore = 0.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.barlow(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.barlow(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isRating && ratingScore > 0.0)
                      Row(
                        children: List.generate(5, (starIdx) {
                          final isFilled = ratingScore >= starIdx + 1;
                          return Icon(
                            Icons.star_rounded,
                            color: isFilled
                                ? Colors.amber
                                : Colors.grey.withOpacity(0.3),
                            size: 10,
                          );
                        }),
                      )
                    else
                      Text(
                        label,
                        style: GoogleFonts.barlow(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isRating) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.barlow(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings(
    BuildContext context,
    List<BookingModel> bookings,
    bool isPending,
  ) {
    if (bookings.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No upcoming bookings for today',
              style: GoogleFonts.barlow(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPending
                  ? 'Bookings will appear here once your application is approved.'
                  : 'You are all caught up for today!',
              style: GoogleFonts.barlow(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: bookings
          .map((booking) => _buildBookingCard(context, booking))
          .toList(),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConfirmed = booking.status.toLowerCase() == 'confirmed';
    final isPendingStatus = booking.status.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar and Time column
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: booking.petPhoto != null && booking.petPhoto!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: booking.petPhoto!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _buildFallbackPetAvatar(booking.petName),
                      )
                    : _buildFallbackPetAvatar(booking.petName),
              ),
              const SizedBox(height: 6),
              Text(
                booking.time,
                style: GoogleFonts.barlow(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Name and Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.petName,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  booking.serviceName,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        booking.location,
                        style: GoogleFonts.barlow(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Price and Status badge column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.priceDisplay,
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? AppColors.success.withOpacity(0.15)
                      : (isPendingStatus
                            ? AppColors.orange.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: GoogleFonts.barlow(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isConfirmed
                        ? AppColors.success
                        : (isPendingStatus ? AppColors.orange : Colors.grey),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPetAvatar(String name) {
    final firstChar = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'P';
    return Container(
      width: 44,
      height: 44,
      color: AppColors.orange.withOpacity(0.15),
      child: Center(
        child: Text(
          firstChar,
          style: GoogleFonts.barlow(
            color: AppColors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                label: 'Manage Availability',
                icon: Icons.calendar_month_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please use the Calendar tab for detailed availability scheduling.',
                        style: GoogleFonts.barlow(),
                      ),
                      backgroundColor: AppColors.orange,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                label: 'Services',
                icon: Icons.pets_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Services list is editable under Profile -> Services list.',
                        style: GoogleFonts.barlow(),
                      ),
                      backgroundColor: AppColors.orange,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                label: 'Earnings',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _showEarningsDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                label: 'Verification',
                icon: Icons.shield_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Your business details are stored securely. Status is reviewed by admin.',
                        style: GoogleFonts.barlow(),
                      ),
                      backgroundColor: AppColors.orange,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.orange, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.barlow(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1610) : const Color(0xFFFFFAF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B1A).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFF6B1A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow your Business',
                  style: GoogleFonts.barlow(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upgrade to premium to get more visibility and exclusive benefits',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showPremiumUpgradeDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upgrade Now',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDetailsDialog(
    BuildContext context,
    HomeApplicationStatus status,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Verification Process',
          style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${status.label}',
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Applications are reviewed by the Pawffy Admin Panel within 24 to 48 hours after submission. You will be notified immediately via app and email when your business is verified.',
              style: GoogleFonts.barlow(fontSize: 13, height: 1.4),
            ),
            if (status.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Text(
                  'Rejection Reason: ${status.rejectionReason}',
                  style: GoogleFonts.barlow(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CLOSE',
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEarningsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Earnings Dashboard',
          style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed historical earnings, payout history, bank setup, and transaction statements are currently missing in the API backend.',
              style: GoogleFonts.barlow(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'For now, you can view your aggregated daily earnings summary in the "TODAY AT A GLANCE" panel.',
              style: GoogleFonts.barlow(
                fontSize: 13,
                color: AppColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFF6B1A),
            ),
            const SizedBox(width: 8),
            Text(
              'Pawffy Premium',
              style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium upgrades, subscription plans, and payment gateways are currently under development on the backend.',
              style: GoogleFonts.barlow(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Benefits include: \n• 3x search boost visibility\n• Direct customer outreach limits removed\n• Zero platform commission fee',
              style: GoogleFonts.barlow(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CLOSE',
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.bold,
                color: AppColors.orange,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Subscription API coming soon!',
                    style: GoogleFonts.barlow(),
                  ),
                  backgroundColor: AppColors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('NOTIFY ME'),
          ),
        ],
      ),
    );
  }
}

// Requests screen is now fully integrated.

class CalendarTabPlaceholder extends StatelessWidget {
  const CalendarTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'CALENDAR',
                style: GoogleFonts.barlow(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: AppColors.orange,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Calendar Schedule Placeholder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'This screen manages your availability calendar and blocked dates.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class SystemThemeCompat {
  static const fitType = BoxFit.cover;
}
