import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:pawffy/main.dart';
import 'package:pawffy/features/home/providers/home_provider.dart';
import 'package:pawffy/features/home/providers/home_controller.dart';
import 'package:pawffy/features/home/data/models/home_data_model.dart';
import 'package:pawffy/features/notification/notification_screen.dart';
import 'package:pawffy/features/notification/providers/notification_controller.dart';

import 'data/models/calendar_day_model.dart';
import 'providers/calendar_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final ScrollController _dateScrollController = ScrollController();

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    final calendarDayAsync = ref.watch(calendarDayProvider);
    final homeDataAsync = ref.watch(homeControllerProvider);
    final unreadNotifCount = ref.watch(unreadCountProvider);

    final isOnline = homeDataAsync.maybeWhen(
      data: (data) => data?.header.isOnline ?? false,
      orElse: () => false,
    );

    // Listen to changes in navigation tab to reset date to today on tab tap
    ref.listen<int>(navigationIndexProvider, (previous, next) {
      if (next == 2) { // Index of Calendar tab
        ref.read(selectedDateProvider.notifier).setDate(DateTime.now());
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(calendarDayProvider);
            ref.invalidate(blockedDatesProvider);
            ref.read(homeControllerProvider.notifier).refresh();
          },
          color: AppColors.orange,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header Row
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CALENDAR',
                        style: GoogleFonts.barlow(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.5,
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
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                            if (unreadNotifCount > 0)
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
                                    '$unreadNotifCount',
                                    style: GoogleFonts.barlow(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                ),
              ),

              // 2. Week/Month horizontal date slider
              SliverToBoxAdapter(
                child: _buildDateSlider(selectedDate),
              ),

              // 3. API Response Content (Banner, Availability, Schedule List)
              calendarDayAsync.when(
                data: (calendarDay) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Banner Card
                        _buildRequestBanner(context, calendarDay),
                        const SizedBox(height: 20),

                        // Availability section
                        _buildAvailabilitySection(context, isOnline),
                        const SizedBox(height: 20),

                        // Dynamic Schedule Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _getScheduleHeader(selectedDate),
                            style: GoogleFonts.barlow(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),

                        // Schedule Content
                        if (calendarDay.isBlocked)
                          _buildBlockedDayCard(context, calendarDay.blockedReason)
                        else if (calendarDay.schedule.isEmpty)
                          _buildEmptyScheduleCard(context)
                        else
                          ...calendarDay.schedule.map((booking) => _buildBookingCard(context, booking)),
                        
                        const SizedBox(height: 40),
                      ]),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load calendar data',
                            style: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            err.toString().replaceFirst('Exception: ', ''),
                            style: GoogleFonts.barlow(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: () => ref.invalidate(calendarDayProvider),
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
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

  // Helper to dynamically name schedule sections
  String _getScheduleHeader(DateTime selectedDate) {
    final today = DateTime.now();
    if (DateUtils.isSameDay(selectedDate, today)) {
      return "Today's Schedule";
    } else if (DateUtils.isSameDay(selectedDate, today.add(const Duration(days: 1)))) {
      return "Tomorrow's Schedule";
    } else if (DateUtils.isSameDay(selectedDate, today.subtract(const Duration(days: 1)))) {
      return "Yesterday's Schedule";
    } else {
      return "${DateFormat('EEEE, MMM d').format(selectedDate)}'s Schedule";
    }
  }

  // Horizontal Date Slider
  Widget _buildDateSlider(DateTime selectedDate) {
    final today = DateTime.now();
    
    // Stable dates anchored to today in general, but shifts if selectedDate is out of window
    var baseDate = today;
    final minStableDate = today.subtract(const Duration(days: 7));
    final maxStableDate = today.add(const Duration(days: 22));
    if (selectedDate.isBefore(minStableDate) || selectedDate.isAfter(maxStableDate)) {
      baseDate = selectedDate;
    }

    // Anchor the date slider so today's date (or selected date) starts centered
    final dates = List.generate(30, (index) => baseDate.add(Duration(days: index - 3)));

    return Container(
      height: 84,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dates.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                final isToday = DateUtils.isSameDay(date, today);
                final dayName = DateFormat('E').format(date); // Mon, Tue...
                final dayNum = DateFormat('d').format(date); // 12, 13...

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).setDate(date);
                  },
                  child: Container(
                    width: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.orangeLight
                                : isToday
                                    ? AppColors.orange
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.orange : Colors.transparent,
                            shape: BoxShape.circle,
                            border: !isSelected && isToday
                                ? Border.all(color: AppColors.orange, width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayNum,
                            style: GoogleFonts.barlow(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppColors.orange
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else if (isToday) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.orange, size: 24),
              onPressed: () async {
                // Open a Date Picker dialog instead of just shifting date
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  ref.read(selectedDateProvider.notifier).setDate(picked);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Request Banner card
  Widget _buildRequestBanner(BuildContext context, CalendarDayModel calendarDay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
              : [const Color(0xFF2C2C2C), const Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Sparkle Icon & dog image
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.1,
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
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          children: const [
                            TextSpan(text: 'You have '),
                            TextSpan(
                              text: 'pending requests',
                              style: TextStyle(
                                color: AppColors.orangeLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: '. Check them out!'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          // Change tab index in HomeScreen to index 1 (Requests)
                          ref.read(navigationIndexProvider.notifier).setIndex(1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: 'https://images.unsplash.com/photo-1534361960057-19889db9621e?auto=format&fit=crop&q=80&w=250',
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                            placeholder: (context, url) => Container(
                              color: Colors.white10,
                              width: 90,
                              height: 90,
                              child: const Icon(Icons.pets, color: Colors.white24, size: 24),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'android/assets/LoginDog.png',
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.pets_rounded,
                                color: AppColors.orange,
                                size: 48,
                              ),
                            ),
                          ),
                          // Sparkle icon overlaid
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.orangeLight,
                              size: 18,
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
        ],
      ),
    );
  }

  // Availability Cards & Buttons
  Widget _buildAvailabilitySection(BuildContext context, bool isOnline) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Availability',
            style: GoogleFonts.barlow(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (isOnline)
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Your are Online' : 'You are Offline', // matching design text
                      style: GoogleFonts.barlow(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isOnline ? 'Accept new requests' : 'Not accepting requests',
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isOnline,
                activeColor: Colors.white,
                activeTrackColor: AppColors.orange,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (val) async {
                  final success = await ref.read(homeControllerProvider.notifier).toggleOnlineStatus();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update online status'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'Manage Availability',
                onTap: () => _showManageAvailabilitySheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.calendar_today_outlined,
                label: 'Blocked Dates',
                onTap: () => _showBlockedDatesSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.orange, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.barlow(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Blocked Day Card UI
  Widget _buildBlockedDayCard(BuildContext context, String? reason) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.block_flipped, color: AppColors.orange, size: 40),
          const SizedBox(height: 12),
          Text(
            'This date is blocked',
            style: GoogleFonts.barlow(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: $reason',
              style: GoogleFonts.barlow(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Empty Schedule Card UI
  Widget _buildEmptyScheduleCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings scheduled',
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no appointments on this day.',
              style: GoogleFonts.barlow(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Booking Card UI (Matches Mockup)
  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConfirmed = booking.status.toLowerCase() == 'confirmed' ||
        booking.status.toLowerCase() == 'completed';
    final isPending = booking.status.toLowerCase() == 'pending';

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request details for ${booking.petName} will be wired here.'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.orange,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left column: Avatar and Time below it
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: booking.petPhoto != null && booking.petPhoto!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: booking.petPhoto!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: Colors.grey.withOpacity(0.1)),
                          errorWidget: (ctx, url, err) => Image.asset(
                            'android/assets/LoginDog.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'android/assets/LoginDog.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.pets_rounded,
                            color: AppColors.orange,
                            size: 24,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.time,
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Middle column: Name, Service, Location
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
                  const SizedBox(height: 4),
                  Text(
                    booking.serviceName,
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.location,
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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

            // Right column: Price and Status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  booking.priceDisplay,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? AppColors.success.withOpacity(isDark ? 0.15 : 0.1)
                        : isPending
                            ? AppColors.orange.withOpacity(isDark ? 0.15 : 0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConfirmed
                          ? AppColors.success.withOpacity(0.3)
                          : isPending
                              ? AppColors.orange.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isConfirmed
                        ? 'Confirmed'
                        : isPending
                            ? 'Pending'
                            : 'Canceled',
                    style: GoogleFonts.barlow(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isConfirmed
                          ? AppColors.success
                          : isPending
                              ? AppColors.orange
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  // BOTTOM SHEET: Manage Availability
  void _showManageAvailabilitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _ManageAvailabilityBottomSheet();
      },
    ).then((value) {
      // Refresh calendar status in case availability settings changed
      ref.invalidate(calendarDayProvider);
    });
  }

  // BOTTOM SHEET: Blocked Dates
  void _showBlockedDatesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _BlockedDatesBottomSheet();
      },
    );
  }
}

// Stateful Widget for Manage Availability Bottom Sheet
class _ManageAvailabilityBottomSheet extends ConsumerStatefulWidget {
  const _ManageAvailabilityBottomSheet();

  @override
  ConsumerState<_ManageAvailabilityBottomSheet> createState() =>
      __ManageAvailabilityBottomSheetState();
}

class __ManageAvailabilityBottomSheetState
    extends ConsumerState<_ManageAvailabilityBottomSheet> {
  bool _isLoading = true;
  List<String> _workingDays = [];
  String _startTime = '09:00 AM';
  String _endTime = '06:00 PM';
  bool _sameDayRequests = false;

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final res = await ref.read(calendarServiceProvider).getAvailability();
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final avail = (data is Map && data.containsKey('availability'))
            ? data['availability']
            : data;
        if (avail != null) {
          setState(() {
            _workingDays = List<String>.from(avail['workingDays'] ?? []);
            _startTime = avail['startTime']?.toString() ?? '09:00 AM';
            _endTime = avail['endTime']?.toString() ?? '06:00 PM';
            _sameDayRequests = avail['sameDayRequests'] as bool? ?? false;
          });
        }
      }
    } catch (_) {
      // Fall back to defaults
      setState(() {
        _workingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final format = DateFormat('hh:mm a');
    DateTime initialDateTime;
    try {
      initialDateTime = format.parse(isStart ? _startTime : _endTime);
    } catch (_) {
      initialDateTime = DateTime(2026, 1, 1, 9, 0);
    }

    final initialTime = TimeOfDay.fromDateTime(initialDateTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() {
        if (isStart) {
          _startTime = format.format(dt);
        } else {
          _endTime = format.format(dt);
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(calendarServiceProvider).updateAvailability(
            workingDays: _workingDays,
            startTime: _startTime,
            endTime: _endTime,
            sameDayRequests: _sameDayRequests,
          );

      final success = response['success'] == true;
      if (success) {
        if (mounted) {
          Navigator.pop(context); // Dismiss sheet first so snackbar is visible
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Availability settings updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to save settings');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss sheet first so snackbar is visible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Manage Availability',
              style: GoogleFonts.barlow(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              )
            else ...[
              // Working Days Selection
              Text(
                'WORKING DAYS',
                style: GoogleFonts.barlow(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekDays.map((day) {
                  final isSelected = _workingDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _workingDays.remove(day);
                        } else {
                          _workingDays.add(day);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.orange
                            : (isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.orange
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        day,
                        style: GoogleFonts.barlow(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Start and End Times
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'START TIME',
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startTime,
                                  style: GoogleFonts.barlow(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              ],
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
                        Text(
                          'END TIME',
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endTime,
                                  style: GoogleFonts.barlow(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Same Day Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Same Day Requests',
                          style: GoogleFonts.barlow(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Allow clients to book services for the same day',
                          style: GoogleFonts.barlow(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sameDayRequests,
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.orange,
                    onChanged: (val) {
                      setState(() => _sameDayRequests = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _save,
                child: const Text('SAVE AVAILABILITY'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Stateful Widget for Blocked Dates Bottom Sheet
class _BlockedDatesBottomSheet extends ConsumerStatefulWidget {
  const _BlockedDatesBottomSheet();

  @override
  ConsumerState<_BlockedDatesBottomSheet> createState() =>
      __BlockedDatesBottomSheetState();
}

class __BlockedDatesBottomSheetState extends ConsumerState<_BlockedDatesBottomSheet> {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addBlockedDate() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date to block'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason (e.g. Holiday)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final success = await ref.read(blockedDatesProvider.notifier).addBlockedDate(dateStr, reason);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Date blocked successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _reasonController.clear();
        setState(() {
          _selectedDate = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to block date'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blockedDatesAsync = ref.watch(blockedDatesProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Blocked Dates',
            style: GoogleFonts.barlow(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Form to Add Blocked Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLOCK A NEW DATE',
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                style: GoogleFonts.barlow(
                                  fontSize: 13,
                                  color: _selectedDate == null
                                      ? Colors.grey
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const Icon(Icons.calendar_month, size: 16, color: AppColors.orange),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          hintText: 'Reason (e.g. Holiday)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          hintStyle: GoogleFonts.barlow(fontSize: 13, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                        ),
                        style: GoogleFonts.barlow(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _addBlockedDate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('BLOCK DATE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'BLOCKED DATES LIST',
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable List of Blocked Dates
          Expanded(
            child: blockedDatesAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No blocked dates configured',
                        style: GoogleFonts.barlow(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.grey.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.date,
                                style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              if (item.reason != null && item.reason!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.reason!,
                                  style: GoogleFonts.barlow(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final success = await ref
                                  .read(blockedDatesProvider.notifier)
                                  .removeBlockedDate(item.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Blocked date removed!'),
                                    backgroundColor: Colors.black,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
