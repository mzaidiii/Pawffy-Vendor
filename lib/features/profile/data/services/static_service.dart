import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';

class StaticService {
  final Dio _dio = DioClient.dio;

  Future<String> getTerms() async {
    try {
      final response = await _dio.get(ApiConstants.terms);
      final body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        final data = body['data'];
        if (data is Map) {
          return data['content']?.toString() ?? '';
        }
        return data.toString();
      }
      throw Exception(body?['message'] ?? 'Failed to parse terms');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch terms from server',
      );
    }
  }

  Future<String> getPrivacy() async {
    try {
      final response = await _dio.get(ApiConstants.privacy);
      final body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        final data = body['data'];
        if (data is Map) {
          return data['content']?.toString() ?? '';
        }
        return data.toString();
      }
      throw Exception(body?['message'] ?? 'Failed to parse privacy');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch privacy from server',
      );
    }
  }
}
