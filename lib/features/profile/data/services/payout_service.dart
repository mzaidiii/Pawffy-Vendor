import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/Storage/storage_service.dart';

class PayoutService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> checkPayoutStatus() async {
    try {
      final response = await _dio.get(
        ApiConstants.payoutsCheck,
        options: await _authHeader,
      );

      final dynamic body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body?['message'] ?? 'Failed to check payout status');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to connect to payouts backend',
      );
    }
  }

  Future<Map<String, dynamic>> startOnboarding() async {
    try {
      final response = await _dio.post(
        ApiConstants.payoutsOnboard,
        options: await _authHeader,
      );

      final dynamic body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body?['message'] ?? 'Failed to start onboarding');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to initiate onboarding link',
      );
    }
  }

  Future<Map<String, dynamic>> syncPayoutStatus() async {
    try {
      final response = await _dio.get(
        ApiConstants.payoutsStatus,
        options: await _authHeader,
      );

      final dynamic body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      throw Exception(body?['message'] ?? 'Failed to sync payout status');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to sync payouts status from Stripe',
      );
    }
  }
}
