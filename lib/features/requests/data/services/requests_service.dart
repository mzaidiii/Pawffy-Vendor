import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pawffy/core/networks/dio_client.dart';
import 'package:pawffy/core/networks/api_constants.dart';
import 'package:pawffy/core/Storage/storage_service.dart';
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

  Future<bool> startRequest(String requestId) async {
    try {
      final options = await _authHeader;
      final response = await _dio.post(
        ApiConstants.startRequest(requestId),
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to start request',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> updateRequestProgress(String requestId, Map<String, dynamic> progressData) async {
    try {
      final options = await _authHeader;
      final response = await _dio.patch(
        ApiConstants.updateRequestProgress(requestId),
        data: progressData,
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update request progress',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> uploadRequestMedia(String requestId, File file) async {
    try {
      final options = await _authHeader;
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      options.headers?['Content-Type'] = 'multipart/form-data';
      
      final response = await _dio.post(
        ApiConstants.uploadRequestMedia(requestId),
        data: formData,
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to upload media',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> updateRequestLocation(
    String requestId, {
    required double latitude,
    required double longitude,
    required String address,
    required String timestamp,
  }) async {
    try {
      final options = await _authHeader;
      final response = await _dio.post(
        ApiConstants.updateRequestLocation(requestId),
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'timestamp': timestamp,
        },
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update location',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> completeRequest(String requestId, FormData formData) async {
    try {
      final options = await _authHeader;
      options.headers?['Content-Type'] = 'multipart/form-data';
      
      final response = await _dio.post(
        ApiConstants.completeRequest(requestId),
        data: formData,
        options: options,
      );
      return response.data != null && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to complete request',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
