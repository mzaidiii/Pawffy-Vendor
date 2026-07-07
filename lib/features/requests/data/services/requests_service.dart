import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/storage/storage_service.dart';
import '../models/request_model.dart';

class RequestsService {
  final Dio _dio = DioClient.dio;

  Future<Options> get _authHeader async {
    final token = await StorageService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<RequestModel>> getRequests({required String status, String? search}) async {
    try {
      final options = await _authHeader;
      final response = await _dio.get(
        ApiConstants.requests,
        queryParameters: {
          'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        options: options,
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
        return list.map((json) => RequestModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load requests',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      final options = await _authHeader;
      final response = await _dio.post(
        ApiConstants.acceptRequest(requestId),
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to accept request',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      final options = await _authHeader;
      final response = await _dio.post(
        ApiConstants.rejectRequest(requestId),
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to reject request',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
