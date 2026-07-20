import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/review_model.dart';
import '../data/services/reviews_service.dart';

final reviewsServiceProvider = Provider<ReviewsService>((ref) => ReviewsService());

final receivedReviewsProvider =
    AsyncNotifierProvider<ReceivedReviewsNotifier, List<CustomerReviewModel>>(
  ReceivedReviewsNotifier.new,
);

class ReceivedReviewsNotifier extends AsyncNotifier<List<CustomerReviewModel>> {
  late final ReviewsService _service;

  @override
  Future<List<CustomerReviewModel>> build() async {
    _service = ref.read(reviewsServiceProvider);
    return await _service.getReceivedReviews();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getReceivedReviews());
  }

  Future<bool> replyToReview(String reviewId, String replyContent) async {
    try {
      final success = await _service.replyToReview(reviewId, replyContent);
      if (success) {
        await refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final writtenReviewsProvider =
    AsyncNotifierProvider<WrittenReviewsNotifier, List<VendorReviewModel>>(
  WrittenReviewsNotifier.new,
);

class WrittenReviewsNotifier extends AsyncNotifier<List<VendorReviewModel>> {
  late final ReviewsService _service;

  @override
  Future<List<VendorReviewModel>> build() async {
    _service = ref.read(reviewsServiceProvider);
    return await _service.getWrittenReviews();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getWrittenReviews());
  }

  Future<bool> submitCustomerReview({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    try {
      final success = await _service.reviewCustomer(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      if (success) {
        await refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
