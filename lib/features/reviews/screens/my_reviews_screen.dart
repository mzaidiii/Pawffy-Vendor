import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pawffy/main.dart';
import '../data/models/review_model.dart';
import '../providers/reviews_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
        title: Text(
          'MY REVIEWS',
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: GoogleFonts.barlow(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          tabs: const [
            Tab(text: 'CLIENT FEEDBACK'),
            Tab(text: 'MY RATINGS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedReviewsTab(isDark),
          _buildWrittenReviewsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildReceivedReviewsTab(bool isDark) {
    final reviewsAsync = ref.watch(receivedReviewsProvider);

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      error: (err, _) => _buildErrorState(err.toString(), () => ref.read(receivedReviewsProvider.notifier).refresh()),
      data: (reviews) {
        if (reviews.isEmpty) {
          return _buildEmptyState('No client feedback found', isDark);
        }
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () => ref.read(receivedReviewsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReceivedReviewCard(review: review, isDark: isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildWrittenReviewsTab(bool isDark) {
    final reviewsAsync = ref.watch(writtenReviewsProvider);

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
      error: (err, _) => _buildErrorState(err.toString(), () => ref.read(writtenReviewsProvider.notifier).refresh()),
      data: (reviews) {
        if (reviews.isEmpty) {
          return _buildEmptyState('You have not rated any clients yet', isDark);
        }
        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () => ref.read(writtenReviewsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _WrittenReviewCard(review: review, isDark: isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load reviews',
              style: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 56,
            color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.barlow(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedReviewCard extends ConsumerStatefulWidget {
  final CustomerReviewModel review;
  final bool isDark;

  const _ReceivedReviewCard({required this.review, required this.isDark});

  @override
  ConsumerState<_ReceivedReviewCard> createState() => _ReceivedReviewCardState();
}

class _ReceivedReviewCardState extends ConsumerState<_ReceivedReviewCard> {
  final _replyController = TextEditingController();
  bool _isReplying = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final success = await ref
        .read(receivedReviewsProvider.notifier)
        .replyToReview(widget.review.id, text);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        setState(() {
          _isReplying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post reply. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(widget.review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: widget.review.customerPhoto != null && widget.review.customerPhoto!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.review.customerPhoto!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildFallbackAvatar(),
                      )
                    : _buildFallbackAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.review.customerName,
                      style: GoogleFonts.barlow(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.review.bookingServiceName} • $dateStr',
                      style: GoogleFonts.barlow(
                        fontSize: 11,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < widget.review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Comment
          Text(
            widget.review.comment,
            style: GoogleFonts.barlow(
              fontSize: 13.5,
              color: widget.isDark ? Colors.white : Colors.black87,
              height: 1.4,
            ),
          ),

          // Existing Reply or Reply Trigger
          if (widget.review.replyContent != null && widget.review.replyContent!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (widget.isDark ? Colors.white : Colors.black).withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, color: AppColors.orange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'YOUR REPLY',
                        style: GoogleFonts.barlow(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.review.replyContent!,
                    style: GoogleFonts.barlow(
                      fontSize: 12.5,
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            if (!_isReplying)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isReplying = true;
                    });
                  },
                  icon: const Icon(Icons.reply_rounded, size: 16, color: AppColors.orange),
                  label: Text(
                    'REPLY',
                    style: GoogleFonts.barlow(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: GoogleFonts.barlow(fontSize: 13, color: widget.isDark ? Colors.white : Colors.black87),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a public reply...',
                        hintStyle: GoogleFonts.barlow(fontSize: 13, color: AppColors.grey),
                        filled: true,
                        fillColor: widget.isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF2F2F7),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)),
                    )
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                      onPressed: _submitReply,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.error, size: 28),
                      onPressed: () {
                        setState(() {
                          _isReplying = false;
                        });
                      },
                    ),
                  ]
                ],
              ),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: widget.isDark ? const Color(0xFF333333) : Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        widget.review.customerName.isNotEmpty ? widget.review.customerName[0].toUpperCase() : 'C',
        style: GoogleFonts.barlow(
          fontWeight: FontWeight.bold,
          color: AppColors.orange,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _WrittenReviewCard extends StatelessWidget {
  final VendorReviewModel review;
  final bool isDark;

  const _WrittenReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: review.customerPhoto != null && review.customerPhoto!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: review.customerPhoto!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildFallbackAvatar(),
                      )
                    : _buildFallbackAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: GoogleFonts.barlow(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rated on $dateStr',
                      style: GoogleFonts.barlow(
                        fontSize: 11,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: GoogleFonts.barlow(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : 'C',
        style: GoogleFonts.barlow(
          fontWeight: FontWeight.bold,
          color: AppColors.orange,
          fontSize: 16,
        ),
      ),
    );
  }
}
