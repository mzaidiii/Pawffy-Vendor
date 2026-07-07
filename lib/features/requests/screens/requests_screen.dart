import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pawffy/main.dart';
import 'package:pawffy/features/home/providers/home_controller.dart';
import 'package:pawffy/features/notification/notification_screen.dart';

import '../data/models/request_model.dart';
import '../providers/requests_controller.dart';
import 'request_details_screen.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _activeStatus = 'pending'; // pending, upcoming, completed, canceled

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      ref.read(requestsQueryProvider.notifier).setQuery(query);
    });
  }

  void _changeStatus(String status) {
    setState(() {
      _activeStatus = status;
    });
    ref.read(requestsFilterProvider.notifier).setFilter(status);
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: homeDataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
          error: (error, _) => Center(
            child: Text('Error loading dashboard: $error'),
          ),
          data: (homeData) {
            final isVerified = homeData?.applicationStatus.isVerified ?? false;

            if (!isVerified) {
              return _buildLockedState(context, isDark);
            }

            return _buildRequestsContent(context, isDark);
          },
        ),
      ),
    );
  }

  // --- LOCKED STATE ---
  Widget _buildLockedState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildSearchRow(isDark),
          const SizedBox(height: 12),
          _buildFilterChips(isDark),
          const Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ConfettiLockWidget(),
                    SizedBox(height: 32),
                    Text(
                      'REQUEST UNAVAILABLE',
                      style: TextStyle(
                        fontFamily: 'Barlow',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Your application is under review. You will start receiving Requests once your application is approved.',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40),
                    _LearnMoreButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VERIFIED STATE ---
  Widget _buildRequestsContent(BuildContext context, bool isDark) {
    final requestsAsync = ref.watch(requestsNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildSearchRow(isDark),
          const SizedBox(height: 12),
          _buildFilterChips(isDark),
          const SizedBox(height: 16),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load requests',
                      style: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(err.toString(), style: const TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                      onPressed: () => ref.read(requestsNotifierProvider.notifier).refresh(),
                      child: const Text('RETRY'),
                    )
                  ],
                ),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 64,
                          color: isDark ? AppColors.grey : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No requests found',
                          style: GoogleFonts.barlow(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Requests for status "${_activeStatus}" will appear here.',
                          style: const TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.orange,
                  onRefresh: () => ref.read(requestsNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return _buildRequestCard(context, req, isDark);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-WIDGETS ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'REQUESTS',
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
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          },
          child: Stack(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.orangeLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.barlow(
                color: isDark ? AppColors.white : AppColors.black,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search by Store Name...',
                hintStyle: GoogleFonts.barlow(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.grey,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final statusMapping = {
      'pending': 'Pending',
      'upcoming': 'Upcoming',
      'completed': 'Competed', // Typo from Figma design
      'canceled': 'Canceled',
    };

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: statusMapping.entries.map((entry) {
          final isSelected = _activeStatus == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _changeStatus(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.orange
                        : (isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: GoogleFonts.barlow(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel req, bool isDark) {
    final hasPetPhoto = req.pet?.photo != null && req.pet!.photo!.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsScreen(request: req),
          ),
        ).then((_) {
          // Refresh list on return in case status was updated
          ref.read(requestsNotifierProvider.notifier).refresh();
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image / Falling Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPetPhoto
                  ? CachedNetworkImage(
                      imageUrl: req.pet!.photo!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _buildFallbackAvatar(req.pet?.name ?? 'P'),
                    )
                  : _buildFallbackAvatar(req.pet?.name ?? 'P'),
            ),
            const SizedBox(width: 14),

            // Card Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.pet?.name ?? 'Unknown Pet',
                        style: GoogleFonts.barlow(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (req.status == 'pending')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.barlow(
                              color: AppColors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${req.pet?.age ?? "Age unknown"} • ${req.pet?.gender ?? "Gender unknown"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    req.pet?.breed ?? 'Breed unknown',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.pets_outlined, size: 14, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          req.serviceName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          req.time,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ),
                      Text(
                        req.priceDisplay,
                        style: GoogleFonts.barlow(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.barlow(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

// --- LEARN MORE BUTTON WIDGET ---
class _LearnMoreButton extends StatelessWidget {
  const _LearnMoreButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Learn more behavior, can display a bottom sheet or url launch
            showModalBottomSheet(
              context: context,
              backgroundColor: Theme.of(context).cardColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Onboarding Review Process',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Barlow',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Our admin team manually reviews all partner details, services, business licenses, and documents. This check typically takes 24-48 business hours. Once verified, your status will update and requests will become available.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('GOT IT'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LEARN MORE',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.call_made_rounded, color: AppColors.orange, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- CONFETTI LOCK DECORATED WIDGET ---
class _ConfettiLockWidget extends StatelessWidget {
  const _ConfettiLockWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Padlock circle base
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),

          // Confetti shape 1: Blue capsule (Top-Left)
          Positioned(
            left: 32,
            top: 36,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: 18,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Confetti shape 2: Red/Orange capsule (Far Top-Left)
          Positioned(
            left: 45,
            top: 20,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 15,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),

          // Confetti shape 3: Light Blue capsule (Top-Right)
          Positioned(
            right: 32,
            top: 22,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 16,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Confetti shape 4: Green capsule (Far Right)
          Positioned(
            right: 18,
            top: 60,
            child: Transform.rotate(
              angle: -0.8,
              child: Container(
                width: 15,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),

          // Confetti shape 5: Green capsule (Bottom-Left)
          Positioned(
            left: 32,
            bottom: 40,
            child: Transform.rotate(
              angle: 0.7,
              child: Container(
                width: 17,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Confetti shape 6: Orange capsule (Bottom-Right)
          Positioned(
            right: 32,
            bottom: 30,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 15,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.shade700,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
