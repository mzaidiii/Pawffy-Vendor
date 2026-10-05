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

  List<dynamic> _extractList(dynamic body) {
    if (body == null) return [];
    if (body is List) return body;
    if (body is Map) {
      if (body['data'] is List) return body['data'];
      if (body['reviews'] is List) return body['reviews'];
      if (body['customerReviews'] is List) return body['customerReviews'];
      if (body['data'] is Map) {
        final Map<String, dynamic> innerMap = Map<String, dynamic>.from(body['data']);
        if (innerMap['data'] is List) return innerMap['data'];
        if (innerMap['reviews'] is List) return innerMap['reviews'];
        if (innerMap['customerReviews'] is List) return innerMap['customerReviews'];
      }
    }
    return [];
  }

  Future<List<CustomerReviewModel>> getReceivedReviews() async {
    try {
      final response = await _dio.get(
        ApiConstants.vendorReviews,
        queryParameters: {'page': 1, 'limit': 50},
        options: await _authHeader,
      );

      final dynamic body = response.data;
      final List<dynamic> list = _extractList(body);
      return list.map((json) => CustomerReviewModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : 'Failed to load received reviews';
      throw Exception(msg);
    }
  }

  Future<bool> replyToReview(String reviewId, String replyContent) async {
    try {
      final response = await _dio.post(
        ApiConstants.replyToReview(reviewId),
        data: {'replyContent': replyContent},
        options: await _authHeader,
      );
      return response.data != null && (response.data['success'] == true || response.statusCode == 200);
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : 'Failed to submit review reply';
      throw Exception(msg);
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
      return response.data != null && (response.data['success'] == true || response.statusCode == 201 || response.statusCode == 200);
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : 'Failed to review customer';
      throw Exception(msg);
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
      final List<dynamic> list = _extractList(body);
      return list.map((json) => VendorReviewModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } on DioException catch (e) {
      final String msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : 'Failed to load written reviews';
      throw Exception(msg);
    }
  }
}
