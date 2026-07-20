import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/Storage/storage_service.dart';
import '../models/review_model.dart';

class ReviewsService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<CustomerReviewModel>> getReceivedReviews() async {
    try {
      final response = await _dio.get(
        ApiConstants.vendorReviews,
        queryParameters: {'page': 1, 'limit': 50},
        options: await _authHeader,
      );

      final dynamic body = response.data;
      if (body != null && body['success'] == true) {
        final List<dynamic> list = body['data'] ?? [];
        return list.map((json) => CustomerReviewModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load received reviews',
      );
    }
  }

  Future<bool> replyToReview(String reviewId, String replyContent) async {
    try {
      final response = await _dio.post(
        ApiConstants.replyToReview(reviewId),
        data: {'replyContent': replyContent},
        options: await _authHeader,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to submit review reply',
      );
    }
  }

  Future<bool> reviewCustomer({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.customerReviews,
        data: {
          'bookingId': bookingId,
          'rating': rating,
          'comment': comment,
        },
        options: await _authHeader,
      );
      return response.data != null && (response.data['success'] == true || response.statusCode == 201);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to review customer',
      );
    }
  }

  Future<List<VendorReviewModel>> getWrittenReviews() async {
    try {
      final response = await _dio.get(
        ApiConstants.customerReviews,
        queryParameters: {'page': 1, 'limit': 50},
        options: await _authHeader,
      );

      final dynamic body = response.data;
      if (body != null && body['success'] == true) {
        final dynamic dataField = body['data'];
        List<dynamic> list = [];
        if (dataField is List) {
          list = dataField;
        } else if (dataField is Map && dataField['data'] is List) {
          list = dataField['data'];
        }
        return list.map((json) => VendorReviewModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load written reviews',
      );
    }
  }
}
